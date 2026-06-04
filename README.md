# TSM for Warmane

针对 Warmane 3.3.5 WLK 服务器适配的 TradeSkillMaster 整合版。
完整汉化（含繁中）。

当前版本：**v2.9.4**

---

## 安装方法

1. 右上角点击绿色 **Code** 按钮 → **Download ZIP**
2. 解压后删除 `README.md`
3. 删除原先的 TSM 插件
4. 把新下载的插件文件剪切到魔兽插件目录（`Interface/AddOns/`）
5. 不建议直接覆盖

---

## 更新日志

**2026.06.04** — v2.9.4
- AuctionScanning：修复拍卖扫描偶发以**降序**发出查询，导致 fastScan 只读到前几页最贵的几条、漏掉真正最低价的问题。表现为 附魔武器-狂暴 / 雕文等明明 AH 上有 677g 的低价单，插件却抓到 888g+ 当"最低价"，于是走「高于最高价，以普通价发布」或「以正常价格发布」，按普通价直接挂、也读不到自己已挂的单。根因是 `/gNN` 反向扫描上线后排序方向改成依赖 `IsAuctionSortReversed()` 判断要不要再翻一次，而 Warmane 3.3.5a 上这个查询常返回"翻转前"的旧值，把升序又翻回降序（是否触发取决于上一次扫描遗留的排序状态，所以偶发）。现改为 `SortAuctionClearSort` + 确定性升序，全程不再读 `IsAuctionSortReversed`，只有 `/gNN` 最小堆叠模式才切降序。

**2026.06.03**
- Shopping：新增最小堆叠过滤 `/gNN`（例：`无限之尘/exact/g20` 只显示 ≥20 的堆叠）。带该过滤时扫描改为按总价**降序**，大堆叠落到最前几页，几秒内就在增量结果里出现，无需等整轮扫描结束；结果表仍按单价排序，最便宜的合格堆叠在最上面。
- AuctionControl：一口价失败（索引过期 / 弹"未找到指定物品"）时**自动重新查询并把确认框恢复成"可购买"**（最多 3 次后才放弃），复刻手动"再搜一次就能买"的恢复动作 —— 不再卡在"寻找物品…"、也不用关掉重搜整张 AH，再点一下即可买到（出价本身仍需点击，是 3.3.5a 的限制）。
- Auctioning：取消扫描时，若拍卖行查询少返回一页导致某个挂单完全没扫到数据，会自动补扫这些目标（最多 2 次），不再静默跳过被压价的附魔/雕文——以前得反复手动「重新开始」碰运气才能读到。补扫后仍读不到的物品会记入日志提示重试，而不是从取消列表里凭空消失。

**2026.05.31** — v2.9.3
- Auctioning：纯竞价单（无一口价）不再被 trim 误当成"最低价"保留。
- AuctionScanning：fastScan 早停判定要求每个目标至少有一条有效一口价记录，避免 WoW 把 `buyout==0` 排在最前导致只扫到纯竞价就停
- Auctioning：SCAN_PAGE_UPDATE 跨页去重 + 延迟交付：每个物品一次扫描只交给 PostScan 一次，且要等看到 buyout 才交，避免雕文这种多页合并查询重复入队同一物品（同一物品在日志里出现 4-5 次 normalPrice 发布）
- Auctioning：MergeAuctionData 修同对象自插入死循环，避免触发 WoW 脚本运行时限

**2026.05.28**
- 修复多个 TSM 窗口同时打开时叠加显示错乱（AH + 附魔 z-order 穿插）

**2026.05.24**
- AuctionScanning：异步卖家名做有界软重试

**2026.05.21**
- 繁中本地化补全 + 台湾用语适配
- 内置 WQY Zen Hei CJK 字体
- AuctionScanning：空卖家名不再整页重扫
- Auctioning：cap-respecting undercut，空 owner 物品也上架
- 回滚 postCap 跨等级合并判断

**2026.05.20**
- Crafting：补货材料按商店类别 + 墨水顺序排序
- 版本号 → v2.9.0

**2026.05.02**
- AuctionScanning：AUCTION_ITEM_LIST_UPDATE 漏发 watchdog 兜底

**2026.04.29**
- Crafting：附魔卷轴按 itemID 定位，规避中文重名
- Crafting：Need / Total 列加宽支持 5 位数

**2026.04.22**
- AuctionScan：fastScan 必须等所有 query.item 进数据
- Shopping：丢弃空 auctionItem 防止排序 nil-index

**2026.04.21**
- Shopping：同组卖家过滤走 fastScan
- Shopping：卖家过滤设置补本地化

**2026.04.19**
- Shopping：卖家过滤改 per-operation 设置

**2026.04.18**
- Shopping：Sniper 新增按卖家过滤（反压价机器人）
- Auctioning：top-N 截断保留玩家自己的挂单，post cap 正确

**2026.04.17**
- Auctioning：无人挂单的物品照常上架
- 完整汉化全部 TSM 模块

---



