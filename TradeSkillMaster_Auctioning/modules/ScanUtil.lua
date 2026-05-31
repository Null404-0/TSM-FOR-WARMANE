-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

Scan.auctionData = {}
Scan.skipped = {}
-- 记录"已交付给 PostScan 的物品"，每次扫描清空。
-- 用来防止 SCAN_PAGE_UPDATE 跨页重复调用 ProcessScannedItem 让 Post:ProcessItem 反复入队，
-- 导致同一物品被排 N 次 normalPrice 的发布任务（一页一次）。
Scan.postProcessed = {}

-- 【优化配置】只扫描前N条拍卖即可判断压价
local EARLY_STOP_LIMIT = 5  -- 可调整为 2-10


local function dbg(fmt, ...)
	if not _G.TSM_AUCTION_DEBUG then return end
	local msg = (select("#", ...) > 0) and string.format(fmt, ...) or fmt
	DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[TSM-DBG/Auct]|r " .. tostring(msg))
end

-- 把物品交给 PostScan：每个 itemString 一次扫描里只交付一次。
-- finalPass=true 表示 SCAN_COMPLETE 的兜底交付，此时即便没有 buyout 数据也要交（让 PostScan
-- 走 postingNormal 路径上架"无对手"的物品）。其他时机要求至少看到过一条 buyout>0 的记录才交，
-- 避免 page 0 全是纯竞价时 PostScan 拿到 nil 最低价错按 normalPrice 上架。
-- 返回值：true 表示这次确实把物品交给了 PostScan（调用方据此决定要不要触发 UI 刷新）。
local function HandOffToPostScan(itemString, noUpdate, finalPass)
	if Scan.postProcessed[itemString] then return false end
	if not finalPass then
		local item = Scan.auctionData[itemString]
		if not item or not item.hasBuyoutRecord then return false end
	end
	Scan.postProcessed[itemString] = true
	TSM.Manage:ProcessScannedItem(itemString, noUpdate)
	return true
end

