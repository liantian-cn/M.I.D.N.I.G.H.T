# Terminal 解码契约

这份文档记录 Terminal 当前读取共享矩阵后的解码事实。共享显示协议本身见 `.context/Common/01_shared_protocol.md`，颜色归属见 `.context/Common/03_color_conventions.md`。

## 基本单位

- `Cell`: 4x4 像素块，Terminal 取中间 2x2 作为有效区域。
- `MegaCell`: 8x8 像素块，Terminal 取中间 6x6 作为有效区域，并用该区域 hash 查标题。
- `BadgeCell`: 8x8 像素块，Terminal 取中间 6x6 作为图标主体，右下角 2x2 作为脚标，中心 2x2 用来判断黑块。
- `CharCell`: 8x8 像素块，通过白点数量解出 0 到 10 的简单数值。
- `BarCell`: 代码里不是独立类，由 `MatrixDecoder.readBarValue()` 读取一段 4 像素高区域的中间 2 行白点占比。

坐标单位统一按 `Cell` 计算，不按像素计算。当前运行契约仍是 `84 x 28` 个 `Cell`。

## 帧有效性校验

`FrameDecodeWorker.submit_frame()` 在提取数据前要求一帧同时满足：

- `getCell(54, 9)` 必须是纯黑或纯白。
- `getCell(0, 0)` 必须是纯色。
- `getCell(82, 2)` 必须是纯白。
- `readCharCell(0, 2)` 不能为 `0`。

校验失败时 emit `frame_invalid`，这一帧不会进入 `extract_all_data()`。提取异常时 emit `frame_failed`，不终止后续帧。

## 顶层输出

`pixelcalc.extractor.extract_all_data()` 当前输出这些顶层键：

- `timestamp`
- `spell`
- `player`
- `target`
- `focus`
- `mouseover`
- `misc`
- `spec`
- `setting`
- `party`
- `assisted_combat`
- `flash`
- `delay`
- `testCell`
- `enable`
- `dispel_blacklist`
- `interrupt_blacklist`
- `spell_stop_list`
- `spell_queue_window`
- `burst_time`
- `latest_succeeded_cast`
- `UTF_hash`
- `UTF_string`

内部临时键 `_pending_utf_title_record` 只用于主线程把 UTF 标题记录写入 `TitleManager`，`MainWindow` 会在保存 `decoded_data` 前把它 `pop()` 掉，rotation 不应依赖它。

## `spell`

`spell` 是 cooldown spell 和 charge spell 的合并列表。每项字段：

- `is_charge`
- `charges`
- `title`
- `cooldown`
- `highlight`
- `is_usable`
- `is_known`

`Context.spell()`、`spell_cooldown_ready()` 和 `spell_charges_ready()` 都消费这组结构。

## `aura`

玩家、队友、目标、焦点和鼠标悬停单位的 aura 列表项字段：

- `title`
- `remain`
- `color_string`
- `type`
- `count`

`type` 来自 `COLOR_MAP["SPELL_TYPE"]`。未知脚标颜色会得到 `UNKNOWN`，不要在 rotation 中硬猜未知颜色的业务意义。

## `unit`

`player` 当前包含：

- `unitToken`
- `exists`
- `buff`
- `debuff`
- `status`

`party.party1` 到 `party.party4` 也是这个形状，但不存在时 `buff`、`debuff` 为空，`status` 为空。

`target` / `focus` / `mouseover` 当前包含：

- `unitToken`
- `exists`
- `debuff`
- `status`

敌方单位没有 `buff` 字段；`context.Unit.buff` 对 enemy 会抛 `ContextError`。不同单位类型的 `status` 字段不完全相同，应通过 `Context` / `Unit` 的属性访问，而不是在 rotation 中假设所有 unit 字段一致。

## `spec` 和 `setting`

- `spec`: `readCellList(55, 13, 14)`。
- `setting`: `readCellList(55, 12, 14)`。
- 每个索引是 `0` 到 `13` 的字符串键；纯色 Cell 返回 `pure`、`mean`、`percent`、`decimal`、`is_black`、`is_white`、`color_string`，非纯色返回 `None`。
- `context.CellDict.cell(index)` 只是轻量读取接口，不替业务定义索引含义。

如果要正式约定某个 `spec` / `setting` 索引，先补协议或项目文档，再改两端实现。

## 全局字段

- `misc.combat_time`: `getCell(56, 9).mean`。
- `misc.use_mouse`: `getCell(58, 9).is_not_black`。
- `assisted_combat`: `getBadgeCell(43, 14).title`。
- `flash`: `getCell(54, 9)` 返回的 `Cell` 对象，用于帧闪烁校验和调试展示。
- `delay`: `getCell(55, 9).is_not_black`。
- `testCell`: `readCharCell(0, 2)`。
- `enable`: `getCell(83, 0).is_not_black`。
- `dispel_blacklist`: `readBadgeCellList(64, 15, 10)`。
- `interrupt_blacklist`: `readBadgeCellList(43, 17, 19)`。
- `spell_stop_list`: `readBadgeCellList(43, 26, 10)`。
- `spell_queue_window`: `getCell(57, 9).mean / 100`。
- `burst_time`: `getCell(82, 0).decimal * 60`。
- `latest_succeeded_cast`: `getBadgeCell(82, 17).title`。
- `UTF_hash` / `UTF_string`: 测试和标题回填辅助数据。

## 边界约束

- `pixelcalc` 只负责从像素还原协议，不负责 rotation 决策。
- `context` 可以包装 `decoded_data`，但不能偷改协议本义。
- `rotation` 可以消费 `Context` 或原始 `decoded_data`，但不反向定义协议。
- 改 `extract_all_data()` 顶层键、unit 结构或 `spec` / `setting` 形状时，必须同步更新这份文档。
