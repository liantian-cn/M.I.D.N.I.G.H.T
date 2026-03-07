# Secret Values 速查

## 一句话理解

WoW 12.0 之后，很多和战斗、单位状态、目标信息有关的 API，不再简单地“返回普通数字或字符串”。它们可能返回 **secret values**：看起来像普通值，但插件 Lua 不能随便读、算、比、分支。

这才是 12.x 最大的兼容点。

## 最稳妥的工作流

1. 先用 `wow-api-mcp` 查 API 的名字、参数、返回结构。
2. 如果要判断“返回值或字段是不是秘密值”，继续查 `warcraft.wiki.gg` 对应 API 页，或 `Patch_12.0.0/API_changes`。
3. 只要没有把握，就当它是秘密值。
4. 如果只是展示，优先把它直接传给官方明确支持的控件接口。
5. 如果你想在 Lua 里做比较、运算、排序、拼接、表索引，先停下，确认这个值不是 secret。

## 高风险数据类型

下面这些内容要默认高警惕：

- 单位血量、最大血量、缺失血量
- 单位能量、最大能量、缺失能量
- 技能冷却、充能、持续时间
- Aura、Buff、Debuff、可驱散、层数、剩余时间
- 施法、引导、不可打断状态、施法目标
- 威胁、仇恨、目标身份、单位名字、单位类别
- 任何与战斗中自动判断有关的布尔值或数字

## 保守地认为“不能做”的事

对可能是 secret 的值，不要默认做这些事：

- `if value then`
- `if a < b then`
- `value + 1`、`value / total`
- `t[value] = true`
- `local n = #value`
- `value.field`、`value[1]`
- 拿它做排序、阈值判断、优先级判断

如果官方文档没有明确说“这个接口接受 secret values”，就不要赌。

## 能怎么安全用

### 1. 只是显示，不做逻辑判断

优先走“直接透传给官方控件”的路线。

常见思路：

- 血量/能量显示：优先让 `StatusBar` 一类控件直接吃值
- 冷却显示：优先用官方冷却控件或 duration 对象
- 文本显示：优先用官方明确支持的显示接口

重点不是“把值拆出来”，而是“让引擎自己画”。

### 2. 如果必须做计算，换非 secret 数据源

优先找这些替代路线：

- 百分比 API，例如 `UnitHealthPercent()`、`UnitPowerPercent()`
- `C_Secrets` 命名空间里的判断函数
- Curve / ColorCurve / Duration 这类让引擎代算的对象
- 更粗粒度的状态，而不是精确数字

### 3. 判断限制状态

可优先查看：

- `issecretvalue()`：判断某个值是不是 secret
- `canaccesssecrets()`：当前调用链是否能操作 secret
- `canaccesstable()`：某张表能不能安全索引
- `C_Secrets.HasSecretRestrictions()`：当前客户端是否启用 secret 限制

这些函数更适合“防出错”和诊断，不是拿来绕过限制的。

## 最常见的错误写法

### 冷却判断

错误思路：

```lua
local info = C_Spell.GetSpellCooldown(spellID)
if info.duration > 0 then
end
```

问题：`duration` 可能是 secret，比较时就炸。

更安全的思路：

- 如果只是显示冷却，直接交给冷却控件
- 如果只是判断“能不能按”，优先找明确不返回 secret 的状态接口

### 血量阈值判断

错误思路：

```lua
if UnitHealth("target") / UnitHealthMax("target") < 0.3 then
end
```

更安全的思路：

- 改用百分比 API
- 或直接驱动血条显示，不自己算

### Aura 逻辑

错误思路：

- 取 aura 剩余时间后自己算剩余秒数
- 根据布尔字段直接走 if 分支

更安全的思路：

- 先确认字段是否 secret
- 如果只是 UI，优先让官方 aura / timer / status 相关控件处理

## 推荐查询顺序

1. `wow-api-mcp` 查 API 形状
2. `warcraft.wiki.gg/wiki/API_xxx` 查字段说明
3. `warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes` 查是否有 secret 或限制说明
4. 还不确定，就按 secret 处理

## 从 EZAddonX2 提炼的显示经验

从 `EZAddonX2` 的做法看，最稳的路线是：

- 血量/能量优先 `UnitHealthPercent()`、`UnitPowerPercent()`，不要自己做除法
- 冷却、充能、施法、引导、Aura 时间优先用 duration 对象，不自己减时间
- 布尔状态优先转成亮灭、颜色、图标，不做综合评分
- Aura 用实例 ID 管理槽位，结构变化和进度变化分开刷新

这些都更符合 DejaVu 的定位：展示信息，不计算战斗属性，不替玩家决策。

## 给本项目的落地建议

- 任何 cell / slot / panel 代码，只要读取战斗态数据，都先假设有 secret 风险
- 不要在 Lua 里做“自动决策式”的战斗逻辑
- 优先做显示、状态同步、用户配置，不做替玩家判断


