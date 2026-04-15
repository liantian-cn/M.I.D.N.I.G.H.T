# Secret Values 高风险 API 清单

这份清单不是“完整 API 目录”, 而是给开发时快速避坑用的。

目标只有两个:

- 让你一眼看出哪些 API 最容易踩 `secret values`
- 告诉你遇到这些 API 时, 应该先查什么、优先怎么写

## 使用方法

看到下面这些 API, 不要直接开写。先做这 3 步:

1. 用 `wow-api-mcp` 查 API 签名和返回结构
2. 用 `C_Secrets` 相关函数或 `warcraft.wiki.gg` 判断 secret 风险
3. 决定这是“显示问题”还是“逻辑判断问题”

如果只是显示, 优先交给官方控件；如果要判断, 优先找非 secret 或 percent 路线。

## 红色: 最容易踩坑

### 1. 单位血量

常见 API:

- `UnitHealth`
- `UnitHealthMax`
- `UnitHealthPercent`

为什么高风险:

- 原始血量和最大血量很容易被你拿去做除法、阈值判断
- 旧写法里最常见的就是 `UnitHealth / UnitHealthMax`

推荐做法:

- 画血条: 优先用原生状态条
- 需要百分比: 优先查 `UnitHealthPercent`
- 需要判断是否受限: 查 `C_Secrets.ShouldUnitHealthMaxBeSecret`, 并结合 wiki 再确认

不要默认写:

```lua
if UnitHealth("target") / UnitHealthMax("target") < 0.3 then
end
```

### 2. 单位能量 / 资源

常见 API:

- `UnitPower`
- `UnitPowerMax`
- `UnitPowerPercent`

为什么高风险:

- 和血量一样, 很容易被直接拿去算百分比和阈值
- 不同能量类型还会让逻辑更复杂

推荐做法:

- 显示资源条: 优先原生控件
- 需要百分比: 优先 `UnitPowerPercent`
- 判断 secret 风险: 查 `C_Secrets.ShouldUnitPowerBeSecret`

### 3. 技能冷却

常见 API:

- `C_Spell.GetSpellCooldown`
- `C_SpellBook.GetSpellBookItemCooldown`

为什么高风险:

- 返回的通常不是一个简单秒数, 而是一整个结构
- 里面的 `startTime`、`duration`、`isEnabled`、`modRate` 都不能想当然当普通值

推荐做法:

- 纯显示: 优先官方冷却控件或 duration 相关路线
- 判断 secret 风险: 查 `C_Secrets.ShouldSpellCooldownBeSecret`
- 不要默认自己做剩余时间计算

### 4. 技能充能

常见 API:

- `C_Spell.GetSpellCharges`

为什么高风险:

- `currentCharges`、`maxCharges`、充能时间都很容易被直接比较
- 这类字段在旧思路里常被拿来决定“现在该不该按”

推荐做法:

- 如果只是画层数或冷却感, 优先显示思路
- 如果要做逻辑判断, 先去 wiki 确认字段行为, 再保守实现

### 5. Aura / Buff / Debuff

常见 API:

- `C_UnitAuras.GetAuraDataByIndex`
- `C_UnitAuras.GetAuraDataByAuraInstanceID`
- 以及 AuraData 结构里的各类字段

为什么高风险:

- 这是一整组复合数据, 不是单个值
- 名称、图标、层数、持续时间、施法者、布尔状态, 经常混着用
- 很多错误来自“把 AuraData 当普通表随便读、随便判断”

推荐做法:

- 先查 AuraData 的字段结构
- 判断 aura 是否可能受限: 查 `C_Secrets.ShouldUnitAuraIndexBeSecret`
- 先分清“显示字段”和“逻辑字段”

### 6. 施法 / 引导状态

常见 API:

- `UnitCastingInfo`
- `UnitChannelInfo`

为什么高风险:

- 里面同时有名称、贴图、开始时间、结束时间、可打断状态等字段
- 很容易被写成“只要不可打断就怎样”“只要剩余施法时间小于 X 就怎样”

推荐做法:

