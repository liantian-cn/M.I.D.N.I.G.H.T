# WoW Patch 12.0.0 秘密值安全编码规范

> **版本**: 12.0.0 (Midnight)  
> **适用范围**: 所有 *.lua,*.xml, *.toc 文件  
> **核心原则**: 如果任意条件可能返回秘密值，则当作返回秘密值处理

---

## 1. 强制检查流程

在编写任何涉及以下数据的代码时，**必须**执行以下流程：

### 1.1 API 查询步骤

```
步骤1: 使用 wow-api-mcp 查询 API 文档
  ↓
步骤2: 检查返回值结构中的所有字段
  ↓
步骤3: 判断字段类型 (number/string/boolean/table)
  ↓
步骤4: 如果是基本类型且与战斗相关 → 假设为秘密值
  ↓
步骤5: 编写不依赖具体数值的安全代码
```

### 1.2 必须查询的API类别

| 类别 | 示例API | 风险等级 |
|------|---------|----------|
| 技能冷却 | `C_Spell.GetSpellCooldown()` | 🔴 高 |
| 技能充能 | `C_Spell.GetSpellCharges()` | 🔴 高 |
| 单位生命 | `UnitHealth()`, `UnitHealthMax()` | 🔴 高 |
| 单位能量 | `UnitPower()`, `UnitPowerMax()` | 🔴 高 |
| 单位信息 | `UnitName()`, `UnitClass()` | 🟡 中 |
| 光环/增益 | `UnitAura()`, `C_UnitAuras.GetAuraDataByIndex()` | 🔴 高 |
| 施法信息 | `UnitCastingInfo()`, `UnitChannelInfo()` | 🟡 中 |
| 威胁值 | `UnitThreatSituation()`, `UnitDetailedThreatSituation()` | 🔴 高 |

---

## 2. 秘密值判定规则

### 2.1 绝对判定（当作秘密值处理）

以下情况**必须**将数据视为秘密值：

1. **数值类型** + **战斗相关** = 🔴 秘密值
2. **布尔类型** + **状态相关** = 🔴 秘密值  
3. **时间相关**（冷却、持续时间）= 🔴 秘密值
4. **单位属性**（生命、能量、属性）= 🔴 秘密值
5. **API文档**明确标记`SecretReturns`或`ConditionalSecret` = 🔴 秘密值

### 2.2 安全类型

以下类型通常**不是**秘密值：

- 本地化字符串（技能名称、描述）
- 图标ID/纹理路径
- 静态配置数据（技能ID、枚举值）
- 类型标识（`Enum.SpellBookItemType.Spell`）

### 2.3 查询验证模板

```lua
-- 使用 wow-api-mcp 查询后，记录结果：
-- API: C_Spell.GetSpellCooldown
-- 返回: SpellCooldownInfo
-- 字段分析:
--   - startTime: number → 🔴 秘密值（时间）
--   - duration: number → 🔴 秘密值（时间）
--   - isEnabled: boolean → 🔴 秘密值（状态）
--   - modRate: number → 🔴 秘密值（数值）
-- 结论: 所有字段都可能是秘密值，禁止比较运算
```

---

## 3. 禁止操作清单

### 3.1 绝对禁止的代码模式

```lua
-- ❌ 禁止：比较运算
if cdInfo.duration > 0 then end
if hp < maxHp * 0.3 then end
if charges.currentCharges == 2 then end

-- ❌ 禁止：布尔测试
if cdInfo.isEnabled then end
if aura.isStealable then end

-- ❌ 禁止：算术运算
local remaining = cdInfo.duration - (GetTime() - cdInfo.startTime)
local percent = hp / maxHp

-- ❌ 禁止：作为table键
local t = {}
t[cdInfo.duration] = value
t[unitName] = data

-- ❌ 禁止：长度运算
local len = #secretString

-- ❌ 禁止：索引访问
local value = secret["field"]

-- ❌ 禁止：pcall保护（无法阻止秘密值污染，且pcall本身会成为秘密函数）
local ok, result = pcall(function() return secretValue > 0 end)
```

### 3.2 危险操作检测清单

在代码审查时，检查以下模式：

| 模式 | 正则表达式 | 风险 |
|------|-----------|------|
| 比较运算 | `\w+\s*[<>=!]+\s*\w+` | 🔴 高 |
| 算术运算 | `\w+\s*[\+\-\*\/\%]` | 🔴 高 |
| 布尔测试 | `if\s+\w+\s+then` | 🔴 高 |
| 字段访问 | `\.\w+\s*[<>=!]` | 🔴 高 |
| table键 | `\[.*\]\s*=` | 🟡 中 |
| pcall保护 | `pcall\s*\(` | 🔴 高 |

---

## 4. 安全编码模式

### 4.1 模式一：存在性检查（推荐）

```lua
-- ✅ 安全：只检查对象是否存在
local cdInfo = C_Spell.GetSpellCooldown(spellID)
if cdInfo then
    -- 有冷却信息，但不访问具体数值
    ShowCooldownIndicator()
end

-- ✅ 安全：检查充能技能
local chargeInfo = C_Spell.GetSpellCharges(spellID)
if chargeInfo then
    -- 是充能技能
    return "charges"
end
```

### 4.2 模式二：直接传递给Widget

```lua
-- ✅ 安全：Widget API接受秘密值
local cdInfo = C_Spell.GetSpellCooldown(spellID)
if cdInfo then
    myCooldown:SetCooldown(cdInfo.startTime, cdInfo.duration)
end

-- ✅ 安全：StatusBar接受秘密值
local hp = UnitHealth("player")
local maxHp = UnitHealthMax("player")
healthBar:SetMinMaxValues(0, maxHp)
healthBar:SetValue(hp)
```

### 4.3 模式三：字符串输出

