# TSM for Warmane

针对 Warmane 3.3.5 WLK 服务器适配的 TradeSkillMaster 整合版。
完整汉化（含繁中）。

当前版本：**v2.9.3**

---

## 安装方法

1. 右上角点击绿色 **Code** 按钮 → **Download ZIP**
2. 解压后删除 `README.md`
3. 删除原先的 TSM 插件
4. 把新下载的插件文件剪切到魔兽插件目录（`Interface/AddOns/`）
5. 不建议直接覆盖

---

## 更新日志

**2026.05.31** — v2.9.3
- Auctioning：纯竞价单（无一口价）不再被 trim 误当成"最低价"保留，高价值物品（如 `附魔武器 - 狂暴`）不再被按 `normalPrice` 上架
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