local function CallbackHandler(event, ...)
	dbg("CallbackHandler event=%s filtersLeft=%s", tostring(event), tostring(Scan.filterList and #Scan.filterList))
	if event == "QUERY_COMPLETE" then
		local filterList = ...
		local numItems = 0
		for _, v in ipairs(filterList) do
			numItems = numItems + #v.items
		end
		Scan.filterList = filterList
		Scan.numFilters = #filterList
		Scan:ScanNextFilter()
	elseif event == "QUERY_UPDATE" then
		local current, total, skipped = ...
		TSM.Manage:UpdateStatus("query", current, total)
		for _, itemString in ipairs(skipped) do
			-- 跳过的物品没有 auction 数据，按 SCAN_COMPLETE 兜底口径交付（finalPass=true）。
			HandOffToPostScan(itemString, nil, true)
			tinsert(Scan.skipped, itemString)
		end
	elseif event == "SCAN_PAGE_UPDATE" then
		-- 【核心优化1】每扫完一页立即处理，不等全部完成
		local page, totalPages, pageData = ...
		TSM.Manage:UpdateStatus("page", page, totalPages)

		local handedOff = false
		if pageData and Scan.filterList and Scan.filterList[1] then
			for _, itemString in ipairs(Scan.filterList[1].items) do
				if pageData[itemString] and not Scan.auctionData[itemString] then
					-- 新物品：立即处理和显示
					Scan:ProcessItem(itemString, pageData[itemString])
				elseif pageData[itemString] and Scan.auctionData[itemString] then
					-- 【优化2】已有数据的物品：检查是否已经收集够5条最低价
					local existingRecords = Scan.auctionData[itemString].records or {}
					if #existingRecords >= EARLY_STOP_LIMIT then
						-- 已经有足够数据，跳过继续扫描这个物品
						-- 不做任何处理，节省时间
					else
						-- 合并新数据（但仍然只保留前5条）
						Scan:MergeAuctionData(itemString, pageData[itemString])
					end
				end
				-- 交付要满足两条：之前没交过、且物品已经看到过 buyout>0 记录。
				-- 没看到 buyout 就不交，等后续页或 SCAN_COMPLETE 兜底，避免重复入队 + 按 normalPrice 错挂。
				-- 这里用 noUpdate=true 跳过每条之后的 UI 刷新，下面做一次合并的去抖刷新。
				if HandOffToPostScan(itemString, true) then
					handedOff = true
				end
			end
		end
		-- 本页若至少交付了一个物品，就触发一次去抖 UI 刷新，让日志框/拍卖框跟着滚动而不必手动点"显示日志"。
		-- 用 CreateTimeDelay 做 0.05s 去抖，相邻页事件不会叠出多次刷新。
		-- 走 TSM.Manage 转发：UpdateSTData 挂在 GUI 模块的 private 表上，TSM.GUI（公开模块）上没有这个方法。
		if handedOff then
			TSMAPI:CreateTimeDelay("aucScanPageSTRefresh", 0.05, function() TSM.Manage:RefreshSTData() end)
		end
	elseif event == "SCAN_INTERRUPTED" then
		TSM.Manage:ScanComplete(true)
	elseif event == "SCAN_TIMEOUT" then
		tremove(Scan.filterList, 1)
		Scan:ScanNextFilter()
	elseif event == "SCAN_COMPLETE" then
		local data = ...
		-- 【修复】确保 filter 里所有物品都会走一次 ProcessScannedItem，
		-- 否则：
		--   1) AH 上完全没人挂单的物品（例如 "智力的伟大" 当前无人挂）会被直接丢弃，
		--      永远走不到 Post:GetPostPrice 里的 postingNormal 分支，无法按 normalPrice 上架。
		--   2) 合并查询里的同名多 itemID 物品（例如 暗月卡片：伟大 力/敏/智 三个变体），
		--      只要某个变体当前无人挂，data 里就缺它，扫描结果随机丢失物品。
		for _, itemString in ipairs(Scan.filterList[1].items) do
			if not Scan.auctionData[itemString] and data[itemString] then
				Scan:ProcessItem(itemString, data[itemString])
			end
			-- finalPass=true：扫描已结束，对没有 buyout 的物品也按 normalPrice 交付。
			HandOffToPostScan(itemString, nil, true)
		end
		tremove(Scan.filterList, 1)
		Scan:ScanNextFilter()
	end
end

function Scan:StartItemScan(itemList)
	wipe(Scan.auctionData)
	wipe(Scan.skipped)
	wipe(Scan.postProcessed)
	TSMAPI:GenerateQueries(itemList, CallbackHandler)
	TSM.Manage:UpdateStatus("query", 0, -1)
end

