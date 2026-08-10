-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local IsSpellInRange        = C_Spell.IsSpellInRange

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell

-- 本地变量定义
local insert                = table.insert
local random = math.random

-- 代码部分

--[[
简述：      目标处于近战范围内
分类：      目标状态
分类索引：  7
位置：      7行39列

说明

使用职业配置的近战技能检测目标是否在范围内；范围结果直接写入对应状态。
技能未配置或结果为nil时清除cell，避免使用或保留不可用状态。

]]

local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.TARGET_STATUS
local CELL_CLASSIFICATION_INDEX = 7
local CELL_POSITION_X = 39
local CELL_POSITION_Y = 7

local DEFAULT_VALUE = 127
local FALLBACK_REFRESH_SECONDS = 0.2
local UNIT_TOKEN = "target"

local function InitFrame()
    local eventFrame = CreateFrame("Frame")

    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_VALUE,
    })

    local function updateCell()
        local spellID = addonTable.MELEE_SEPLL
        if spellID == nil then
            cell:clearCell()
            return
        end

        local isInRange = IsSpellInRange(spellID, UNIT_TOKEN)
        if isInRange == nil then
            cell:clearCell()
            return
        end

        cell:setCellBoolean(isInRange)
    end

    updateCell()

    local fallbackElapsed = -random()
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed

        if fallbackElapsed >= FALLBACK_REFRESH_SECONDS then
            fallbackElapsed = 0
            updateCell()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
