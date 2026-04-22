local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table

local private = {itemOperations={}}

function private.Create(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()

	local stContainer = CreateFrame("Frame", nil, frame)
	stContainer:SetPoint("TOPLEFT", 0, -35)
	stContainer:SetPoint("BOTTOMRIGHT", 0, 30)
	TSMAPI.Design:SetFrameColor(stContainer)
	frame.groupTree = TSMAPI:CreateGroupTree(stContainer, "Shopping", "Shopping_AH")
	private.groupTree = frame.groupTree
	
	local helpText = TSMAPI.GUI:CreateLabel(frame)
	helpText:SetPoint("TOPLEFT")
	helpText:SetPoint("TOPRIGHT")
	helpText:SetHeight(35)
	helpText:SetJustifyH("CENTER")
	helpText:SetJustifyV("CENTER")
	helpText:SetText(L["Select the groups which you would like to include in the search."])
	frame.helpText = helpText
	
	local startBtn = TSMAPI.GUI:CreateButton(frame, 16)
	startBtn:SetPoint("BOTTOMLEFT", 3, 3)
	startBtn:SetPoint("BOTTOMRIGHT", -3, 3)
	startBtn:SetHeight(20)
	startBtn:SetText(L["Start Search"])
	startBtn:SetScript("OnClick", private.StartScan)
	frame.startBtn = startBtn
	
	return frame
end

function private.ScanCallback(event, ...)
	if event == "filter" then
		local filter = ...
		local maxPrice
		for _, itemString in ipairs(filter.items) do
			local operation = private.itemOperations[itemString]
			local operationPrice = TSM:GetMaxPrice(operation.maxPrice, itemString)
			if not operationPrice then return end
			if operation.showAboveMaxPrice then
				maxPrice = nil
				break
			end
			maxPrice = maxPrice and max(maxPrice, operationPrice) or operationPrice
		end
		return maxPrice
	elseif event == "fastScan" then
		-- 反秒压 bot：本次 query 涉及的所有物品都设了"目标卖家"时，只扫第 1 页足矣
		-- （bot 的恶意低价必然是最低价，定在第 1 页）
		local filter = ...
		if not filter or not filter.items or #filter.items == 0 then return false end
		for _, itemString in ipairs(filter.items) do
			local op = private.itemOperations[itemString]
			if not (op and type(op.sniperSeller) == "string" and op.sniperSeller ~= "") then
				return false
			end
		end
		return true
	elseif event == "process" then
		local itemString, auctionItem = ...
		-- filter out auctions according to operation settings
		itemString = TSMAPI:GetBaseItemString(itemString, true)
		local operation = private.itemOperations[itemString]
		if not operation then return end
		local operationPrice = TSM:GetMaxPrice(operation.maxPrice, itemString)
		if not operationPrice then return end
		-- 反秒压 bot：如果填了"目标卖家"，只保留这些卖家的拍卖
		local sellerFilter
		do
			local raw = operation.sniperSeller
			if type(raw) == "string" and raw ~= "" then
				sellerFilter = {}
				for name in string.gmatch(raw, "[^,]+") do
					name = strlower(strtrim(name))
					if name ~= "" then
						sellerFilter[name] = true
					end
				end
				if not next(sellerFilter) then sellerFilter = nil end
			end
		end
		auctionItem:FilterRecords(function(record)
				if sellerFilter and not sellerFilter[strlower(record.seller or "")] then
					return true
				end
				if operation.evenStacks and record.count % 5 ~= 0 then
					return true
				end
				if not operation.showAboveMaxPrice then
					return (record:GetItemBuyout() or 0) > operationPrice
				end
			end)
		-- 过滤后若 records 全部被剔掉（例如设了"目标卖家"但本页没匹配），
		-- 不能把空壳继续塞回 private.auctions，否则 UpdateRT 里 sort 会炸（a[1] == nil）
		if #auctionItem.records == 0 then return end
		auctionItem:SetMarketValue(operationPrice)
		return auctionItem
	elseif event == "done" then
		TSM.Search:SetSearchBarDisabled(false)
		return
	end
end

function private.StartScan()
	TSMAPI:FireEvent("SHOPPING:GROUPS:STARTSCAN")
	wipe(private.itemOperations)
	for groupName, data in pairs(private.groupTree:GetSelectedGroupInfo()) do
		groupName = TSMAPI:FormatGroupPath(groupName, true)
		for _, opName in ipairs(data.operations) do
			TSMAPI:UpdateOperation("Shopping", opName)
			local opSettings = TSM.operations[opName]
			if not opSettings then
				-- operation doesn't exist anymore in Auctioning
				TSM:Printf(L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."], groupName, opName)
			else
				-- it's a valid operation
				for itemString in pairs(data.items) do
					local _, err = TSM:GetMaxPrice(opSettings.maxPrice, itemString)
					if err then
						TSM:Printf(L["Invalid custom price source for %s. %s"], TSMAPI:GetSafeItemInfo(itemString) or itemString, err)
					else
						private.itemOperations[itemString] = opSettings
					end
				end
			end
		end
	end
	
	local itemList = {}
	for itemString in pairs(private.itemOperations) do
		tinsert(itemList, itemString)
	end

	TSM.Search:SetSearchBarDisabled(true)
	TSM.Util:ShowSearchFrame(nil, L["% Max Price"])
	TSM.Util:StartItemScan(itemList, private.ScanCallback)
end

do
	TSM:AddSidebarFeature(L["TSM Groups"], private.Create)
end