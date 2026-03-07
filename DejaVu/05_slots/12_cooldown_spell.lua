--[[
文件定位：
  DejaVu 冷却技能槽位显示模块，负责普通冷却技能的 Cell 布局与刷新。



状态：
  draft
]]

-- luacheck: globals C_Spell C_SpellActivationOverlay C_SpellBook C_CurveUtil
local addonName, addonTable = ... -- luacheck: ignore addonName
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean

-- 本地化性能优化

local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local InitUI = addonTable.UpdateFunc.InitUI                 -- 初始化 UI 函数列表
local SPELLS_CHANGED = addonTable.UpdateFunc.SPELLS_CHANGED -- SPELLS_CHANGED 回调列表
local OnUpdateLow = addonTable.UpdateFunc.OnUpdateLow       -- 低频刷新回调列表（约 2 Hz）
local OnUpdateHigh = addonTable.UpdateFunc.OnUpdateHigh     -- 高频刷新回调列表（约 10 Hz）

local cooldownSpells = Slots.cooldownSpells                 -- 普通冷却技能列表
local remainingCurve = Slots.remainingCurve                 -- 剩余时长映射曲线

local COOLDOWN_LENGTH = 40




local function InitializeCooldownFrame()
    local cooldownCells = {}
    for i = 1, COOLDOWN_LENGTH do
        local x = 2 * i
        local y = 0
        table.insert(cooldownCells, {
            icon = BadgeCell:New(x, y),         -- 技能图标
            remaining = Cell:New(x, y + 2),     -- 冷却剩余时间的颜色映射
            overlayed = Cell:New(x + 1, y + 2), -- 技能高亮提示
            unusable = Cell:New(x, y + 3),      -- 当前不可施放时显示白色
            unknown = Cell:New(x + 1, y + 3),   -- 不在法术书中时显示白色
        })
    end



    local function updateIcon() -- 更新图标
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local spellID = spell.spellID

                local iconID = GetSpellTexture(spellID)
                cell.icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
            else
                cell.icon:clearCell()
            end
        end
    end

    local function updateRemaining() -- 更新冷却剩余时间
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local spellID = spell.spellID
                local remaining = GetSpellCooldownDuration(spellID)
                local result = remaining:EvaluateRemainingDuration(remainingCurve)
                cell.remaining:setCell(result)
            else
                cell.remaining:clearCell()
            end
        end
    end

    local function updateOverlayed() -- 更新技能高亮状态
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local spellID = spell.spellID

                local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(spellID), COLOR.WHITE, COLOR.BLACK)
                cell.overlayed:setCell(isOverlayed)
            else
                cell.overlayed:clearCell()
            end
        end
    end

    local function updateUnusable() -- 更新技能不可施放状态
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local spellID = spell.spellID


                local isUnusable = EvaluateColorFromBoolean(IsSpellUsable(spellID), COLOR.BLACK, COLOR.WHITE)
                cell.unusable:setCell(isUnusable)
            else
                cell.unusable:clearCell()
            end
        end
    end

    local function updateUnknown() -- 更新技能是否不在法术书中
        for i = 1, COOLDOWN_LENGTH do
            local cell = cooldownCells[i]
            if i <= #cooldownSpells then
                local spell = cooldownSpells[i]
                local spellID = spell.spellID
                local isUnknown = EvaluateColorFromBoolean(IsSpellInSpellBook(spellID), COLOR.BLACK, COLOR.WHITE)
                cell.unknown:setCell(isUnknown)
            else
                cell.unknown:clearCell()
            end
        end
    end

    local function fullUpdate() -- 全量更新
        updateIcon()
        updateRemaining()
        updateOverlayed()
        updateUnusable()
        updateUnknown()
    end
    fullUpdate()
    table.insert(SPELLS_CHANGED, updateIcon)      -- 技能变更时更新图标
    table.insert(SPELLS_CHANGED, updateRemaining) -- 技能变更时更新冷却剩余时间
    table.insert(SPELLS_CHANGED, updateOverlayed) -- 技能变更时更新高亮状态
    table.insert(SPELLS_CHANGED, updateUnknown)   -- 技能变更时更新法术书收录状态
    table.insert(OnUpdateHigh, updateRemaining)   -- 高频更新冷却剩余时间
    table.insert(OnUpdateLow, updateOverlayed)    -- 低频更新技能高亮状态
    table.insert(OnUpdateLow, updateUnusable)     -- 低频更新技能不可施放状态
end
table.insert(InitUI, InitializeCooldownFrame)     -- 初始化时创建冷却技能槽位
