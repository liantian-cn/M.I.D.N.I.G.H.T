-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置奥术法师的专精业务数据。

描述：仅在玩家为奥术法师时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为法师职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增奥术智慧配置。
]]

-- Code
if UnitClassBase("player") ~= "MAGE" then return end
if currentSpec ~= 1 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
}

addonTable.SPEC.ChargeList = {
}

-- These tables are intentionally empty because Fuyutsui provides no finite static player-buff or player-origin target-debuff ID lists to port.
addonTable.SPEC.PlayerBuff = {
}

addonTable.SPEC.PartyBuff = {
    description = "奥术智慧",
    spellIDs = { 1459, 432778 },
}

addonTable.SPEC.TargetDebuff = {
}
