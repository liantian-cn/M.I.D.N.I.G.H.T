# Secret Values 示例

这些例子只保留模式，不继承旧项目名称、模块结构、颜色表、矩阵尺寸或协议。示例里涉及 PTR / beta API 时，以最新 `.context/api-changes/` 和官方 API 签名为准。

## 1. 曲线映射颜色

不要把 secret 时间拆成数字再手算 RGB。让官方曲线对象完成映射。

```lua
local curve = C_CurveUtil.CreateColorCurve()
curve:SetType(Enum.LuaCurveType.Linear)
curve:AddPoint(0.0, CreateColor(0, 0, 0, 1))
curve:AddPoint(5.0, CreateColor(0.4, 0.4, 0.4, 1))
curve:AddPoint(30.0, CreateColor(0.7, 0.7, 0.7, 1))
curve:AddPoint(120.0, CreateColor(1, 1, 1, 1))

local duration = C_Spell.GetSpellCooldownDuration(spellID)
local color = duration:EvaluateRemainingDuration(curve)
texture:SetVertexColor(color:GetRGBA())
```

同一个模式也适合百分比曲线、类型曲线、剩余时间曲线。

## 2. 布尔值映射颜色

如果 API 返回的布尔值允许被用于显示，直接交给官方颜色选择器。

```lua
local color = C_CurveUtil.EvaluateColorFromBoolean(
    UnitAffectingCombat("player"),
    CreateColor(1, 0, 0, 1),
    CreateColor(0, 0, 0, 1)
)

texture:SetVertexColor(color:GetRGBA())
```

支持 boolean 显示的 Region，也优先用原生方法：

```lua
region:SetVertexColorFromBoolean(isActive, activeColor, inactiveColor)
region:SetAlphaFromBoolean(isActive, 1, 0.25)
```

## 3. 直接范围 CurveEvaluatedResult

能直接吃 curve 的单位 API，不要退回 `UnitHealth / UnitHealthMax` 自己除法。

```lua
local zeroToOne = C_CurveUtil.CreateColorCurve()
zeroToOne:SetType(Enum.LuaCurveType.Linear)
zeroToOne:AddPoint(0.0, CreateColor(0, 0, 0, 1))
zeroToOne:AddPoint(1.0, CreateColor(1, 1, 1, 1))

healthTexture:SetVertexColor(UnitHealthPercent("target", false, zeroToOne):GetRGBA())
powerTexture:SetVertexColor(UnitPowerPercent("target", UnitPowerType("target"), false, zeroToOne):GetRGBA())
```

同类思路包括 `UnitHealthMissing`、`UnitPowerMissing`，以及 `UnitHealPredictionCalculator:EvaluateCurrentHealthPercent` / `EvaluateMissingHealthPercent`。

## 4. DurationObject 到颜色

保留 duration object，不要先取 start/end/remaining 数字。

```lua
local color = duration:EvaluateElapsedDuration(curve)
local color = duration:EvaluateElapsedPercent(curve)
local color = duration:EvaluateRemainingDuration(curve)
local color = duration:EvaluateRemainingPercent(curve)
local color = duration:EvaluateTotalDuration(curve)
```

可作为 duration 来源的 API 包括 spell / action cooldown duration、`UnitCastingDuration`、`UnitChannelDuration`、`GetTotemDuration`、`C_LossOfControl.GetActiveLossOfControlDuration`。

## 5. Cooldown 直接接收 DurationObject

给 Cooldown frame 显示 secret duration 时，用 duration object 入口。

```lua
local duration = C_Spell.GetSpellCooldownDuration(spellID)
cooldown:SetCooldownFromDurationObject(duration)
```

不要把 secret duration 拆给 `SetCooldown`、`SetCooldownDuration`、`SetCooldownFromExpirationTime` 或 `SetCooldownUNIX`。

## 6. DurationTextBinding

需要文本倒计时时，不要自己 `string.format` secret 秒数。把 FontString 绑定到 duration。

```lua
local formatter = C_StringUtil.CreateSecondsFormatter()
formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
formatter:SetStripIntervalWhitespace(Enum.SecondsFormatterIntervalWhitespace.Strip)

local binding = C_DurationUtil.CreateDurationTextBinding()
binding:SetFontString(fontString)
binding:SetDuration(duration)
binding:SetFormatter(formatter)
binding:SetExpiredText("")
binding:Enable()
```

