-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置守护德鲁伊的专精业务数据。

描述：仅在玩家为守护德鲁伊时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为德鲁伊职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增野性印记配置。
]]

-- Code
if UnitClassBase("player") ~= "DRUID" then return end
if currentSpec ~= 3 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 22812, description = "树皮术" },
    [3] = { spellId = 132469, description = "台风" },
    [4] = { spellId = 99, description = "夺魂咆哮" },
    [5] = { spellId = 29166, description = "激活" },
    [6] = { spellId = 102793, description = "乌索尔旋风" },
    [7] = { spellId = 22842, description = "狂暴回复", charge = true },
    [8] = { spellId = 61336, description = "生存本能" },
    [9] = { spellId = 102558, description = "化身：乌索克的守护者" },
    [10] = { spellId = 1261867, description = "野性之心" },
    [11] = { spellId = 1253799, description = "碎甲咆哮" },
    [12] = { spellId = 1252871, description = "赤红之月" },
    [13] = { spellId = 6807, description = "重殴" },
    [14] = { spellId = 77758, description = "痛击" },
}

-- Entries without a source charge count bar use the user-approved Phantom 0..8 fallback.
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 22842, description = "狂暴回复", minValue = 0, maxValue = 8 },
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "塞纳留斯的梦境", spellIDs = { 372152 } },
    [2] = { description = "铁鬃", spellIDs = { 192081 } },
    [3] = { description = "狂暴回复", spellIDs = { 22842 } },
    [4] = { description = "星河守护者", spellIDs = { 213708 } },
    [5] = { description = "淤血", spellIDs = { 93622 } },
}

addonTable.SPEC.PartyBuff = {
    description = "野性印记",
    spellIDs = { 1126, 432661 },
}

addonTable.SPEC.TargetDebuff = {
}
