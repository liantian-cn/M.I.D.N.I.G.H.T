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
摘要：      输出插件当前启停状态
分类：      环境信息
分类索引：  22
位置：      5行60列

描述：
读取插件级 ENABLE 标志，仅当该值严格等于 true 时向 Cell 写入真值，否则写入假值。
模块约每 0.1 秒轮询一次当前状态，并通过随机负偏移错开首次刷新。

主要变量信息：
- addonTable.ENABLE：插件级启停标志。
- fastTimeElapsed：累计刷新间隔，初始随机错开。
- cell：环境信息分类第 22 个 Cell，位于第 5 行第 60 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、状态判断与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 22
local CELL_POSITION_X = 60
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

    -- Cell 使用布尔编码反映插件级 ENABLE 是否严格开启。
    local function updateCell()
        cell:setCellBoolean(addonTable.ENABLE == true)
    end

    -- 高频刷新约每 0.1 秒重新读取启停标志。
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
