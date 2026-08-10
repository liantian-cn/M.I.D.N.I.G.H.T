-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local After = C_Timer.After
local GetTime = GetTime
local max = math.max
local min = math.min
local print = print
local tostring = tostring
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenHeight = GetScreenHeight

-- 插件级变量定义/引用

--[[
摘要：定义插件默认业务配置、公共日志函数与基础运行参数。

描述：
本文件先建立可由职业配置覆盖的技能、Aura、驱散和小队距离默认值，再提供日志、界面缩放、
爆发状态等公共能力，最后设置插件运行所需的客户端参数。小队距离候选技能按声明顺序表达优先级，
空表表示当前专精无需输出小队距离状态；空的小队职业增益对象由 providerClass 专精配置按需覆盖。

主要变量信息：
addonTable.SPEC：当前专精共享配置；PartyBuff 保存单个小队职业增益配置；PartyRangeSpellIDs 保存按优先级排列的友方距离探测技能 ID。

修改记录：
2026-07-26：按小队职业增益 providerClass 配置需求将默认 PartyBuff 改为空对象。
2026-07-26：按小队距离技能选择需求将默认距离配置改为空候选列表。
]]

addonTable.DEBUG = true             -- 是否开启调试模式
addonTable.VERSION = "12.1.0.68209" -- 插件版本
addonTable.SPEC = {}
addonTable.SPEC.SpellList = {
    [1] = { spellId = 61304, description = "公共冷却" },
}

-- 玩家充能监控列表，按下面的格式设置，应该在class配置中覆盖此配置，以下两个仅是例子
addonTable.SPEC.ChargeList = {
    [1] = { spellId = 185123, description = "投掷利刃", minValue = 0, maxValue = 2 },
}

-- 玩家buff监控列表，按下面的格式设置，应该在class配置中覆盖此配置，以下两个仅是例子
addonTable.SPEC.PlayerBuff = {
    { description = "爪子", spellIDs = { 1126, 1128 } }, -- 可以多个技能id放置在一个槽位
    { description = "萌芽", spellIDs = { 155777 } }, -- 可以单个技能id独享一个槽位
}

-- 目标debuff监控列表，按下面的格式设置，应该在class配置中覆盖此配置，以下两个仅是例子
addonTable.SPEC.TargetDebuff = {
    { description = "爪子", spellIDs = { 1126, 1128 } }, -- 可以多个技能id放置在一个槽位
    { description = "萌芽", spellIDs = { 155777 } }, -- 可以单个技能id独享一个槽位
}


-- 用于检测远程还是近战的施法技能。
addonTable.RANGED_SEPLL = nil
addonTable.MELEE_SEPLL = nil

-- 玩家吸收量状态条阈值
addonTable.PLAYER_DAMAGE_ABSORB_THRESHOLD = 10000
addonTable.PLAYER_HEAL_ABSORB_THRESHOLD = 10000

-- 可驱散类型过滤器
addonTable.SPEC.DISPEL_TYPES = {
    Magic = true,
    -- Curse = true,
    -- Poison = true,
}


-- 小队/团队框架显示的hots，最多5个，需在职业配置中覆盖这里仅作例子。
addonTable.SPEC.PartyHots = {
    -- { description = "萌芽", spellIDs = { 155777 } },
    { description = "回春", spellIDs = { 778, 774 } },
    -- { description = "愈合", spellIDs = { 8936, 8938 } },
    -- { description = "野性成长", spellIDs = { 48438 } },
    -- { description = "生命绽放", spellIDs = { 33763 }, },

}

-- 小队/团队框架中，增益槽判断的buff，注意，仅有一个增益槽，任意增益存在都会亮。
addonTable.SPEC.PartyBuff = {
    description = "",
    spellIDs = {},
}


-- 判断小队成员是否在距离内的候选技能，空表时不判断。

addonTable.SPEC.PartyRangeSpellIDs = {}

-- 代码部分

addonTable.logging = function(msg)
    print("|cFFFFBB66[" .. addonName .. "]|r" .. tostring(msg))
end


addonTable.debug = function(msg)
    if addonTable.DEBUG then
        print("|cFFFFBB66[" .. addonName .. "]|r" .. tostring(msg))
    end
end

addonTable.GetUIScaleFactor = function(pixelValue)
    local physicalHeight = select(2, GetPhysicalScreenSize())
    local UI_scale = UIParent:GetScale()
    return pixelValue * 768 / physicalHeight / UI_scale
end


-- 全局状态、爆发和启动
addonTable.ENABLE = true -- 是否开启插件
addonTable.BurstTime = GetTime() + 60
addonTable.InBurst = function()
    return addonTable.BurstTime > GetTime()
end
addonTable.BurstRemaining = function()
    return min(60.0, max(0, addonTable.BurstTime - GetTime()))
end


SetCVar("useUiScale", 0)
SetCVar("secretChallengeModeRestrictionsForced", 1)
SetCVar("secretCombatRestrictionsForced", 1)
SetCVar("secretEncounterRestrictionsForced", 1)
SetCVar("secretMapRestrictionsForced", 1)
SetCVar("secretPvPMatchRestrictionsForced", 1)
SetCVar("secretAuraDataRestrictionsForced", 1)
SetCVar("scriptErrors", 1);
SetCVar("doNotFlashLowHealthWarning", 1);
SetCVar("lossOfControl", 0);
SetCVar("cameraIndirectVisibility", 1);
SetCVar("cameraIndirectOffset", 10);
SetCVar("targetNearestDistance", 5)
SetCVar("cameraDistanceMaxZoomFactor", 2.6)
SetCVar("CameraReduceUnexpectedMovement", 1)
SetCVar("synchronizeSettings", 1)
SetCVar("synchronizeConfig", 1)
SetCVar("synchronizeBindings", 1)
SetCVar("synchronizeMacros", 1)
SetCVar("LowLatencyMode", 0)      --低延迟模式 0:关闭 1:内置 2:NVIDIA Reflex 3:NVIDIA Reflex + Boost 4:Intel XeLL
SetCVar("ffxAntiAliasingMode", 0) --基于图像的技术 0:无 1:FXAA低 2:FXAA高 3:CMAA 4:CMAA2
SetCVar("MSAAQuality", 0)         --多重采样技术 0:无 1:色彩 2x / 景深 2x 2:色彩 4x / 景深 4x 3:色彩 8x / 景深 8x
SetCVar("Contrast", 50)           --对比度 minValue, maxValue, step = 0, 100, 1
SetCVar("Brightness", 50)         --亮度 minValue, maxValue, step = 0, 100, 1
SetCVar("Gamma", 1)               --伽马值 minValue, maxValue, step = .3, 2.8, .1
