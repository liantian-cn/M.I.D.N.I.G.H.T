-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置增辉唤魔师的专精业务数据。

描述：仅在玩家为增辉唤魔师时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为唤魔师职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增青铜祝福配置。
]]

-- Code
if UnitClassBase("player") ~= "EVOKER" then return end
if currentSpec ~= 3 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 365585, description = "净除" },
    [3] = { spellId = 363916, description = "黑曜鳞片", charge = true },
    [4] = { spellId = 358385, description = "山崩" },
    [5] = { spellId = 360995, description = "青翠之拥" },
    [6] = { spellId = 357210, description = "深呼吸" },
    [7] = { spellId = 374227, description = "微风" },
    [8] = { spellId = 358267, description = "悬空", charge = true },
    [9] = { spellId = 368970, description = "扫尾" },
    [10] = { spellId = 370553, description = "扭转天平" },
    [11] = { spellId = 370665, description = "营救" },
    [12] = { spellId = 374968, description = "时间螺旋" },
    [13] = { spellId = 406732, description = "空间悖论" },
    [14] = { spellId = 357208, description = "火焰吐息" },
    [15] = { spellId = 396286, description = "地壳激变" },
    [16] = { spellId = 409311, description = "先知先觉", charge = true },
    [17] = { spellId = 395152, description = "黑檀之力" },
    [18] = { spellId = 442204, description = "亘古吐息" },
}

-- Entries without a source charge count bar use the user-approved Phantom 0..8 fallback.
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 363916, description = "黑曜鳞片", minValue = 0, maxValue = 8 },
    [2] = { spellId = 358267, description = "悬空", minValue = 0, maxValue = 8 },
    [3] = { spellId = 409311, description = "先知先觉", minValue = 0, maxValue = 8 },
}

-- These tables are intentionally empty because Fuyutsui provides no finite static player-buff or player-origin target-debuff ID lists to port.
addonTable.SPEC.PlayerBuff = {
}

addonTable.SPEC.PartyBuff = {
    description = "青铜祝福",
    spellIDs = { 381748 },
}

addonTable.SPEC.TargetDebuff = {
}
