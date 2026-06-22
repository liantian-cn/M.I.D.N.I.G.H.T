# Secret Values 与 12.1 Aura 风险

## 基本规则

- 只要值来自战斗、单位、Aura、施法、冷却、威胁或目标信息，先假设可能是 secret。
- 不确认安全前，不做比较、算术、索引、计数、排序或布尔分支。
- 只是显示时，优先交给官方支持的显示对象或新 12.1 Aura 显示系统。

## 12.1 Aura 重点

- `UnitAura` 系列在关键场景可能返回 secret 或 nil。
- secret vector 不能默认 `#value`，不能默认 `for` 遍历。
- AuraContainer / AuraButton 的目标是显示过滤后的 aura，不暴露底层数据给插件逻辑。
- AuraButton 被加入 AuraContainer 后会进入 Forbidden Partition；插件不能依赖 OnShow、IsShown、HookScript 等方式反推 aura 状态。

## 禁止默认使用的旧思路

```lua
local auras = C_UnitAuras.GetUnitAuras(unit, filter)
for i = 1, #auras do
end
```

```lua
local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
if aura and aura.expirationTime > GetTime() then
end
```

```lua
if button:IsShown() then
end
```

这些写法都可能在 12.1 的 secret / forbidden 规则下失效。

## 查询顺序

1. 查 `.context/api-changes/`，新版本优先；12.1.0 仍是 PTR / beta 时先考虑刷新。
2. 用 `wow-api-mcp` 查 API 签名和废弃状态
3. 查 `warcraft.wiki.gg` 的具体 API 页
4. 必要时才查 `wow-ui-source-12.1.0/`
