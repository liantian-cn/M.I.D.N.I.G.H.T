-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置元素萨满的专精业务数据。

描述：仅在玩家为元素萨满时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为萨满职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增天怒配置。
]]

-- Code
if UnitClassBase("player") ~= "SHAMAN" then return end
if currentSpec ~= 1 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 57994, description = "风剪" },
    [3] = { spellId = 198103, description = "土元素" },
    [4] = { spellId = 192058, description = "电能图腾" },
    [5] = { spellId = 378081, description = "自然迅捷" },
    [6] = { spellId = 108287, description = "图腾投射" },
    [7] = { spellId = 51514, description = "妖术" },
    [8] = { spellId = 378773, description = "强化净化术" },
    [9] = { spellId = 8143, description = "战栗图腾" },
    [10] = { spellId = 383013, description = "清毒图腾" },
    [11] = { spellId = 192063, description = "阵风" },
    [12] = { spellId = 58875, description = "幽魂步" },
}

addonTable.SPEC.ChargeList = {
}

-- These tables are intentionally empty because Fuyutsui provides no finite static player-buff or player-origin target-debuff ID lists to port.
addonTable.SPEC.PlayerBuff = {
}

addonTable.SPEC.PartyBuff = {
    description = "天怒",
    spellIDs = { 462854 },
}

addonTable.SPEC.TargetDebuff = {
}
