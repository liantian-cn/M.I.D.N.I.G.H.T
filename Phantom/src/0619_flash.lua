-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert
local random = math.random

-- 代码部分

--[[
摘要：      输出持续交替的闪烁解析辅助状态
分类：      环境信息
分类索引：  19
位置：      5行57列

描述：
模块以布尔值初始化闪烁状态，约每 0.1 秒将当前状态写入 Cell 后翻转，形成真假交替信号。
首次刷新通过随机负偏移错开，避免多个高频模块在同一帧集中更新。

主要变量信息：
- flashValue：下一次写入 Cell 的布尔值，每次写入后翻转。
- fastTimeElapsed：累计刷新间隔，初始随机错开。
- cell：环境信息分类第 19 个 Cell，位于第 5 行第 57 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、状态翻转与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 19
local CELL_POSITION_X = 57
local CELL_POSITION_Y = 5
local DEFAULT_VALUE = 0

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_VALUE,
    })
    local flashValue = true

    -- 先写入当前布尔状态，再为下一次刷新翻转状态。
    local function updateCell()
        cell:setCellBoolean(flashValue)
        flashValue = not flashValue
    end

    -- 高频刷新约每 0.1 秒推进一次，并保留未消费的累计时间。
    local fastTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCell()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
