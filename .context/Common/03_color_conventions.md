# MIDNIGHT 颜色约定

颜色是共享协议的一部分，不是“看起来差不多就行”的视觉效果。

当前代码里的两个现实来源是：

- `DejaVu/DejaVu_Core/Color.lua`
- `Terminal/terminal/pixelcalc/color_map.py`

这两份定义不是完全相同，因此这里按“并集 + 标归属”整理。

## 共享基础色

- `BLACK`: 空白、关闭、未激活。
- `WHITE`: 开启、可见、显著布尔状态。
- `TRANSPARENT`: 无内容。
- `RED` / `GREEN` / `BLUE`: 基础调试或通用纯色。
- `C0` / `C100` / `C150` / `C200` / `C250` / `C255`: 灰阶常量。

## 两端共享的颜色组

### `SPELL_TYPE`

- 区分魔法、诅咒、疾病、中毒、激怒、流血。
- 区分友方 Buff、友方 Debuff、敌方 Debuff、玩家技能、可打断和不可打断施法。

### `MARK_POINT`

- 当前共享的两个近黑色定位色是 `15,25,20` 和 `25,15,20`。
- 它们属于矩阵定位锚点，不是普通视觉装饰色。

### `ROLE`

- `TANK`
- `HEALER`
- `DAMAGER`
- `NONE`

### `CLASS`

- 各职业固定色，供两端按协议识别。

### `STATUS_BOOLEAN`

- 共享语义只有一条：黑色代表 `false`，非黑色代表 `true`。
- 不要把这组颜色的具体 RGB 再解释成更细的通用业务分类。

## 只在 DejaVu 侧存在的颜色定义

### `SPELL_BOOLEAN`

- `IS_USABLE`
- `IS_KNOWN`
- `IS_HIGH_LIGHTED`

这组颜色当前定义在 `DejaVu/DejaVu_Core/Color.lua`，用于 Lua 侧技能显示布尔值。

### `STATUS_BOOLEAN.USE_MOUSE`

- `USE_MOUSE` 目前只在 Lua 侧出现。
- Python 端当前没有对应镜像键名，文档里保留这个差异，不把它误写成共享字段。

## 只在 Terminal 侧存在的颜色定义

### `MARK_FRAME`

- 这组颜色当前只出现在 `Terminal/terminal/pixelcalc/color_map.py`。
- 它是 Python 侧用于分区或解码辅助的派生颜色组，不是 `DejaVu/DejaVu_Core/Color.lua` 里当前存在的常量组。
- `MARK_FRAME` 不参与锚定，不参与定位，也不应被写成共享稳定锚点。

## 使用原则

- 先认颜色组，再认业务意义，不要把未知颜色硬猜成已知类别。
- 修改共享颜色语义前，先改这份文档，再改代码和项目专属文档。
- 看到 `MARK_POINT` 要想到定位阶段。
- 看到 `MARK_FRAME` 要想到 Terminal 侧分区辅助，而不是共享锚点规则。
