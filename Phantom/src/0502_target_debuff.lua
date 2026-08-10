-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame

-- 插件级变量定义/引用
local CreateAuraSlotContainer = addonTable.CreateAuraSlotContainer
local TARGET_DEBUFF_DURATION = addonTable.CELL_CLASSIFICATION.TARGET_DEBUFF_DURATION
local TARGET_DEBUFF_COUNT = addonTable.CELL_CLASSIFICATION.TARGET_DEBUFF_COUNT

-- 本地变量定义
local insert = table.insert
local random = math.random
local FALLBACK_REFRESH_SECONDS = 2


--[[
简述：      目标Debuff信息
分类：      目标Debuff信息
分类索引：  1-6，由TargetDebuff顺序确定
位置：      从视觉第3行、零基X偏移37开始，向右延伸，共6个宽4高2的固定AuraSlot
区域：      X=37..60, Y=3..4，宽度24，高度2

说明

通过受管AuraSlotContainer显示由玩家施放且位于TargetDebuff的减益效果。
每项description仅用于提高维护时的可读性，不参与Aura过滤。
DurationBar使用TARGET_DEBUFF_DURATION分类，ApplicationBar使用TARGET_DEBUFF_COUNT分类。
注意，仅显示玩家释放的减益效果。
]]

local function InitFrame()
    local container = CreateAuraSlotContainer({
        x = 37,
        y = 3,
        max_slots = 6,
        unitToken = "target",
        filterString = "PLAYER|HARMFUL",
        durationClassification = TARGET_DEBUFF_DURATION,
        applicationClassification = TARGET_DEBUFF_COUNT,
        slots = addonTable.SPEC.TargetDebuff,
    })

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        container:UpdateAllAuras()
    end)

    local fallbackElapsed = -random()
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed

        if fallbackElapsed >= FALLBACK_REFRESH_SECONDS then
            fallbackElapsed = 0
            container:UpdateAllAuras()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