12.1 还增加了 `DurationTextBinding:SetTextColorCurve`，适合把倒计时文本颜色也交给曲线。

## 7. 数字 Formatter

显示 secret number 时，优先考虑官方 formatter 对象，而不是 `string.format`、字符串截断或拼接。

- `AbbreviatedNumberFormatter`
- `NumericRuleFormatter`
- `NumericFormatter`
- `SecondsFormatter`

12.0.5 起这些对象被设计为可由 duration / format API 接收 secret number。`string.format("%.5s", secretText)` 这类截断行为不能作为显示策略。

## 8. AuraContainer / AuraButton

12.1 Aura 显示优先走容器和按钮。插件负责摆放和外观，不读取底层 aura 列表做逻辑。

```lua
local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
container:SetUnit("target")
container:AddAuraFilter("HELPFUL", { maxFrameCount = 5 })

auraButton:SetIcon(iconTexture)
auraButton:SetDurationText(durationText)
container:AddAuraFrame(auraButton)
```

不要通过 AuraButton 的 `OnShow`、`IsShown`、HookScript 或事件注册反推 aura 状态。

## 9. Aura 官方显示辅助

在 API 明确允许读取具体 aura 的非 secret 场景，可以把显示交给官方辅助 API。

```lua
local color = C_UnitAuras.GetAuraDispelTypeColor(unit, auraInstanceID, dispelTypeCurve)
local countText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 1, 9)
```

如果 12.1 场景下拿到的是 secret vector 或 nil，改用 AuraContainer / AuraButton，不要遍历补救。

## 10. 自定义字体显示单个数字

单字符显示可以用自定义字体，但字体只是显示层，不是解密层。

```lua
local fontString = frame:CreateFontString(nil, "ARTWORK")
fontString:SetAllPoints(frame)
fontString:SetJustifyH("CENTER")
fontString:SetJustifyV("MIDDLE")
fontString:SetFont("Interface\\AddOns\\YourAddon\\PixNum.ttf", fontSize, "MONOCHROME")
fontString:SetText(displayText)
```

`displayText` 应来自官方 display API、formatter 或已确认安全的值。不要把 FontString 上的文本再读回来做逻辑。

## 11. Secret 值缓存比较

缓存可以省重绘，但不能比较 secret。只要当前值或上次值是 secret，就当作变化并重新交给显示 API。

```lua
local function sameDisplayValue(lastValue, lastWasSecret, nextValue)
    if lastValue == nil then
        return false
    end

    if lastWasSecret or issecretvalue(nextValue) then
        return false
    end

    return lastValue == nextValue
end
```

这个模式适合颜色、图标、文本、StatusBar value、min/max value。

## 12. 单位身份和威胁

单位 token、GUID、nameplate、party/raid 关系都可能被限制。先问官方 secret 判断 API，不能比较时不要分支。

```lua
if C_Secrets.CanCompareUnitTokens("player", unit) then
    isPlayer = UnitIsUnit("player", unit)
end

if C_Secrets.ShouldUnitThreatValuesBeSecret(unit) then
    threatBar:Hide()
else
    threatBar:Show()
end
```

具体签名以最新 API 文档为准；这里的重点是“先问能否比较/读取”，不是自己绕。

## 13. Tooltip 金钱

Tooltip 里显示 money 时，用官方 money line，避免自己拆 secret money 值。

```lua
GameTooltip_AddMoneyLine(tooltip, money)
```

同类原则：tooltip 只做显示，不把 tooltip 文本当数据源。

## 14. Radial progress

12.1 增加 radial progress 支持。需要圆形进度时，把百分比交给 texture/statusbar 的原生 radial API，不要自己把 secret percent 拆成角度。

```lua
texture:SetRadialProgressBarPercent(percent)
texture:SetRadialProgressBarStartOffset(0)
texture:SetRadialProgressBarEndOffset(1)
texture:SetRadialProgressBarReverse(false)
```

如果对象带 `Enum.SecretAspect.RadialProgress`，按 secret aspect 处理：只显示，不反查。

## 15. Forbidden Aspects 是硬限制

Secret value 是值不可用；Forbidden Aspect 是行为不可用。遇到 Forbidden 对象时，不要换个 Hook 点绕过。

```lua
if frame:HasAnyForbiddenAspect() then
    return
end
```

这个检查只适合诊断和早退。AuraContainer 管理的 AuraButton 尤其不能靠脚本处理器、hook、显示状态反推 aura。
