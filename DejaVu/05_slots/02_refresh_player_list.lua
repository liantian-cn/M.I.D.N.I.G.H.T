local addonName, addonTable = ...
-- 本地化性能优化

local GetSpellCharges = C_Spell.GetSpellCharges



local InitUI = addonTable.Event.Func.InitUI                             -- 初始化 UI 函数列表
local PLAYER_TALENT_UPDATE = addonTable.Event.Func.PLAYER_TALENT_UPDATE -- 专精更新事件函数列表
local TRAIT_CONFIG_UPDATED = addonTable.Event.Func.TRAIT_CONFIG_UPDATED -- 专精配置更新事件函数列表
local logging = addonTable.Logging
local Slots = addonTable.Slots

Slots.chargeSpells = {}
Slots.cooldownSpells = {}


local chargeSpells = Slots.chargeSpells     -- 充能技能的ID列表
local cooldownSpells = Slots.cooldownSpells -- 冷却技能的ID列表





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
    -- logging("chargeSpells: " .. #chargeSpells)
    -- logging("cooldownSpells: " .. #cooldownSpells)
end
table.insert(InitUI, UpdateSpellsTable)               -- 第二帧创建面板
table.insert(PLAYER_TALENT_UPDATE, UpdateSpellsTable) -- 第二帧创建面板
table.insert(TRAIT_CONFIG_UPDATED, UpdateSpellsTable) -- 第二帧创建面板
