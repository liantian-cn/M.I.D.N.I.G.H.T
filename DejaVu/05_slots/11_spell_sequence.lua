--[[
文件定位：
  DejaVu 施法序列Cell组配置模块，定义施法技能相关的Cell布局。



状态：
  draft
]]

local addonName, addonTable = ...
-- 本地化性能优化
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean

local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local InitUI = addonTable.Event.Func.InitUI                 -- 初始化 UI 函数列表
local SPELLS_CHANGED = addonTable.Event.Func.SPELLS_CHANGED -- 专精配置更新事件函数列表
local OnUpdateLow = addonTable.Event.Func.OnUpdateLow
local OnUpdateHigh = addonTable.Event.Func.OnUpdateHigh

local cooldownSpells = Slots.cooldownSpells -- 冷却技能的ID列表

local COOLDOWN_LENGTH = 40
local CHARGE_LENGTH = 10


local remaining_curve = CreateColorCurve()
remaining_curve:SetType(Enum.LuaCurveType.Linear)
remaining_curve:AddPoint(0.0, COLOR.C0)
remaining_curve:AddPoint(5.0, COLOR.C100)
remaining_curve:AddPoint(30.0, COLOR.C150)
remaining_curve:AddPoint(155.0, COLOR.C200)
remaining_curve:AddPoint(375.0, COLOR.C255)




local function InitializeCooldownFrame()
    local cooldownCells = {}
    for i = 1, COOLDOWN_LENGTH do
        local x = 2 * i
        local y = 0
        table.insert(cooldownCells, {
            icon = BadgeCell:New(x, y),         -- 技能图标
            remaining = Cell:New(x, y + 2),     -- 冷却事件
            overlayed = Cell:New(x + 1, y + 2), -- overlayed 是技能是否高亮，取自C_SpellActivationOverlay.IsSpellOverlayed
            unusable = Cell:New(x, y + 3),      -- unknown 和 unusable 是重合的，任意满足，该图标为白色，否则为透明色。 C_Spell.IsSpellUsable(spellID)
            unknown = Cell:New(x, y + 3),       -- unknown 和 unusable 是重合的，任意满足，该图标为白色，否则为透明色。  C_SpellBook.IsSpellInSpellBook(spellID)
        })
    end



    local function updateIcon() -- 全量更新
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local SpellID = spell.spellID

                local iconID = GetSpellTexture(SpellID)
                cell.icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
            else
                cell.icon:clearCell()
            end
            i = i + 1
        end
    end

    local function updateRemaining() -- 全量更新
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local SpellID = spell.spellID
                local duration = GetSpellCooldownDuration(SpellID)
                local result = duration:EvaluateRemainingDuration(remaining_curve)
                cell.remaining:setCell(result)
            else
                cell.remaining:clearCell()
            end
            i = i + 1
        end
    end

    local function updateOverlayed() -- 全量更新
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local SpellID = spell.spellID

                local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(SpellID), COLOR.WHITE, COLOR.TRANSPARENT)
                cell.overlayed:setCell(isOverlayed)
            else
                cell.overlayed:clearCell()
            end
            i = i + 1
        end
    end

    local function updateUnknownAndUnsable() -- 全量更新
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local SpellID = spell.spellID


                local isUnusable = EvaluateColorFromBoolean(IsSpellUsable(SpellID), COLOR.TRANSPARENT, COLOR.WHITE)
                cell.unusable:setCell(isUnusable)

                local isUnknown = EvaluateColorFromBoolean(IsSpellInSpellBook(SpellID), COLOR.TRANSPARENT, COLOR.WHITE)
                cell.unknown:setCell(isUnknown)
            else
                cell.unusable:clearCell()
                cell.unknown:clearCell()
            end
            i = i + 1
        end
    end

    local function fullUpdate() -- 全量更新
        updateIcon()
        updateRemaining()
        updateOverlayed()
        updateUnknownAndUnsable()
    end
    fullUpdate()
    table.insert(SPELLS_CHANGED, updateIcon)           -- 第二帧创建面板
    table.insert(OnUpdateHigh, updateRemaining)        -- 第二帧创建面板
    table.insert(OnUpdateHigh, updateOverlayed)        -- 第二帧创建面板
    table.insert(OnUpdateLow, updateUnknownAndUnsable) -- 第二帧创建面板
end
table.insert(InitUI, InitializeCooldownFrame)          -- 第二帧创建面板
