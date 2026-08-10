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
简述：      焦点处于远程范围内
分类：      焦点目标
分类索引：  6
位置：      7行52列

说明

使用职业配置的远程技能检测焦点是否在范围内；范围结果直接写入对应状态。
技能未配置或结果为nil时清除cell，避免使用或保留不可用状态。

]]

local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.FOCUS_TARGET
local CELL_CLASSIFICATION_INDEX = 6
local CELL_POSITION_X = 52
local CELL_POSITION_Y = 7

local DEFAULT_VALUE = 127
local FALLBACK_REFRESH_SECONDS = 0.2
local UNIT_TOKEN = "focus"

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
        local spellID = addonTable.RANGED_SEPLL
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
