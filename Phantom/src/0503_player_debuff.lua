-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local Debuff = AuraUtil.AuraUpdateChangedType.Debuff
local UnitFrameDebuff = AuraContainerSortMethod.UnitFrameDebuff
local CreateColorCurve = C_CurveUtil.CreateColorCurve

-- 插件级变量定义/引用
local CreateAuraGroupContainer = addonTable.CreateAuraGroupContainer
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION

-- 本地变量定义
local insert = table.insert
local random = math.random
local FALLBACK_REFRESH_SECONDS = 2

-- 代码部分

--[[
Summary:              Player debuff information
Classification:       Player debuff duration and application
Classification index: Dynamic, with up to five AuraGroup entries
Position:             Starts at x = 1, y = 5 and extends right with up to five 6x2 AuraGroup entries (X=1..30, Y=5..6)

Description

Displays harmful auras on the player that are accepted by the Aura processing policy.
The Dispel category is intentionally excluded.
]]

local COLOR = addonTable.COLOR

local auraColorCurve = CreateColorCurve()
auraColorCurve:AddPoint(0, COLOR.DEBUFF_ON_FRIENDLY)
auraColorCurve:AddPoint(1, COLOR.MAGIC)
auraColorCurve:AddPoint(2, COLOR.CURSE)
auraColorCurve:AddPoint(3, COLOR.DISEASE)
auraColorCurve:AddPoint(4, COLOR.POISON)
auraColorCurve:AddPoint(9, COLOR.ENRAGE)
auraColorCurve:AddPoint(11, COLOR.BLEED)


local function InitFrame()
    local container = CreateAuraGroupContainer({
        x = 1,
        y = 5,
        unitToken = "player",
        filterString = "HARMFUL",
        durationClassification = CELL_CLASSIFICATION.PLAYER_DEBUFF_DURATION,
        applicationClassification = CELL_CLASSIFICATION.PLAYER_DEBUFF_COUNT,
        maxFrameCount = 5,
        processAuraOptions = {
            ignoreBuffs = true,
            ignoreDispelDebuffs = true,
        },
        candidateFilters = {
            processedAuraType = Debuff,
        },
        sortMethod = UnitFrameDebuff,
        auraColorCurve = auraColorCurve,
    })

    local fallbackFrame = CreateFrame("Frame")
    local fallbackElapsed = -random()
    fallbackFrame:SetScript("OnUpdate", function(self, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed

        if fallbackElapsed >= FALLBACK_REFRESH_SECONDS then
            fallbackElapsed = 0
            container:UpdateAllAuras()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
