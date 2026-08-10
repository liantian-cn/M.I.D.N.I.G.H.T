-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置恢复萨满的专精业务数据。

描述：仅在玩家为恢复萨满时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为萨满职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增天怒配置。
]]

-- Code
if UnitClassBase("player") ~= "SHAMAN" then return end
if currentSpec ~= 3 then return end

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
    [13] = { spellId = 51505, description = "熔岩爆裂", charge = true },
    [14] = { spellId = 61295, description = "激流", charge = true },
    [15] = { spellId = 5394, description = "治疗之泉图腾", charge = true },
    [16] = { spellId = 470411, description = "烈焰震击" },
    [17] = { spellId = 77130, description = "净化灵魂" },
    [18] = { spellId = 73685, description = "生命释放" },
    [19] = { spellId = 443454, description = "先祖迅捷" },
    [20] = { spellId = 444995, description = "涌动图腾" },
    [21] = { spellId = 98008, description = "灵魂链接图腾" },
    [22] = { spellId = 114052, description = "升腾" },
    [23] = { spellId = 108280, description = "治疗之潮图腾" },
}

-- Entries without a source charge count bar use the user-approved Phantom 0..8 fallback.
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 51505, description = "熔岩爆裂", minValue = 0, maxValue = 8 },
    [2] = { spellId = 61295, description = "激流", minValue = 0, maxValue = 2 },
    [3] = { spellId = 5394, description = "治疗之泉图腾", minValue = 0, maxValue = 4 },
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "飞旋之土", spellIDs = { 453406 } },
    [2] = { description = "潮汐奔涌", spellIDs = { 53390 } },
    [3] = { description = "风暴涌流图腾", spellIDs = { 1267089 } },
    [4] = { description = "生命释放", spellIDs = { 73685 } },
    [5] = { description = "升腾", spellIDs = { 114052 } },
    [6] = { description = "倾盆大雨", spellIDs = { 462488 } },
}

addonTable.SPEC.PartyBuff = {
    description = "天怒",
    spellIDs = { 462854 },
}

addonTable.SPEC.TargetDebuff = {
}