function Scan:ScanNextFilter()
	dbg("ScanNextFilter: %d filters remaining", #Scan.filterList)
	if #Scan.filterList == 0 then
		TSM.Manage:UpdateStatus("scan", Scan.numFilters, Scan.numFilters)
		return TSM.Manage:ScanComplete()
	end
	TSM.Manage:UpdateStatus("scan", Scan.numFilters-#Scan.filterList, Scan.numFilters)
	local f = Scan.filterList[1]
	dbg("ScanNextFilter: starting filter name=%q items=%d", tostring(f and f.name), f and f.items and #f.items or 0)
	-- 【优化】启用快速扫描模式：只扫第一页
	TSMAPI.AuctionScan:RunQuery(Scan.filterList[1], CallbackHandler, true, nil, nil, true)
end

-- 用 GetItemBuyout()（buyout==0/nil 时返回 nil）+ math.huge 兜底，
-- 把"纯竞价"（buyout==0）的拍卖排到最后，而不是原始 a.buyout 把 0 当最低。
-- 否则像"附魔武器 - 狂暴"这种高价值物品满屏纯竞价时，trim 会保留 5 条 buyout==0
-- 的记录，GetLowestAuction 全部跳过 → 取不到最低价 → 永远走 postingNormal。
local function SortRecordsByBuyoutAsc(a, b)
	local aBuyout = a:GetItemBuyout() or math.huge
	local bBuyout = b:GetItemBuyout() or math.huge
	if aBuyout ~= bBuyout then
		return aBuyout < bBuyout
	end
	return (a:GetItemDisplayedBid() or math.huge) < (b:GetItemDisplayedBid() or math.huge)
end

-- 按价格升序排序，保留前 N 条最低价；额外保留所有玩家自己（含小号）的拍卖，
-- 否则 GetPlayerAuctionCount 会数不到高于 top N 的自有挂单，导致发布上限失效。
local function TrimRecordsKeepPlayer(records)
	if #records <= EARLY_STOP_LIMIT then return records end

	table.sort(records, SortRecordsByBuyoutAsc)

	local limitedRecords = {}
	for i = 1, EARLY_STOP_LIMIT do
		limitedRecords[i] = records[i]
	end
	for i = EARLY_STOP_LIMIT + 1, #records do
		if records[i]:IsPlayer() then
			tinsert(limitedRecords, records[i])
		end
	end
	return limitedRecords
end

-- 合并拍卖数据（保留前 N 条最低价 + 玩家自己的所有挂单）
function Scan:MergeAuctionData(itemString, newAuctionItem)
	if not Scan.auctionData[itemString] or not newAuctionItem then return end

	local existing = Scan.auctionData[itemString]
	-- 让新来的记录在 IsPlayer() 判定时能复用现有的 alts 表，
	-- 否则 record.parent (= newAuctionItem) 的 alts 为空，小号挂单会漏判。
	newAuctionItem:SetAlts(existing.alts)

	-- 在当前数据流里 pageData == private.data，所以 newAuctionItem 与 existing 是同一对象，
	-- existing.records == newAuctionItem.records 是同一张表。直接 ipairs 边遍历边 tinsert 会
	-- 让索引一直追到尾部 nil 不出现，陷入无限循环并最终触发 WoW 的脚本运行超限。
	-- AddAuctionRecord 已经把后续页的记录就地 append 到这张表里了，这里只需 re-trim + re-compact。
	if newAuctionItem ~= existing then
		local newRecords = newAuctionItem.records or {}
		for _, record in ipairs(newRecords) do
			tinsert(existing.records, record)
		end
	end

	existing.records = TrimRecordsKeepPlayer(existing.records)
	existing.shouldCompact = true
	existing:PopulateCompactRecords()
end

function Scan:ProcessItem(itemString, auctionItem)
	if not itemString or not auctionItem then return end

	-- SetAlts 必须在裁剪之前，否则 IsPlayer() 只能识别当前角色，小号挂单会被裁掉。
	auctionItem:SetAlts(TSM.db.factionrealm.player)

	if auctionItem.records then
		auctionItem.records = TrimRecordsKeepPlayer(auctionItem.records)
	end

	auctionItem:SetRecordParams({"GetItemBuyout", "GetItemDisplayedBid", "seller", "count"})
	auctionItem:PopulateCompactRecords()
	if #auctionItem.records > 0 then
		auctionItem:SetMarketValue(TSMAPI:GetItemValue(itemString, "DBMarket"))
		Scan.auctionData[itemString] = auctionItem
	end
end

function Scan:ShouldIgnoreAuction(record, operation)
	if type(operation) ~= "table" then return end
	if record.timeLeft <= operation.ignoreLowDuration then
		-- ignoring low duration
		return true
	elseif operation.matchStackSize and record.count ~= operation.stackSize then	
		-- matching stack size
		return true
	else
		local minPrice = TSM.Util:GetItemPrices(operation, record.parent:GetItemString()).minPrice
		if operation.priceReset == "ignore" and minPrice and record:GetItemBuyout() and record:GetItemBuyout() <= minPrice then	
			-- ignoring auctions below threshold
			return true
		end
	end
end

-- This gets how many auctions are posted specifically on this tier, it does not get how many of the items they up at this tier
-- but purely the number of auctions
function Scan:GetPlayerAuctionCount(itemString, findBuyout, findBid, findQuantity, operation)
	findBuyout = floor(findBuyout)
	findBid = floor(findBid)

	local quantity = 0
	for _, record in ipairs(Scan.auctionData[itemString].compactRecords) do
		if not Scan:ShouldIgnoreAuction(record, operation) and record:IsPlayer() then
			if record:GetItemBuyout() == findBuyout and record:GetItemDisplayedBid() == findBid and record.count == findQuantity then
				quantity = quantity + record.numAuctions
			end
		end
	end

	return quantity
end

-- gets the buyout / bid of the second lowest auction for this item
function Scan:GetSecondLowest(itemString, lowestBuyout, operation)
	local auctionItem = Scan.auctionData[itemString]
	if not auctionItem then return end
	
	local buyout, bid
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record, operation) then
			local recordBuyout = record:GetItemBuyout()
			if recordBuyout and (not buyout or recordBuyout < buyout) and recordBuyout > lowestBuyout then
				buyout, bid = recordBuyout, record:GetItemDisplayedBid()
			end
		end
	end
	
	return buyout, bid
end

-- Find out the lowest price for this item
function Scan:GetLowestAuction(auctionItem, operation)
	if type(auctionItem) == "string" or type(auctionItem) == "number" then -- it's an itemString
		auctionItem = Scan.auctionData[auctionItem]
	end
	if not auctionItem then return end
	
	-- Find lowest
	local buyout, bid, owner, invalidSellerEntry
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record, operation) then
			local recordBuyout = record:GetItemBuyout()
			if recordBuyout then
				local recordBid = record:GetItemDisplayedBid()
				if not buyout or recordBuyout < buyout or (recordBuyout == buyout and recordBid < bid) then
					buyout, bid, owner = recordBuyout, recordBid, record.seller
				end
			end
		end
	end
	-- 空白名玩家（owner == "?"）一律当成"非白名单的对手"，不再因为白名单未知就跳过该物品。
	-- Warmane 上滥用空白名的几乎都是压价机器人，应当按正常 undercut 流程压价发布。
	-- postCap 由 PostScan 的对手压价分支用 GetPlayerTotalAuctionCount 兜底，不会越限。

	-- Now that we know the lowest, find out if this price "level" is a friendly person
	-- the reason we do it like this, is so if Apple posts an item at 50g, Orange posts one at 50g
	-- but you only have Apple on your white list, it'll undercut it because Orange posted it as well
	local isWhitelist, isPlayer = true, true
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record, operation) then
			local recordBuyout = record:GetItemBuyout()
			if not record:IsPlayer() and recordBuyout and recordBuyout == buyout then
				isPlayer = nil
				if not TSM.db.factionrealm.whitelist[strlower(record.seller)] then
					isWhitelist = nil
				end

				-- If the lowest we found was from the player, but someone else is matching it (and they aren't on our white list)
				-- then we swap the owner to that person
				buyout, bid, owner = recordBuyout, record:GetItemDisplayedBid(), record.seller
			end
		end
	end

	return buyout, bid, owner, isWhitelist, isPlayer, invalidSellerEntry
end

function Scan:GetPlayerLowestBuyout(auctionItem, operation)
	if not auctionItem then return end
	
	-- Find lowest
	local buyout
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record, operation) then
			local recordBuyout = record:GetItemBuyout()
			if record:IsPlayer() and recordBuyout and (not buyout or recordBuyout < buyout) then
				buyout = recordBuyout
			end
		end
	end

	return buyout
end
