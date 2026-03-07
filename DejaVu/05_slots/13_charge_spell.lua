--[[
文件定位：
  DejaVu 充能技能槽位显示模块，负责充能技能的 Cell 布局与刷新。



状态：
  draft
]]

-- luacheck: globals C_Spell C_SpellActivationOverlay C_SpellBook C_CurveUtil
local addonName, addonTable = ... -- luacheck: ignore addonName
local GetSpellTexture = C_Spell.GetSpellTexture
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration

-- 本地化性能优化


local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell
local InitUI = addonTable.Event.Func.InitUI                 -- 初始化 UI 函数列表
local SPELLS_CHANGED = addonTable.Event.Func.SPELLS_CHANGED -- SPELLS_CHANGED 回调列表
local OnUpdateLow = addonTable.Event.Func.OnUpdateLow       -- 低频刷新回调列表（约 2 Hz）
local OnUpdateHigh = addonTable.Event.Func.OnUpdateHigh     -- 高频刷新回调列表（约 10 Hz）

local chargeSpells = Slots.chargeSpells                     -- 充能技能列表

local CHARGE_LENGTH = 10

local remainingCurve = Slots.remainingCurve



local function InitializeChargeFrame()
    local chargeCells = {}
    for i = 1, CHARGE_LENGTH do
        local x = 60 + 2 * i
        local y = 4
        table.insert(chargeCells, {
            icon = BadgeCell:New(x, y),         -- 技能图标
            remaining = Cell:New(x, y + 2),     -- 充能恢复剩余时间的颜色映射
            overlayed = Cell:New(x + 1, y + 2), -- 技能高亮提示
            unusable = Cell:New(x, y + 3),      -- 当前不可施放时显示白色
            unknown = Cell:New(x + 1, y + 3),   -- 不在法术书中时显示白色
            count = CharCell:New(x, y + 4)      -- 当前可用层数
        })
    end



    local function updateIcon() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID

                local iconID = GetSpellTexture(spellID)
                cell.icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
            else
                cell.icon:clearCell()
            end
        end
    end

    local function updateRemaining() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID
                local duration = GetSpellChargeDuration(spellID)
                local result = duration:EvaluateRemainingDuration(remainingCurve)
                cell.remaining:setCell(result)

                local chargeInfo = GetSpellCharges(spellID)
                cell.count:setCell(tostring(chargeInfo.currentCharges))
            else
                cell.remaining:clearCell()
            end
        end
    end

    local function updateOverlayed() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID

                local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(spellID), COLOR.WHITE, COLOR.BLACK)
                cell.overlayed:setCell(isOverlayed)
            else
                cell.overlayed:clearCell()
            end
        end
    end

    local function updateUnknown() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID



                local isUnknown = EvaluateColorFromBoolean(IsSpellInSpellBook(spellID), COLOR.BLACK, COLOR.WHITE)
                cell.unknown:setCell(isUnknown)
            else
                cell.unknown:clearCell()
            end
        end
    end

    local function updateUnusable() -- 全量更新
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID


                local isUnusable = EvaluateColorFromBoolean(IsSpellUsable(spellID), COLOR.BLACK, COLOR.WHITE)
                cell.unusable:setCell(isUnusable)
            else
                cell.unusable:clearCell()
            end
        end
    end

    local function fullUpdate() -- 全量更新
        updateIcon()
        updateRemaining()
        updateOverlayed()
        updateUnknown()
        updateUnusable()
    end
    fullUpdate()
    table.insert(SPELLS_CHANGED, updateIcon)      -- 技能变更时更新图标
    table.insert(SPELLS_CHANGED, updateRemaining) -- 技能变更时更新充能剩余时间
    table.insert(SPELLS_CHANGED, updateOverlayed) -- 技能变更时更新高亮状态
    table.insert(SPELLS_CHANGED, updateUnknown)   -- 技能变更时更新可用性状态
    table.insert(OnUpdateHigh, updateRemaining)   -- 高频更新充能剩余时间
    table.insert(OnUpdateLow, updateOverlayed)    -- 低频更新技能高亮状态
    table.insert(OnUpdateLow, updateUnusable)     -- 低频更新技能状态
end
table.insert(InitUI, InitializeChargeFrame)       -- 初始化时创建充能技能槽位
