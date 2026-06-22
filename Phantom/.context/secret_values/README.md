# Secret Values 与 12.1 Aura 风险

12.1.0 仍是 PTR / beta；依赖 Aura、Forbidden Aspects、Duration、FrameXML 细节前，先刷新 `.context/api-changes/`。

## 基本规则

- 只要值来自战斗、单位、Aura、施法、冷却、威胁、目标或 nameplate，先假设可能是 secret。
- 不确认安全前，不做比较、算术、索引、计数、排序、拼接、格式化截断或布尔分支。
- 只是显示时，优先交给官方支持的显示对象、曲线、formatter、duration object 或 12.1 Aura 显示系统。
- `issecretvalue`、`hasanysecretvalues`、`HasSecretValues` 只能帮助诊断，不是解密手段。

## 12.1 Aura 重点

- `UnitAura` / `C_UnitAuras` 在 combat、encounter、M+、PvP 等关键场景可能返回 full secret 或 nil。
- `C_UnitAuras.GetUnitAuras`、`GetUnitAuraInstanceIDs` 可能返回 secret vector；不能默认 `#value`，不能默认 `for` 遍历。
- AuraContainer / AuraButton 的目标是显示过滤后的 aura，不暴露底层 aura 数据给插件逻辑。
- AuraButton 被加入 AuraContainer 后会进入 Forbidden Partition；插件不能依赖 OnShow、IsShown、HookScript、事件注册等方式反推 aura 状态。

## 推荐方向

- 显示颜色：用 `C_CurveUtil.CreateColorCurve`、`EvaluateColorFromBoolean`、直接支持 curve 的单位 API。
- 显示时间：保留 `DurationObject`，用 `Evaluate*`、`Format*`、`Cooldown:SetCooldownFromDurationObject`、`DurationTextBinding`。
- 显示数量：优先官方 display count / formatter，而不是自己把 secret number 转字符串。
- 显示 Aura：12.1 起优先 AuraContainer / AuraButton；旧的 aura 列表读取只能作为反例或非 secret 场景的临时参考。
- 显示单个数字：可以用自定义字体和 FontString，但不要把显示文本反向当成逻辑输入。

## 禁止默认使用的旧思路

```lua
local auras = C_UnitAuras.GetUnitAuras(unit, filter)
for i = 1, #auras do
end
```

```lua
local ids = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter)
if ids and #ids > 0 then
end
```

```lua
local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
if aura and aura.expirationTime > GetTime() then
end
```

```lua
if auraButton:IsShown() then
end
```

这些写法都可能在 12.1 secret / forbidden 规则下失效。

## 查询顺序

1. 查 `.context/api-changes/`，新版本优先；12.1.0 仍是 PTR / beta 时先考虑刷新。
2. 用 `wow-api-mcp` 查 API 签名和废弃状态。
3. 查 `warcraft.wiki.gg` 的具体 API 页。
4. 必要时才查 `wow-ui-source-12.1.0/`。

## 更多例子

见 [`examples.md`](examples.md)。
