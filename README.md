# TSM for Warmane

针对 Warmane 3.3.5 WLK 服务器适配的 TradeSkillMaster 整合版。
完整汉化（含繁中）。

当前版本：**v2.9.2**

## 更新日志

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

## 安装方法

1. 右上角点击绿色 **Code** 按钮 → **Download ZIP**
2. 解压后删除 `README.md`
3. 删除原先的 TSM 插件
4. 把新下载的插件文件剪切到魔兽插件目录（`Interface/AddOns/`）
5. 不建议直接覆盖

