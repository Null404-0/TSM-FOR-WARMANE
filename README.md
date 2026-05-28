<<<<<<< claude/sharp-gauss-1868p
# TSM for Warmane

针对 Warmane 3.3.5 WLK 服务器适配的 TradeSkillMaster 整合版。
完整汉化（含繁中），并修复了原版在国服 / Warmane 环境下日常使用中遇到的多个痛点。

当前版本：**v2.9.2**

---

## 痛点修复一览

按模块整理。每条都是真实遇到 → 已修复的问题。

### 国际化 & 字体
- **完整汉化所有 TSM 模块**：核心、Accounting、Auctioning、AuctionDB、Crafting、Destroying、ItemTracker、Shopping、Warehousing 全部覆盖
- **zhTW 繁中本地化补全**：补齐缺失翻译，按台湾用语调整词条
- **内置 WQY Zen Hei CJK 字体**：解决繁中 / 部分客户端字体缺失导致的乱码 / 方块

### Shopping & Sniper（狙击）
- **新增按卖家筛选 (Anti-Undercut-Bot)**：Sniper 可指定 / 排除目标卖家，针对自动压价机器人
- **卖家筛选按操作配置**：从全局开关改成 per-operation 设置，更灵活
- **同组卖家过滤走 fastScan**：组里所有物品都有卖家过滤时合并加速扫描
- **空 auctionItem 不再触发排序崩溃**：丢弃空壳条目，避免 sort nil-index

### Auctioning（上架）
- **无人挂单的物品照常上架**：不再被静默丢弃
- **post-cap（挂单上限）严格生效**：top-N 截断时保留玩家自己的挂单，cap 数正确
- **空卖家名条目也参与比价 / 改价**：处理 Warmane 偶发空 owner 字段
- **撤回了 postCap 跨等级合并判断**：避免误改价

### AuctionScanning（拍卖扫描）
- **修复扫描卡死**：AH 服务端漏发 `AUCTION_ITEM_LIST_UPDATE` 时 watchdog 兜底
- **空卖家名不再整页重扫**：服务端临时返回空 owner 时只对该条目做有界软重试，整页扫描不会被反复重置
- **fastScan 完整性保证**：所有 query.item 都进数据后才停止，不再漏数据

### Crafting（制造）
- **材料列表 Need / Total 列加宽**：支持 5 位数显示，不再被截断
- **附魔卷轴按 itemID 定位**：解决国服中文重名物品识别错乱
- **补货材料按"商店类别 + 墨水顺序"排序**：分大类（墨水 / 羊皮纸 / …），墨水按等级排，未列入的材料归末尾，方便按商店动线采购

### GUI / 窗口层级
- **多窗口同时打开 z-order 错乱修复**：AH 与附魔（或其它 TSM 可移动窗口）同时打开时不再相互穿插，无需拖动即可正常显示

---

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
=======
2026.05.28更新日志
修复了多个TSM窗口同时打开叠加时的显示错误问题


安装方法
右上角点击绿色【code】 然后Download ZIP
解压后删除readme.md
删除原先的插件 
剪切新下载的插件文件到魔兽插件目录即可 不建议直接覆盖
>>>>>>> main
