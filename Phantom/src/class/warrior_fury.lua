-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置狂怒战士的专精业务数据。

描述：仅在玩家为狂怒战士时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为战士职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增战斗怒吼配置。
]]

-- Code
if UnitClassBase("player") ~= "WARRIOR" then return end
if currentSpec ~= 2 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 202168, description = "胜利在望" },
    [3] = { spellId = 376079, description = "勇士之矛" },
    [4] = { spellId = 6544, description = "英勇飞跃" },
    [5] = { spellId = 97462, description = "集结呐喊" },
    [6] = { spellId = 46968, description = "震荡波" },
    [7] = { spellId = 107570, description = "风暴之锤" },
    [8] = { spellId = 384110, description = "破裂投掷" },
    [9] = { spellId = 64382, description = "碎裂投掷" },
    [10] = { spellId = 5246, description = "破胆怒吼" },
    [11] = { spellId = 1719, description = "鲁莽" },
    [12] = { spellId = 6552, description = "拳击" },
}

addonTable.SPEC.ChargeList = {
}

-- These tables are intentionally empty because Fuyutsui provides no finite static player-buff or player-origin target-debuff ID lists to port.
addonTable.SPEC.PlayerBuff = {
}

addonTable.SPEC.PartyBuff = {
    description = "战斗怒吼",
    spellIDs = { 6673 },
}

addonTable.SPEC.TargetDebuff = {
}