- 先查返回字段
- 判断风险: 查 `C_Secrets.ShouldUnitSpellCastingBeSecret`
- 施法条尽量用显示控件, 不要在 Lua 里做复杂时序判断

### 7. 威胁 / 仇恨

常见 API:

- `UnitThreatSituation`
- `UnitDetailedThreatSituation`

为什么高风险:

- 返回值天然就会被拿来做优先级与危险判断
- `status`、`scaledPercentage`、`rawThreat` 这些字段非常容易被直接比较

推荐做法:

- 判断风险: 查 `C_Secrets.ShouldUnitThreatValuesBeSecret`
- 尽量做展示, 不要在战斗中据此自动替玩家决策

## 黄色: 不是每次都炸, 但要警惕

### 8. 单位身份

常见 API:

- `UnitName`
- 其他和单位身份、目标身份、GUID 相关的接口

为什么要警惕:

- 你可能以为“名字只是字符串, 应该安全”, 但 12.x 里单位身份本身也可能受限制

推荐做法:

- 判断风险: 查 `C_Secrets.ShouldUnitIdentityBeSecret`
- 如果只是显示名字, 优先走显示链路
- 如果名字要参与匹配、过滤、优先级判断, 就必须先确认

### 9. 任何战斗相关布尔值

典型风险:

- `isEnabled`
- `notInterruptible`
- 各类 aura 布尔标记
- 各类“是否可用 / 是否满足条件”的状态

为什么要警惕:

- 很多人看到 boolean 就自然会写 `if flag then`
- 但 secret 环境下, 这反而可能是最先报错的地方

推荐做法:

- 不要因为它是布尔值就放松警惕
- 先确认它是不是来自高风险结构体或高风险 API

## 绿色: 更适合作为替代路线

这些不是说“永远安全”, 而是一般更适合当保守方案来优先考虑。

### 1. 百分比接口

例如:

- `UnitHealthPercent`
- `UnitPowerPercent`

适合:

- 你确实需要“比例”而不是原始数值
- 你希望少做 Lua 算术

### 2. `C_Secrets` 判断接口

高频有用的包括:

- `C_Secrets.HasSecretRestrictions`
- `C_Secrets.ShouldUnitHealthMaxBeSecret`
- `C_Secrets.ShouldUnitPowerBeSecret`
- `C_Secrets.ShouldSpellCooldownBeSecret`
- `C_Secrets.ShouldUnitAuraIndexBeSecret`
- `C_Secrets.ShouldUnitSpellCastingBeSecret`
- `C_Secrets.ShouldUnitThreatValuesBeSecret`
- `C_Secrets.ShouldUnitIdentityBeSecret`

适合:

- 写防御式代码
- 决定当前该走“显示路径”还是“降级路径”

### 3. Secret 诊断函数

常用:

- `issecretvalue`
- `canaccesssecrets`

适合:

- 调试
- 防御性保护
- 快速确认某个值是不是你想象中的普通值

不适合:

- 拿来设计一套“绕过 secret 限制”的逻辑

## 最常用的排查问句

每次看到高风险 API, 先问自己:

- 这个值我只是想显示, 还是要做判断？
- 我是不是正准备写 `<`、`>`、`==`、`+`、`/`？
- 我是不是正准备写 `if value then`？
- 我能不能改成官方原生控件直接显示？
- 我能不能改成 percent API？
- 我能不能先用 `C_Secrets` 判断一下？

## 给 DejaVu 的最实用结论

如果功能属于下面这些类型, 就默认它在红区:

- `DejaVu_Spell` 或其他直接显示模块里显示冷却、充能、施法状态
- `DejaVu_Matrix` 或单位输出模块里显示单位血量、资源、aura、威胁
- 专精目录里根据战斗态数据决定提示或排序

这几类代码, 先翻:

1. `00_secret_values.md`
2. 这份清单
3. `06_wow_api_query_playbook.md`

## 一句话总结

在 WoW 12.x 里, 真正危险的不是“你不知道有 secret values”, 而是: **你看到一个熟悉的 API, 就下意识按旧时代方式去比较、计算和分支。**
