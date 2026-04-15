# 显示优先模式

这份文档只讲一件事: 在 WoW 12.x 里, DejaVu 这种展示型插件, 应该怎样把战斗属性**安全地显示出来**。

重点不是“算出一个结论”, 而是:

- 尽量少做 Lua 计算
- 尽量直接使用官方返回的 percent / duration / curve 结果
- 把状态翻译成颜色、图标、亮灭、进度

## 最重要的 5 条规则

- 血量和能量优先用百分比接口, 不自己做除法
- 施法、引导、冷却、Aura 时间优先用 duration 对象, 不自己减时间
- 布尔状态优先转成颜色、亮灭、角标, 不做综合评分
- Aura 列表优先按实例 ID 维护槽位
- UI 刷新优先分层: 事件更新、标准频率更新、低频更新

## 1. 血量和能量: 直接显示百分比

最稳的路线不是:

- 先拿当前值
- 再拿最大值
- 自己算百分比

而是直接显示官方给的百分比结果。

### 示例: 血量显示

```lua
local healthColor = UnitHealthPercent(unit, true, curve)
healthTexture:SetColorTexture(healthColor:GetRGBA())
```

### 示例: 能量显示

```lua
local powerType = UnitPowerType(unit)
local powerColor = UnitPowerPercent(unit, powerType, true, curve)
powerTexture:SetColorTexture(powerColor:GetRGBA())
```

### 适合 DejaVu 的原因

- 不需要自己做 `current / max`
- 更符合展示用途
- 更不容易踩 `secret values`

## 2. 施法和引导: 直接显示进度

施法条和引导条, 不要自己做时间差计算。优先使用 duration 对象。

### 示例: 施法进度

```lua
local _, _, castTextureID = UnitCastingInfo(unit)
if castTextureID then
    castIcon:SetTexture(castTextureID)

    local duration = UnitCastingDuration(unit)
    local result = duration:EvaluateElapsedPercent(curve)
    castProgress:SetColorTexture(result:GetRGBA())
else
    castIcon:SetColorTexture(0, 0, 0, 1)
    castProgress:SetColorTexture(0, 0, 0, 1)
end
```

### 示例: 引导进度

```lua
local _, _, channelTextureID = UnitChannelInfo(unit)
if channelTextureID then
    channelIcon:SetTexture(channelTextureID)

    local duration = UnitChannelDuration(unit)
    local result = duration:EvaluateElapsedPercent(curve)
    channelProgress:SetColorTexture(result:GetRGBA())
else
    channelIcon:SetColorTexture(0, 0, 0, 1)
    channelProgress:SetColorTexture(0, 0, 0, 1)
end
```

### 不推荐的思路

- `endTime - GetTime()`
- `duration - elapsed`
- 手写剩余秒数再决定颜色

## 3. 冷却和充能: 显示剩余进度, 不自己算秒数

### 示例: 普通冷却

```lua
local duration = C_Spell.GetSpellCooldownDuration(spellID)
local result = duration:EvaluateRemainingDuration(remainingCurve)
cooldownTexture:SetColorTexture(result:GetRGBA())
```

### 示例: 充能技能

```lua
local duration = C_Spell.GetSpellChargeDuration(spellID)
local result = duration:EvaluateRemainingDuration(remainingCurve)
chargeCooldownTexture:SetColorTexture(result:GetRGBA())

local chargeInfo = C_Spell.GetSpellCharges(spellID)
chargeText:SetText(tostring(chargeInfo.currentCharges))
```

### 适合 DejaVu 的做法

- 图标负责“这是什么技能”
- 进度色负责“还剩多少”
- 小文本负责“当前层数”
- 不把冷却再加工成自动建议

## 4. Aura: 结构变化和进度变化分开

Aura 最稳的写法, 不是每次全量重建, 而是先维护槽位身份, 再单独刷剩余时间。

### 示例: 事件阶段, 按实例 ID 更新槽位

```lua
local auraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, maxCount, sortRule, sortDirection) or {}

for index = 1, #auraInstanceIDs do
    local auraInstanceID = auraInstanceIDs[index]
    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)

    if aura then
        slot.icon:SetTexture(aura.icon)
        slotState[index] = auraInstanceID

        local count = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 1, 9)
        slot.count:SetText(count)
    end
end
```

### 示例: 标准刷新阶段, 只更新剩余时间

```lua
for index, auraInstanceID in pairs(slotState) do
    local duration = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
    if duration then
        local result = duration:EvaluateRemainingDuration(remainingCurve)
        slots[index].duration:SetColorTexture(result:GetRGBA())
    end
end
```

### 这样拆的好处

- 图标和层数变化不频繁, 走事件更新
- 剩余时间变化频繁, 走标准刷新
- 逻辑更清楚, 也更省维护成本

## 5. 布尔状态: 用亮灭和颜色表达

很多状态最适合变成一个简单视觉信号, 例如:

- 是否存在
- 是否存活
- 是否在战斗中
- 是否可打断
- 是否可用
- 是否高亮

### 示例: 白色表示开启, 黑色表示关闭

```lua
if UnitAffectingCombat(unit) then
    inCombat:SetColorTexture(1, 1, 1, 1)
else
    inCombat:SetColorTexture(0, 0, 0, 1)
end
```

### 示例: 用布尔转颜色

```lua
local value = C_CurveUtil.EvaluateColorFromBoolean(isUsable, COLOR.WHITE, COLOR.BLACK)
usableTexture:SetColorTexture(value:GetRGBA())
```

### 对 DejaVu 的启发

不要急着把多个状态合并成一个“智能分数”。

更稳的方式通常是:

- 一个格子表达一个状态
- 一个颜色表达一种含义
- 一个角标表达一个附加状态

## 6. 吸收条: 直接用条形控件显示

如果目标只是展示吸收量, 优先让 `StatusBar` 直接工作。

### 示例

```lua
local maxHealth = UnitHealthMax(unit)
absorbBar:SetMinMaxValues(0, maxHealth)
absorbBar:SetValue(UnitGetTotalAbsorbs(unit))
healAbsorbBar:SetValue(UnitGetTotalHealAbsorbs(unit))
```

### 这里真正值得学的点

不是“去推导吸收逻辑”, 而是:

- 最大值由官方接口给
- 当前值由官方接口给
- 界面直接显示

## 7. 刷新分层: 不要一个函数包打天下

推荐拆成三层:

### 事件更新

适合:

- 技能列表变化
- Aura 列表变化
- 最大生命值变化
- 配置切换

### 标准频率更新

适合:

- 冷却进度
- 施法进度
- 引导进度
- Aura 剩余时间
- 当前血量/能量显示

### 低频更新

适合:

- 职业色
- 团队职责
- 距离状态
- 已知/未知技能

## 8. 给 DejaVu 的直接落地建议

如果你在写:

- `DejaVu_Matrix`
- `DejaVu_Player` / `DejaVu_Party` / `DejaVu_Enemy` / `DejaVu_Spell` / `DejaVu_Aura`
- 各专精目录

优先遵守下面的顺序:

1. 先决定这个信息是“显示”还是“判断”
2. 如果只是显示, 优先找 percent / duration / 原生控件
3. 把状态拆成颜色、亮灭、图标、角标
4. 把结构变化和进度变化拆开刷新
5. 不要把显示数据再反向拼成战斗决策

## 一句话总结

DejaVu 最适合走的路线是:

**少算, 多显示；少推理, 多映射；少自己展开战斗数据, 多让官方对象直接驱动 UI。**
