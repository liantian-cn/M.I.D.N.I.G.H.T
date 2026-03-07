-- luacheck: globals C_Spell C_SpellBook Enum wipe
local addonName, addonTable = ... -- luacheck: ignore addonName
-- 本地化性能优化
local GetSpellCharges = C_Spell.GetSpellCharges
local GetNumSpellBookSkillLines = C_SpellBook.GetNumSpellBookSkillLines
local GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo
local GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo
local IsSpellPassive = C_Spell.IsSpellPassive
local IsSpellBookItemOffSpec = C_SpellBook.IsSpellBookItemOffSpec
local InsertTable = table.insert
local Wipe = wipe
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor
local DoesAuraHaveExpirationTime = C_UnitAuras.DoesAuraHaveExpirationTime
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealthMax = UnitHealthMax
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit
local UnitIsEnemy = UnitIsEnemy
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitChannelDuration = UnitChannelDuration
local UnitCastingDuration = UnitCastingDuration
local UnitInVehicle = UnitInVehicle
local IsMounted = IsMounted
local GetUnitSpeed = GetUnitSpeed
local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local IsSpellUsable = C_Spell.IsSpellUsable
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local GetSpellLink = C_Spell.GetSpellLink


local InitUI = addonTable.Event.Func.InitUI -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell

local function AuraSequenceCreater(unit, filter, maxCount, pos_x, pos_y, sortRule, sortDirection)
    sortRule = sortRule or Enum.UnitAuraSortRule.Default
    sortDirection = sortDirection or Enum.UnitAuraSortDirection.Normal

    local start_idx, end_idx = string.find(filter, "HELPFUL")
    local isBuff = false
    local isDebuff = false
    if start_idx then
        isBuff = true
    else
        isDebuff = true
    end

    local auraCells = {}

    for i = 1, maxCount do
        local x = pos_x - 2 + 2 * i
        local y = pos_y
        table.insert(auraCells, {
            icon = BadgeCell:New(x, y),       -- aura的图标
            duration = Cell:New(x, y + 2),    -- aura的剩余时间的颜色映射
            forever = Cell:New(x + 1, y + 2), -- aura是否永久生效
            count = CharCell:New(x, y + 3)    -- 当的层数
        })
    end
end



local InitializeAuraSequence = function() -- 初始化 aura 序列槽位
    AuraSequenceCreater("player", "HELPFUL", 30, 2, 4, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Norma)
end
table.insert(InitUI, InitializeAuraSequence) -- 初始化时创建 aura 序列槽位
