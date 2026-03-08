-- luacheck: globals C_Spell C_SpellBook Enum wipe
local addonName, addonTable = ... -- luacheck: ignore addonName
-- 本地化性能优化
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor
local DoesAuraHaveExpirationTime = C_UnitAuras.DoesAuraHaveExpirationTime
local UnitIsEnemy = UnitIsEnemy
local UnitExists = UnitExists
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean

local InitUI = addonTable.UpdateFunc.InitUI -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell

local OnUpdateHigh = addonTable.UpdateFunc.OnUpdateHigh           -- 高频刷新回调列表（约 10 Hz）
local UNIT_AURA = addonTable.UpdateFunc.UNIT_AURA                 -- UNIT_AURA 回调列表
local TARGET_CHANGED = addonTable.UpdateFunc.TARGET_CHANGED       -- 目标改变时触发，并不存在这个事件，多个事件会触发这个事件
local FOCUS_CHANGED = addonTable.UpdateFunc.FOCUS_CHANGED         -- 焦点改变时触发，并不存在这个事件，多个事件会触发这个事件
local MOUSEOVER_CHANGED = addonTable.UpdateFunc.MOUSEOVER_CHANGED -- 鼠标悬停改变时触发，并不存在这个事件，多个事件会触发这个事件

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
            icon = BadgeCell:New(x, y),         -- aura的图标
            remaining = Cell:New(x, y + 2),     -- aura的剩余时间的颜色映射
            forever = Cell:New(x, y + 2),       -- aura是否永久生效，覆盖在剩余时间上
            spellType = Cell:New(x + 1, y + 2), -- aura的类型颜色
            count = CharCell:New(x, y + 3)      -- 当的层数
        })
    end

    local function wipeCells()
        for i = 1, maxCount do
            local cell = auraCells[i]
            cell.icon:clearCell()
            cell.remaining:clearCell()
            cell.forever:clearCell()
            cell.spellType:clearCell()
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
                cell.remaining:clearCell()
                cell.forever:clearCell()
                cell.spellType:clearCell()
                cell.icon:clearCell()
            else
                local auraInstanceID = auraInstanceIDs[i]
                InstanceIDtoCell[auraInstanceID] = cell
                local aura = GetAuraDataByAuraInstanceID(unit, auraInstanceID)
                if aura ~= nil then
                    local remaining = GetAuraDuration(unit, auraInstanceID)
                    local foreverBoolen = DoesAuraHaveExpirationTime(unit, auraInstanceID)
                    local count = GetAuraApplicationDisplayCount(unit, auraInstanceID, 1, 9)

                    cell.count:setCell(count)

                    if remaining ~= nil then
                        local remainingColor = remaining:EvaluateRemainingDuration(remainingCurve)
                        cell.remaining:setCell(remainingColor)
                    else
                        cell.remaining:clearCell()
                    end

                    if foreverBoolen ~= nil then
                        local foreverColor = EvaluateColorFromBoolean(foreverBoolen, COLOR.TRANSPARENT, COLOR.WHITE) -- 白色是永久buff
                        cell.forever:setCell(foreverColor)
                    else
                        cell.forever:clearCell()
                    end

                    if isPlayer and isDebuff then
                        local debuffColor = GetAuraDispelTypeColor(unit, auraInstanceID, playerDebuffCurve)
                        cell.icon:setCell(aura.icon, debuffColor)
                        cell.spellType:setCell(debuffColor)
                    elseif isPlayer and isBuff then
                        local buffColor = GetAuraDispelTypeColor(unit, auraInstanceID, playerBuffCurve)
                        cell.icon:setCell(aura.icon, buffColor)
                        cell.spellType:setCell(buffColor)
                    elseif isEnemy and isDebuff then
                        local debuffColor = GetAuraDispelTypeColor(unit, auraInstanceID, enemyDebuffCurve)
                        cell.icon:setCell(aura.icon, debuffColor)
                        cell.spellType:setCell(debuffColor)
                    end
                end
            end
        end
    end -- updateSequence

    local function updatedRemaining()
        for auraInstanceID, cell in pairs(InstanceIDtoCell) do
            if cell ~= nil then
                local remaining = GetAuraDuration(unit, auraInstanceID)
                if remaining ~= nil then
                    local remainingColor = remaining:EvaluateRemainingDuration(remainingCurve)
                    cell.remaining:setCell(remainingColor)
                else
                    cell.remaining:clearCell()
                end
            end
        end
    end
    table.insert(OnUpdateHigh, updatedRemaining)
    table.insert(UNIT_AURA, { unit = unit, func = updateFullSequence })
    if unit == "target" then
        table.insert(TARGET_CHANGED, updateFullSequence)
    elseif unit == "focus" then
        table.insert(FOCUS_CHANGED, updateFullSequence)
    elseif unit == "mouseover" then
        table.insert(MOUSEOVER_CHANGED, updateFullSequence)
    end
    updateFullSequence()
end



local InitializeAuraSequence = function() -- 初始化 aura 序列槽位
    AuraSequenceCreater("player", "HELPFUL", 30, 2, 4, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
    AuraSequenceCreater("player", "HARMFUL", 10, 2, 9, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
    AuraSequenceCreater("target", "HARMFUL|PLAYER", 15, 22, 9, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
    AuraSequenceCreater("focus", "HARMFUL|PLAYER", 10, 2, 14, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
    AuraSequenceCreater("mouseover", "HARMFUL|PLAYER", 10, 22, 14, Enum.UnitAuraSortRule.Expiration, Enum.UnitAuraSortDirection.Normal)
end
table.insert(InitUI, InitializeAuraSequence) -- 初始化时创建 aura 序列槽位
