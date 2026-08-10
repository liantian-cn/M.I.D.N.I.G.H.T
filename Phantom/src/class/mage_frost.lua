-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置冰霜法师的专精业务数据。

描述：仅在玩家为冰霜法师时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为法师职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增奥术智慧配置。
]]

-- Code
if UnitClassBase("player") ~= "MAGE" then return end
if currentSpec ~= 3 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
}

addonTable.SPEC.ChargeList = {
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "热能真空", spellIDs = { 1247730 } },
    [2] = { description = "冰冷智慧", spellIDs = { 190446 } },
    [3] = { description = "冰冻之雨", spellIDs = { 270232 } },
    [4] = { description = "寒冰指", spellIDs = { 44544 } },
}

addonTable.SPEC.PartyBuff = {
    description = "奥术智慧",
    spellIDs = { 1459, 432778 },
}

addonTable.SPEC.TargetDebuff = {
}
