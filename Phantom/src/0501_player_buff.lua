-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame

-- 插件级变量定义/引用
local CreateAuraSlotContainer = addonTable.CreateAuraSlotContainer
local PLAYER_BUFF_DURATION = addonTable.CELL_CLASSIFICATION.PLAYER_BUFF_DURATION
local PLAYER_BUFF_COUNT = addonTable.CELL_CLASSIFICATION.PLAYER_BUFF_COUNT

-- 本地变量定义
local insert = table.insert
local random = math.random
local FALLBACK_REFRESH_SECONDS = 2


--[[
简述：      玩家Buff信息
分类：      玩家Buff信息
分类索引：  1-9，由PlayerBuff顺序确定
位置：      从视觉第3行、零基X偏移1开始，向右延伸，共9个宽4高2的固定AuraSlot
区域：      X=1..36, Y=3..4，宽度36，高度2

说明

通过受管AuraSlotContainer显示由玩家施放且位于PlayerBuff中的增益效果。
每项description仅用于提高维护时的可读性，不参与Aura过滤。
DurationBar使用PLAYER_BUFF_DURATION分类，ApplicationBar使用PLAYER_BUFF_COUNT分类。
]]

local function InitFrame()
    local container = CreateAuraSlotContainer({
        x = 1,
        y = 3,
        max_slots = 9,
        unitToken = "player",
        filterString = "PLAYER|HELPFUL",
        durationClassification = PLAYER_BUFF_DURATION,
        applicationClassification = PLAYER_BUFF_COUNT,
        slots = addonTable.SPEC.PlayerBuff,
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