```lua
-- ✅ 安全：字符串拼接
print("Cooldown: " .. cdInfo.duration)

-- ✅ 安全：string.format
local text = string.format("%.1f seconds", cdInfo.duration)

-- ✅ 安全：存储到table
local spells = {}
table.insert(spells, {
    name = spellName,
    cooldown = cdInfo.duration  -- 安全存储
})
```

### 4.4 模式四：使用DurationObject/CurveObject

```lua
-- ✅ 安全：使用DurationObject处理时间
local duration = C_DurationUtil.CreateDuration()
-- 配置duration...
myStatusBar:SetTimerDuration(duration)

-- ✅ 安全：使用ColorCurve映射值到颜色
local curve = C_CurveUtil.CreateColorCurve()
-- 配置curve...
myStatusBar:SetStatusBarColor(curve:GetColorAt(value))
```

---

## 5. API查询与验证

### 5.1 查询流程

当使用任何API时，执行：

```
1. 调用 wow-api-mcp/lookup-api 或 wow-api-mcp/search-api
2. 检查返回值的每个字段
3. 根据字段类型和用途判断秘密值风险
4. 编写对应的安全代码
```

### 5.2 查询示例

```lua
-- 查询API: C_Spell.GetSpellCharges
-- MCP返回:
--   返回: SpellChargeInfo | nil
--   字段: currentCharges(number), maxCharges(number), 
--         cooldownStartTime(number), cooldownDuration(number)
--
-- 分析:
--   - 所有字段都是number类型
--   - 与战斗/冷却相关
--   - 🔴 全部视为秘密值
--
-- 安全代码:
local chargeInfo = C_Spell.GetSpellCharges(spellID)
if chargeInfo then
    -- 确定是充能技能，但不访问字段
    return { type = "charges" }
end
```

### 5.3 C_Secrets查询（辅助）

```lua
-- 查询是否为秘密值
local secrecyLevel = C_Secrets.GetSpellCooldownSecrecy(spellID)
-- Enum.SecrecyLevel: NeverSecret(0), AlwaysSecret(1), ContextuallySecret(2)

-- 直接判断
if C_Secrets.ShouldSpellCooldownBeSecret(spellID) then
    -- 当前是秘密值
end
```

---

## 6. 常见API安全处理指南

### 6.1 C_Spell.GetSpellCooldown

```lua
-- 🔴 所有字段都是秘密值
local cdInfo = C_Spell.GetSpellCooldown(spellID)

-- ✅ 安全用法
if cdInfo then
    myCooldown:SetCooldown(cdInfo.startTime, cdInfo.duration)
end

-- ❌ 危险用法
if cdInfo.duration > 0 then end  -- 错误！
if cdInfo.isEnabled then end      -- 错误！
```

### 6.2 C_Spell.GetSpellCharges

```lua
-- 🔴 所有字段都是秘密值
local chargeInfo = C_Spell.GetSpellCharges(spellID)

-- ✅ 安全用法
if chargeInfo then
    return "has_charges"
end

-- ❌ 危险用法
if chargeInfo.currentCharges > 1 then end  -- 错误！
```

### 6.3 UnitHealth / UnitHealthMax

```lua
-- 🔴 返回值是秘密值
local hp = UnitHealth("target")
local maxHp = UnitHealthMax("target")

-- ✅ 安全用法
healthBar:SetMinMaxValues(0, maxHp)
healthBar:SetValue(hp)

-- ❌ 危险用法
if hp < maxHp * 0.5 then end  -- 错误！
```

### 6.4 UnitName / UnitClass

```lua
-- 🟡 可能为秘密值（战斗中单位身份受限时）
local name = UnitName("target")
local class = UnitClass("target")

-- ✅ 安全用法
nameplate:SetText(name)

-- ❌ 危险用法
if name == "BossName" then end  -- 错误！
```

---

## 7. 代码审查检查表

在提交代码前，确认以下检查项：

- [ ] 所有战斗相关API都通过wow-api-mcp查询
- [ ] 所有number/boolean类型的返回值都视为秘密值
- [ ] 没有使用比较运算（>, <, ==, >=, <=, ~=）
- [ ] 没有使用算术运算（+, -, *, /, %）
- [ ] 没有使用布尔测试（if value then）
- [ ] 没有将可能为秘密的值作为table键
- [ ] Widget API调用接受秘密值参数
- [ ] 使用存在性检查（if obj then）而非字段检查

---

## 8. 错误处理

### 8.1 常见错误信息

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `attempt to compare field 'duration' (a secret number)` | 比较秘密值 | 使用存在性检查 |
| `attempt to perform boolean test on field 'isEnabled' (a secret boolean)` | 布尔测试秘密值 | 检查对象存在性 |
| `attempt to perform arithmetic on a secret value` | 算术运算 | 使用DurationObject |
| `attempt to use a secret value as a table key` | table键 | 使用非秘密值作为键 |

### 8.2 调试方法

```lua
-- 检查是否为秘密值
if issecretvalue(value) then
    print("Value is secret")
end

-- 检查是否可以访问
if canaccessvalue(value) then
    -- 可以安全操作
end
```

---

## 9. 关键原则总结

1. **查询优先**: 使用wow-api-mcp检查每个API的返回值
2. **保守假设**: 如果任意条件可能返回秘密值，则当作返回秘密值处理
3. **禁止比较**: 永远不要对API返回值进行数值或布尔比较
4. **禁止运算**: 永远不要对API返回值进行算术运算
5. **Widget友好**: 优先将秘密值直接传递给Widget API
6. **存在性检查**: 使用`if obj then`而非`if obj.field then`

---

> **记住**: 在Patch 12.0.0中，安全比功能更重要。如果无法确定数据是否为秘密值，假设它是秘密值并编写安全代码。
