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
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
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
local CreateColorCurve = C_CurveUtil.CreateColorCurve


local InitUI = addonTable.Event.Func.InitUI -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell

local OnUpdateLow = addonTable.Event.Func.OnUpdateLow   -- 低频刷新回调列表（约 2 Hz）
local OnUpdateHigh = addonTable.Event.Func.OnUpdateHigh -- 高频刷新回调列表（约 10 Hz）

local remainingCurve = addonTable.Slots.remainingCurve
local playerDebuffCurve = addonTable.Slots.playerDebuffCurve
local enemyDebuffCurve = addonTable.Slots.enemyDebuffCurve
local playerBuffCurve = addonTable.Slots.playerBuffCurve



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
    local InstanceIDtoCell = {}

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

    local function wipeCells()
        for i = 1, maxCount do
            local cell = auraCells[i]
            cell.icon:clearCell()
            cell.duration:clearCell()
            cell.forever:clearCell()
            cell.count:clearCell()
        end
    end

    local function updateFullSequence()
        wipe(InstanceIDtoCell)
        if not UnitExists(unit) then
            wipeCells()
            return
        end
        local isEnemy = UnitIsEnemy("player", unit)
        local isPlayer = not isEnemy
        local auraInstanceIDs = GetUnitAuraInstanceIDs(unit, filter, maxCount, sortRule, sortDirection) or {}
        for i = 1, maxCount do
            local cell = auraCells[i]
            if i > #auraInstanceIDs then
                cell.count:clearCell()
                cell.duration:clearCell()
                cell.forever:clearCell()
                cell.icon:clearCell()
            else
                local auraInstanceID = auraInstanceIDs[i]
                InstanceIDtoCell[auraInstanceID] = cell
                local aura = GetAuraDataByAuraInstanceID(unit, auraInstanceID)
                if aura ~= nil then
                    local duration = GetAuraDuration(unit, auraInstanceID)
                    local foreverBoolen = DoesAuraHaveExpirationTime(unit, auraInstanceID)
                    local count = GetAuraApplicationDisplayCount(unit, auraInstanceID, 1, 9)

                    cell.count:setCell(count)

                    if duration ~= nil then
                        local durationColor = duration:EvaluateRemainingDuration(remainingCurve)
                        cell.duration:setCell(durationColor)
                    else
                        cell.duration:clearCell()
                    end

                    if foreverBoolen ~= nil then
                        local foreverColor = EvaluateColorFromBoolean(foreverBoolen, COLOR.BLACK, COLOR.WHITE) -- 白色是永久buff
                        cell.forever:setCell(foreverColor)
                    else
                        cell.forever:clearCell()
                    end

                    if isPlayer and isDebuff then
                        cell.icon:setCell(aura.icon, GetAuraDispelTypeColor(unit, auraInstanceID, playerDebuffCurve))
                    elseif isPlayer and isBuff then
                        cell.icon:setCell(aura.icon, GetAuraDispelTypeColor(unit, auraInstanceID, playerBuffCurve))
                    elseif isEnemy and isDebuff then
                        cell.icon:setCell(aura.icon, GetAuraDispelTypeColor(unit, auraInstanceID, enemyDebuffCurve))
                    end
                end
            end
        end
    end -- updateSequence
    table.insert(OnUpdateLow, updateFullSequence)
    wipeCells()
end



local InitializeAuraSequence = function() -- 初始化 aura 序列槽位
    AuraSequenceCreater("player", "HELPFUL", 30, 2, 4, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
end
table.insert(InitUI, InitializeAuraSequence) -- 初始化时创建 aura 序列槽位
