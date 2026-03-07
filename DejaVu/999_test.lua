-- WoW 插件测试脚本
-- 这是一个独立的测试文件，与其他文件无关

-- 本地函数：安全获取秘密值的类型
local function SafeGetType(value)
    return pcall(function() return type(value) end) and "secret" or "normal"
end

-- 本地函数：获取技能冷却类型信息
-- 返回: "charges"=充能技能, "cooldown"=普通冷却, "unknown"=无法判断（秘密值）
local function GetSpellCooldownType(spellID)
    -- 先检查是否为充能技能
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if chargeInfo then
        -- 尝试获取 maxCharges，如果是秘密值则使用 pcall
        local ok, maxCharges = pcall(function()
            return chargeInfo.maxCharges
        end)
        -- 如果成功获取且 maxCharges > 1，则是充能技能
        if ok and maxCharges then
            local ok2, isMulti = pcall(function() return maxCharges > 1 end)
            if ok2 and isMulti then
                return "charges", chargeInfo
            end
        end
        -- 如果能获取到 chargeInfo 但无法判断层数，仍然认为是充能技能
        if ok then
            return "charges", chargeInfo
        end
    end

    -- 检查普通冷却
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if cdInfo then
        -- 只要有冷却信息就认为是冷却技能（避免判断具体数值）
        return "cooldown", cdInfo
    end

    return "unknown", nil
end

-- 本地函数：统计当前角色的技能书内的技能
-- 只包含当前专精的技能，不含被动技能，不含其他专精技能，不含通用技能
local function CollectActiveSpells()
    local spells = {}
    local spellBank = Enum.SpellBookSpellBank.Player

    -- 获取技能书技能线数量（标签页数量）
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()

    for skillLineIndex = 1, numSkillLines do
        -- 获取技能线信息
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)

        if skillLineInfo and skillLineInfo.numSpellBookItems > 0 then
            -- 跳过通用技能标签页（通常是第一个标签页 "通用"）
            -- 通用技能线通常是技能书索引 1，或者通过名字判断
            local isGeneralSkillLine = (skillLineIndex == 1) or
                (skillLineInfo.name == "通用") or
                (skillLineInfo.name == "General")

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

                        -- 检查是否为被动技能
                        local isPassive = C_Spell.IsSpellPassive(spellID)

                        -- 检查是否为其他专精的技能（非当前专精）
                        local isOffSpec = C_SpellBook.IsSpellBookItemOffSpec(slotIndex, spellBank)

                        -- 只收集：非被动技能 且 非其他专精技能
                        if not isPassive and not isOffSpec then
                            -- 获取技能名称
                            local spellName = C_Spell.GetSpellName(spellID)

                            -- 获取冷却类型信息
                            local cdType, cdInfo = GetSpellCooldownType(spellID)

                            table.insert(spells, {
                                spellID = spellID,
                                name = spellName,
                                skillLine = skillLineInfo.name,
                                cdType = cdType,
                                cdInfo = cdInfo
                            })
                        end
                    end
                end
            end
        end
    end

    return spells
end

-- 定义 test 函数
local function test()
    -- 收集主动技能
    local spells = CollectActiveSpells()

    -- 分类统计
    local chargeSpells = {}
    local cooldownSpells = {}
    local noCooldownSpells = {}

    for _, spell in ipairs(spells) do
        if spell.cdType == "charges" then
            table.insert(chargeSpells, spell)
        elseif spell.cdType == "cooldown" then
            table.insert(cooldownSpells, spell)
        else
            table.insert(noCooldownSpells, spell)
        end
    end

    -- 输出统计结果
    print("=== 技能统计 ===")
    print("共找到 " .. #spells .. " 个主动技能")
    print("  - 充能技能: " .. #chargeSpells .. " 个")
    print("  - 普通冷却: " .. #cooldownSpells .. " 个")
    print("  - 无冷却: " .. #noCooldownSpells .. " 个")
    print("------------------------")

    -- 显示充能技能
    if #chargeSpells > 0 then
        print("\n【充能技能】")
        for _, spell in ipairs(chargeSpells) do
            print("  - " .. spell.name)
        end
    end

    -- 显示普通冷却技能
    if #cooldownSpells > 0 then
        print("\n【普通冷却技能】")
        for _, spell in ipairs(cooldownSpells) do
            print("  - " .. spell.name)
        end
    end

    -- 显示无冷却技能
    if #noCooldownSpells > 0 then
        print("\n【无冷却技能】")
        for _, spell in ipairs(noCooldownSpells) do
            print("  - " .. spell.name)
        end
    end
end

-- 注册游戏内命令 /test
SLASH_TEST1 = "/test"
SlashCmdList["TEST"] = test
