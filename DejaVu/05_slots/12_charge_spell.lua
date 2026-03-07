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
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local GetSpellLink = C_Spell.GetSpellLink
local GetCooldownViewerCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet
local GetCooldownViewerCooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo


local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell
local InitUI = addonTable.Event.Func.InitUI                 -- 初始化 UI 函数列表
local SPELLS_CHANGED = addonTable.Event.Func.SPELLS_CHANGED -- 专精配置更新事件函数列表
local OnUpdateLow = addonTable.Event.Func.OnUpdateLow
local OnUpdateHigh = addonTable.Event.Func.OnUpdateHigh

local chargeSpells = Slots.chargeSpells -- 冷却技能的ID列表

local CHARGE_LENGTH = 10

local remainingCurve = Slots.remainingCurve



local function InitializeChargeFrame()
    local chargeCells = {}
    for i = 1, CHARGE_LENGTH do
        local x = 60 + 2 * i
        local y = 4
        table.insert(chargeCells, {
            icon = BadgeCell:New(x, y),         -- 技能图标
            remaining = Cell:New(x, y + 2),     -- 冷却事件
            overlayed = Cell:New(x + 1, y + 2), -- overlayed 是技能是否高亮，取自C_SpellActivationOverlay.IsSpellOverlayed
            unusable = Cell:New(x, y + 3),      --  unusable 满足，该图标为白色，否则为透明色。 C_Spell.IsSpellUsable(spellID)
            unknown = Cell:New(x + 1, y + 3),   -- unknown 满足，该图标为白色，否则为透明色。  C_SpellBook.IsSpellInSpellBook(spellID)
            count = CharCell:New(x, y + 4)
        })
    end



    local function updateIcon() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
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
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local SpellID = spell.spellID
                local duration = GetSpellChargeDuration(SpellID)
                local result = duration:EvaluateRemainingDuration(remainingCurve)
                cell.remaining:setCell(result)

                local chargeInfo = GetSpellCharges(SpellID)
                cell.count:setCell(tostring(chargeInfo.currentCharges))
            else
                cell.remaining:clearCell()
            end
            i = i + 1
        end
    end

    local function updateOverlayed() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
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
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
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
    table.insert(SPELLS_CHANGED, updateIcon)              -- 第二帧创建面板
    table.insert(SPELLS_CHANGED, updateRemaining)         -- 第二帧创建面板
    table.insert(SPELLS_CHANGED, updateOverlayed)         -- 第二帧创建面板
    table.insert(SPELLS_CHANGED, updateUnknownAndUnsable) -- 第二帧创建面板
    table.insert(OnUpdateHigh, updateRemaining)           -- 第二帧创建面板
    table.insert(OnUpdateLow, updateOverlayed)            -- 第二帧创建面板
    table.insert(OnUpdateLow, updateUnknownAndUnsable)    -- 第二帧创建面板
end
table.insert(InitUI, InitializeChargeFrame)               -- 第二帧创建面板
