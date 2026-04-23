# Terminal 解码契约

这份文档定义 Terminal 读取到共享矩阵之后，当前解码层实际依赖的契约。

共享显示协议本身见 `.context/Common/01_shared_protocol.md`；这里重点补充 Terminal 独有的帧校验、输出结构和消费边界。

## 基本单位

- `Cell`: 4x4 像素块，实际取中间 2x2 作为有效区域。
- `MegaCell`: 8x8 像素块，实际取中间 6x6 作为有效区域。
- `BadgeCell`: 8x8 像素块，实际取中间 6x6 作为图标主体；右下角 2x2 是脚标；中心 2x2 用来判断是否黑块。
- `CharCell`: 8x8 像素块，通过白点数量解出简单字符数值。

坐标单位统一按 `Cell` 计算，不按像素计算。

## 当前矩阵尺寸

- 当前实现按 `84 x 28` 个 `Cell` 解码。
- 这不是抽象理论，而是当前仓库代码依赖的运行契约。
- 如果矩阵尺寸将来变化，至少要同步修改共享协议、代码和这里。

## 帧有效性校验

当前 `FrameDecodeWorker` 在真正提取数据前，要求一帧同时满足：

- `getCell(54, 9)` 必须是纯黑或纯白
- `getCell(0, 0)` 必须是纯色
- `getCell(82, 2)` 必须是纯白
- `readCharCell(0, 2)` 不能为 `0`

这些检查失败时，这一帧会被当成无效帧，不进入 `extract_all_data()`。

## 解码输出结构

`pixelcalc.extractor.extract_all_data()` 当前输出的顶层键：

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
- `spell_queue_window`

### `spell`

列表项结构：

- `is_charge`
- `charges`
- `title`
- `cooldown`
- `highlight`
- `is_usable`
- `is_known`

### `aura`

列表项结构：

- `title`
- `remain`
- `color_string`
- `type`
- `count`

### `unit`

`player` / `target` / `focus` / `mouseover` / `party[n]` 统一按这种大结构组织：

- `unitToken`
- `exists`
- `buff`
- `debuff`
- `status`

但并不是所有 `unit` 都有完全相同的 `status` 字段。`context/Unit` 正是用来把这些差异包装成更好用的 API。

### `spec` 和 `setting`

- 这两块目前故意保持为"原始 Cell 字典"，不直接在 `pixelcalc` 层做业务语义命名。
- `context/CellDict` 只是提供轻量读取接口，没有替你定义业务含义。
- 如果要正式约定某个索引的意义，先补共享协议或这里，再决定要不要改 `context/`。

### `setting` 索引与坐标对应表

`ctx.setting.cell(index)` 的 index 是配置在 WoW 插件端 `ConfigRows` 中的顺序（从 0 开始），实际坐标定义在各个专精的 `Config.lua` 的 `Cell:New(x, y)` 调用中。

#### DeathKnightBlood

| index | 坐标 | 配置项 | 说明 |
|-------|------|--------|------|
| 0 | x:55, y:12 | runic_power_max | 最大符文能量 |
| 1 | x:56, y:12 | dk_interrupt_mode | 打断模式 |
| 2 | x:57, y:12 | blood_death_strike_health_threshold | 死亡打击生命值阈值 |
| 3 | x:58, y:12 | blood_death_strike_runic_power_overflow_threshold | 死亡打击泄能阈值 |
| 4 | x:59, y:12 | reaper_mark_health_threshold | 死神印记血量阈值 |
| 5 | x:60, y:12 | dancing_rune_mode | 符文刃舞模式 |

#### DemonHunterDevourer

| index | 坐标 | 配置项 | 说明 |
|-------|------|--------|------|
| 0 | x:55, y:12 | fury_max | 最大恶魔之怒 |
| 1 | x:56, y:12 | dh_interrupt_mode | 打断模式 |
| 2 | x:57, y:12 | phase_shift_threshold | 疾影血量阈值 |
| 3 | x:58, y:12 | void_Ray_fury_overflow_threshold | 虚空射线泄能阈值 |
| 4 | x:59, y:12 | slider_enemy_health_threshold | 收割血量阈值 |
| 5 | x:60, y:12 | aoe_enemy_count | AOE敌人数量 |

#### DruidGuardian

| index | 坐标 | 配置项 | 说明 |
|-------|------|--------|------|
| 0 | - | guardian_aoe_enemy_count | AOE敌人数量 |
| 1 | - | guardian_opener_time | 开怪时间 |
| 2 | - | guardian_frenzied_regeneration_threshold | 狂暴回复阈值 |
| 3 | - | guardian_barkskin_threshold | 树皮术阈值 |
| 4 | - | guardian_survival_instincts_threshold | 生存本能阈值 |
| 5 | - | guardian_rage_overflow_threshold | 怒气溢出阈值 |
| 6 | - | guardian_rage_threshold | 怒气阈值 |
| 7 | - | guardian_interrupt_logic | 打断逻辑 |
| 8 | - | guardian_incarnation_logic | 化身逻辑 |
| 9 | - | guardian_ironfur_logic | 铁皮逻辑 |
| 10 | - | guardian_rage_limit | 怒气上限 |

#### DruidRestoration

| index | 配置项 | 说明 |
|-------|--------|------|
| 0 | restoration_ironbark_hp_threshold | 铁木树皮阈值 |
| 1 | restoration_barkskin_hp_threshold | 树皮术阈值 |
| 2 | restoration_convoke_party_hp_threshold | 熊群触发群体阈值 |
| 3 | restoration_convoke_single_hp_threshold | 熊群触发单体阈值 |
| 4 | restoration_wild_growth_hp_threshold | 野性成长阈值 |
| 5 | restoration_tranquility_party_hp_threshold | 宁静群体阈值 |
| 6 | restoration_nature_swiftness_hp_threshold | 自然迅捷阈值 |
| 7 | restoration_swiftmend_hp_threshold | 迅捷治愈阈值 |
| 8 | restoration_swiftmend_count_threshold | 迅捷治愈计数阈值 |
| 9 | restoration_regrowth_hp_threshold | 愈合阈值 |
| 10 | restoration_rejuvenation_hp_threshold | 回春术阈值 |
| 11 | restoration_abundance_stack_threshold | 丰盛堆叠阈值 |
| 13 | restoration_hot_hp_threshold | HOT血量阈值 |

#### spec 索引说明

`ctx.spec.cell(index)` 同样按专精 Spec.lua 中 Cell 创建顺序索引：

| index | DeathKnightBlood | DemonHunterDevourer |
|-------|------------------|---------------------|
| 0 | - | soul_fragments (x:55, y:13) |

## 边界约束

- 颜色语义要结合 `.context/Common/03_color_conventions.md` 一起看。
- `context/` 可以包装 `decoded_data`，但不能偷改协议本义。
- `rotation/` 只能消费 `Context` 或 `decoded_data`，不应该反向定义协议。
- 如果改了 `extract_all_data()` 的字段结构，这份文档必须跟着改。
