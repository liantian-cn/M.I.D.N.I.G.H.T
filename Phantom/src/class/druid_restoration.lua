-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local GetSpecialization = GetSpecialization
local UnitClassBase = UnitClassBase

-- Addon-level variable definitions/references

-- Local variables
local currentSpec = GetSpecialization()

-- Code
--[[
摘要：配置恢复德鲁伊的技能、增益、减益、职业小队增益与驱散类型。

描述：
在恢复专精加载时建立本专精使用的技能列表、Aura 白名单与小队距离候选技能，供玩家、小队及目标相关模块读取。
小队距离候选按配置顺序表达优先级，由距离模块选择首个已学习且支持友方距离查询的技能。

主要变量信息：
currentSpec：当前玩家专精编号，用于限制恢复德鲁伊配置的加载。
addonTable.SPEC.PartyBuff：德鲁伊职业小队增益配置；PartyRangeSpellIDs：小队友方距离探测候选技能列表。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求将 PartyBuff 名称规范为野性印记。
2026-07-26：按冻结 plan 补充爪子两个 Aura ID 的事实说明。
2026-07-26：按小队距离技能选择需求配置愈合、回春的有序候选列表。
]]

if UnitClassBase("player") ~= "DRUID" then return end
if currentSpec ~= 4 then return end

addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却", isGCD = true },
    [2] = { spellId = 22812, description = "树皮术" },
    [3] = { spellId = 132469, description = "台风" },
    [4] = { spellId = 99, description = "夺魂咆哮" },
    [5] = { spellId = 29166, description = "激活" },
    [6] = { spellId = 102793, description = "乌索尔旋风" },
    [7] = { spellId = 18562, description = "迅捷治愈", charge = true },
    [8] = { spellId = 48438, description = "野性成长" },
    [9] = { spellId = 391528, description = "万灵之召" },
    [10] = { spellId = 88423, description = "自然之愈" },
    [11] = { spellId = 102342, description = "铁木树皮" },
    [12] = { spellId = 132158, description = "自然迅捷" },
    [13] = { spellId = 1261867, description = "野性之心" },
}

-- Entries without a source charge count bar use the user-approved Phantom 0..8 fallback.
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 18562, description = "迅捷治愈", minValue = 0, maxValue = 2 },
}

addonTable.SPEC.PlayerBuff = {
    -- 玩家自身的 Mark of the Wild Aura ID 为 1126，施加到其他单位时为 432661，白名单需同时配置。
    { description = "爪子", spellIDs = { 1126, 432661 } },
    { description = "萌芽", spellIDs = { 155777 } },
    { description = "回春", spellIDs = { 778, 774 } },
    { description = "愈合", spellIDs = { 8936, 8938 } },
    { description = "野性成长", spellIDs = { 48438 } },
    {
        description = "生命绽放",
        spellIDs = { 33763 },
    },
    {
        description = "清晰预兆",
        spellIDs = { 16870, 16872 },
    },
    {
        description = "树皮术",
        spellIDs = { 22812 },
    },
    {
        description = "自然迅捷",
        spellIDs = { 132158 },
    }

}

addonTable.SPEC.PartyHots = {
    { description = "萌芽", spellIDs = { 155777 } },
    { description = "回春", spellIDs = { 778, 774 } },
    { description = "愈合", spellIDs = { 8936, 8938 } },
    { description = "野性成长", spellIDs = { 48438 } },
    { description = "生命绽放", spellIDs = { 33763 }, },

}

-- 监控德鲁伊职业小队增益。

addonTable.SPEC.PartyBuff = {
    description = "野性印记",
    -- 玩家自身的 Mark of the Wild Aura ID 为 1126，施加到其他单位时为 432661，白名单需同时配置。
    spellIDs = { 1126, 432661 },
}

-- 优先使用愈合，技能不可用时回退到回春判断距离。

addonTable.SPEC.PartyRangeSpellIDs = { 8936, 774 }

addonTable.SPEC.DISPEL_TYPES = {
    Magic = true,
    Curse = true,
    Poison = true,
}


addonTable.SPEC.TargetDebuff = {
    {
        description = "月火术",
        spellIDs = { 164812, 8921 },
    },
    {
        description = "阳炎术",
        spellIDs = { 93402, 164815 },
    }
}
