-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置神圣圣骑士的专精业务数据。

描述：仅在玩家为神圣圣骑士时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为圣骑士职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增虔诚光环配置。
]]

-- Code
if UnitClassBase("player") ~= "PALADIN" then return end
if currentSpec ~= 1 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 115750, description = "盲目之光" },
    [3] = { spellId = 853, description = "制裁之锤" },
    [4] = { spellId = 642, description = "圣盾术" },
    [5] = { spellId = 6940, description = "牺牲祝福" },
    [6] = { spellId = 1044, description = "自由祝福" },
    [7] = { spellId = 1022, description = "保护祝福" },
    [8] = { spellId = 633, description = "圣疗术" },
    [9] = { spellId = 20473, description = "神圣震击", charge = true },
    [10] = { spellId = 4987, description = "清洁术" },
    [11] = { spellId = 275773, description = "审判" },
    [12] = { spellId = 375576, description = "圣洁鸣钟" },
    [13] = { spellId = 114165, description = "神圣棱镜" },
    [14] = { spellId = 31821, description = "光环掌握" },
    [15] = { spellId = 200025, description = "美德道标" },
}

-- Entries without a source charge count bar use the user-approved Phantom 0..8 fallback.
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 20473, description = "神圣震击", minValue = 0, maxValue = 8 },
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "神圣意志", spellIDs = { 223819, 408458 } },
    [2] = { description = "圣光灌注", spellIDs = { 54149 } },
    [3] = { description = "神性之手", spellIDs = { 414273 } },
}

addonTable.SPEC.PartyBuff = {
    description = "虔诚光环",
    spellIDs = { 465 },
}

addonTable.SPEC.TargetDebuff = {
}
