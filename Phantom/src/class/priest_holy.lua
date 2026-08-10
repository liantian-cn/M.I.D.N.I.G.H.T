-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置神圣牧师的专精业务数据。

描述：仅在玩家为神圣牧师时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为牧师职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增真言术：韧配置。
]]

-- Code
if UnitClassBase("player") ~= "PRIEST" then return end
if currentSpec ~= 2 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 8122, description = "心灵尖啸" },
    [3] = { spellId = 32375, description = "群体驱散" },
    [4] = { spellId = 527, description = "纯净术" },
    [5] = { spellId = 19236, description = "绝望祷言" },
    [6] = { spellId = 232633, description = "奥术洪流" },
    [7] = { spellId = 33076, description = "愈合祷言", charge = true },
    [8] = { spellId = 2050, description = "圣言术：静", charge = true },
    [9] = { spellId = 88625, description = "圣言术：罚" },
    [10] = { spellId = 200183, description = "神圣化身" },
    [11] = { spellId = 14914, description = "神圣之火" },
    [12] = { spellId = 120517, description = "光晕" },
    [13] = { spellId = 64843, description = "神圣赞美诗" },
}

addonTable.SPEC.ChargeList = {
    [1] = { spellId = 33076, description = "愈合祷言", minValue = 0, maxValue = 2 },
    [2] = { spellId = 2050, description = "圣言术：静", minValue = 0, maxValue = 2 },
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "织光者", spellIDs = { 390993 } },
    [2] = { description = "圣光涌动", spellIDs = { 114255 } },
    [3] = { description = "祈福", spellIDs = { 1262766 } },
}

addonTable.SPEC.PartyBuff = {
    description = "真言术：韧",
    spellIDs = { 21562 },
}

addonTable.SPEC.TargetDebuff = {
}
