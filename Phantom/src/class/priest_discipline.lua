-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

--[[
摘要：配置戒律牧师的专精业务数据。

描述：仅在玩家为戒律牧师时加载技能、Aura 与职业小队增益配置，供对应业务模块读取。

主要变量信息：currentSpec 为当前玩家专精编号；addonTable.SPEC.PartyBuff 为牧师职业小队增益配置。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求新增真言术：韧配置。
]]

-- Code
if UnitClassBase("player") ~= "PRIEST" then return end
if currentSpec ~= 1 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 8122, description = "心灵尖啸" },
    [3] = { spellId = 32375, description = "群体驱散" },
    [4] = { spellId = 527, description = "纯净术" },
    [5] = { spellId = 19236, description = "绝望祷言" },
    [6] = { spellId = 232633, description = "奥术洪流" },
    [7] = { spellId = 47540, description = "苦修", charge = true },
    [8] = { spellId = 194509, description = "真言术：耀", charge = true },
    [9] = { spellId = 17, description = "真言术：盾" },
    [10] = { spellId = 62618, description = "真言术：障" },
    [11] = { spellId = 421453, description = "终极苦修" },
    [12] = { spellId = 472433, description = "福音" },
    [13] = { spellId = 8092, description = "心灵震爆" },
    [14] = { spellId = 32379, description = "暗言术：灭" },
    [15] = { spellId = 34433, description = "暗影魔" },
    [16] = { spellId = 1235211, description = "暗影分流" },
    [17] = { spellId = 586, description = "渐隐术" },
}

addonTable.SPEC.ChargeList = {
    [1] = { spellId = 47540, description = "苦修", minValue = 0, maxValue = 2 },
    [2] = { spellId = 194509, description = "真言术：耀", minValue = 0, maxValue = 2 },
}

addonTable.SPEC.PlayerBuff = {
    [1] = { description = "虚空之盾", spellIDs = { 1253591 } },
    [2] = { description = "圣光涌动", spellIDs = { 114255 } },
    [3] = { description = "暗影愈合", spellIDs = { 1252217 } },
    [4] = { description = "福音", spellIDs = { 472433 } },
    [5] = { description = "祸福相依", spellIDs = { 390787 } },
}

addonTable.SPEC.PartyBuff = {
    description = "真言术：韧",
    spellIDs = { 21562 },
}

addonTable.SPEC.TargetDebuff = {
}
