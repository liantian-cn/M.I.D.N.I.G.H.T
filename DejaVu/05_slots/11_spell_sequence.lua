--[[
文件定位：
  DejaVu 施法序列Cell组配置模块，定义施法技能相关的Cell布局。



状态：
  draft
]]

local addonName, addonTable = ...
-- 本地化性能优化
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local GetSpellLink = C_Spell.GetSpellLink
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local GetCooldownViewerCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet
local GetCooldownViewerCooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo

local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local MegaCell = addonTable.MegaCell
local BadgeCell = addonTable.BadgeCell
local InitUI = addonTable.Event.Func.InitUI                             -- 初始化 UI 函数列表
local PLAYER_TALENT_UPDATE = addonTable.Event.Func.PLAYER_TALENT_UPDATE -- 专精更新事件函数列表
local TRAIT_CONFIG_UPDATED = addonTable.Event.Func.TRAIT_CONFIG_UPDATED -- 专精配置更新事件函数列表
local SPELLS_CHANGED = addonTable.Event.Func.SPELLS_CHANGED             -- 专精配置更新事件函数列表
local OnUpdateLow = addonTable.Event.Func.OnUpdateLow
local OnUpdateHigh = addonTable.Event.Func.OnUpdateHigh
local logging = addonTable.Logging

local chargeSpells = {}   -- 充能技能的ID列表
local cooldownSpells = {} -- 冷却技能的ID列表


local COOLDOWN_LENGTH = 40
local CHARGE_LENGTH = 10


local remaining_curve = CreateColorCurve()
remaining_curve:SetType(Enum.LuaCurveType.Linear)
remaining_curve:AddPoint(0.0, COLOR.C0)
remaining_curve:AddPoint(5.0, COLOR.C100)
remaining_curve:AddPoint(30.0, COLOR.C150)
remaining_curve:AddPoint(155.0, COLOR.C200)
remaining_curve:AddPoint(375.0, COLOR.C255)
addonTable.remaining_curve = remaining_curve


--- 获取技能冷却类型信息
---@param spellID number 技能ID
---@return "charges"|"cooldown" cdType 冷却类型
local function GetSpellCooldownType(spellID)
    -- 检查是否为充能技能
    -- C_Spell.GetSpellCharges() 返回值：
    --   - nil = cooldown 技能
    --   - table = charge 技能（table本身不是秘密值，可以if判断）
    local chargeInfo = GetSpellCharges(spellID)
    if chargeInfo then
        return "charges"
    end

    return "cooldown"
end

--- 统计当前角色的技能书内的技能
--- 只包含当前专精的技能，不含被动技能，不含其他专精技能，不含通用技能
---@return table[] spells 技能列表
local function CollectActiveSpells()
    local spells = {}
    table.insert(spells, {
        spellID = 61304,
        cdType = "cooldown"
    })
    local spellBank = Enum.SpellBookSpellBank.Player

    -- 获取技能书技能线数量（标签页数量）
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()

    for skillLineIndex = 1, numSkillLines do
        -- 获取技能线信息
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)

        if skillLineInfo and skillLineInfo.numSpellBookItems > 0 then
            -- 跳过通用技能标签页（通常是第一个标签页 "通用"）
            -- 通用技能线通常是技能书索引 1，或者通过名字判断
            local isGeneralSkillLine = (skillLineIndex == 1)

            -- 只处理非通用技能线
            if not isGeneralSkillLine then
                -- 遍历该技能线下的所有技能项
                local startSlot = skillLineInfo.itemIndexOffset + 1
                local endSlot = skillLineInfo.itemIndexOffset + skillLineInfo.numSpellBookItems

                for slotIndex = startSlot, endSlot do
                    -- 获取技能项信息
                    local itemInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)

                    -- 只处理 SPELL 类型，排除 FLYOUT、FUTURESPELL 等
                    if itemInfo and itemInfo.itemType == Enum.SpellBookItemType.Spell then
                        local spellID = itemInfo.spellID
                        if spellID then
                            -- 检查是否为被动技能
                            local isPassive = C_Spell.IsSpellPassive(spellID)

                            -- 检查是否为其他专精的技能（非当前专精）
                            local isOffSpec = C_SpellBook.IsSpellBookItemOffSpec(slotIndex, spellBank)

                            -- 只收集：非被动技能 且 非其他专精技能
                            if not isPassive and not isOffSpec then
                                -- 获取冷却类型信息
                                local cdType = GetSpellCooldownType(spellID)

                                table.insert(spells, {
                                    spellID = spellID,
                                    cdType = cdType
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    return spells
end

local function UpdateSpellsTable()
    wipe(chargeSpells)
    wipe(cooldownSpells)

    local spells = CollectActiveSpells()

    for _, spell in ipairs(spells) do
        if spell.cdType == "charges" then
            table.insert(chargeSpells, spell)
        else
            table.insert(cooldownSpells, spell)
        end
    end
    logging("chargeSpells: " .. #chargeSpells)
    logging("cooldownSpells: " .. #cooldownSpells)
end
table.insert(InitUI, UpdateSpellsTable)               -- 第二帧创建面板
table.insert(PLAYER_TALENT_UPDATE, UpdateSpellsTable) -- 第二帧创建面板
table.insert(TRAIT_CONFIG_UPDATED, UpdateSpellsTable) -- 第二帧创建面板



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
