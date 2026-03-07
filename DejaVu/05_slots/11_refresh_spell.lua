-- luacheck: globals C_Spell C_SpellBook Enum wipe
local addonName, addonTable = ... -- luacheck: ignore addonName
local GetSpellCharges = C_Spell.GetSpellCharges
local GetNumSpellBookSkillLines = C_SpellBook.GetNumSpellBookSkillLines
local GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo
local GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo
local IsSpellPassive = C_Spell.IsSpellPassive
local IsSpellBookItemOffSpec = C_SpellBook.IsSpellBookItemOffSpec
local InsertTable = table.insert
local Wipe = wipe

-- 本地化性能优化



local InitUI = addonTable.UpdateFunc.InitUI                               -- 初始化 UI 函数列表
local PLAYER_TALENT_CHANGED = addonTable.UpdateFunc.PLAYER_TALENT_CHANGED -- 所有涉及天赋变化的事件
local Slots = addonTable.Slots

Slots.chargeSpells = {}
Slots.cooldownSpells = {}


local chargeSpells = Slots.chargeSpells     -- 充能技能列表
local cooldownSpells = Slots.cooldownSpells -- 普通冷却技能列表





--- 获取技能冷却类型信息
---@param spellID number 技能ID
---@return "charges"|"cooldown" cdType 冷却类型
local function GetSpellCooldownType(spellID)
    -- `C_Spell.GetSpellCharges()` 对充能技能返回 `SpellChargeInfo`，
    -- 对非充能技能或无效技能返回 `nil`。
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
    InsertTable(spells, {
        spellID = 61304,
        cdType = "cooldown"
    })
    local spellBank = Enum.SpellBookSpellBank.Player

    -- 获取技能书技能线数量（标签页数量）
    local numSkillLines = GetNumSpellBookSkillLines()

    for skillLineIndex = 1, numSkillLines do
        -- 获取技能线信息
        local skillLineInfo = GetSpellBookSkillLineInfo(skillLineIndex)

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
                    local itemInfo = GetSpellBookItemInfo(slotIndex, spellBank)

                    -- 只处理 SPELL 类型，排除 FLYOUT、FUTURESPELL 等
                    if itemInfo and itemInfo.itemType == Enum.SpellBookItemType.Spell then
                        local spellID = itemInfo.spellID
                        if spellID then
                            -- 检查是否为被动技能
                            local isPassive = IsSpellPassive(spellID)

                            -- 检查是否为其他专精的技能（非当前专精）
                            local isOffSpec = IsSpellBookItemOffSpec(slotIndex, spellBank)

                            -- 只收集：非被动技能 且 非其他专精技能
                            if not isPassive and not isOffSpec then
                                -- 获取冷却类型信息
                                local cdType = GetSpellCooldownType(spellID)

                                InsertTable(spells, {
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
    Wipe(chargeSpells)
    Wipe(cooldownSpells)

    local spells = CollectActiveSpells()

    for spellIndex = 1, #spells do
        local spell = spells[spellIndex]
        if spell.cdType == "charges" then
            InsertTable(chargeSpells, spell)
        else
            InsertTable(cooldownSpells, spell)
        end
    end
    -- logging("chargeSpells: " .. #chargeSpells)
    -- logging("cooldownSpells: " .. #cooldownSpells)
end
InsertTable(InitUI, UpdateSpellsTable)                -- 初始化时建立技能列表
InsertTable(PLAYER_TALENT_CHANGED, UpdateSpellsTable) -- 天赋变更时刷新技能列表
