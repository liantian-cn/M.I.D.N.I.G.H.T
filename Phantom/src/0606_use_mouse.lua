-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local IsMouseButtonDown = IsMouseButtonDown
local IsMouselooking = IsMouselooking

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert
local random = math.random

-- 代码部分

--[[
摘要：      输出玩家当前是否正在使用鼠标
分类：      环境信息
分类索引：  6
位置：      5行44列

描述：
检测鼠标视角模式以及左键、右键、中键、Button4 和 Button5 的按下状态，任一条件成立即写入真值。
转向开始和停止事件会立即刷新，同时约每 0.1 秒轮询一次，以覆盖没有对应事件的鼠标按键变化。

主要变量信息：
- useMouse：鼠标视角模式或任一受监测按键按下时得到的状态值。
- fastTimeElapsed：累计轮询间隔，初始随机错开。
- cell：环境信息分类第 6 个 Cell，位于第 5 行第 44 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、事件分发与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 6
local CELL_POSITION_X = 44
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

    -- Cell 使用布尔编码表示是否处于任一受监测的鼠标操作状态。
    local function updateCell()
        local useMouse = IsMouselooking()
            or IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
            or IsMouseButtonDown("Button4")
            or IsMouseButtonDown("Button5")
        cell:setCellBoolean(useMouse)
    end

    -- 转向事件通过同名方法路由，发生时立即重新检测鼠标状态。
    eventFrame:RegisterEvent("PLAYER_STARTED_TURNING")
    function eventFrame:PLAYER_STARTED_TURNING()
        updateCell()
    end

    eventFrame:RegisterEvent("PLAYER_STOPPED_TURNING")
    function eventFrame:PLAYER_STOPPED_TURNING()
        updateCell()
    end

    -- 高频轮询约每 0.1 秒补充刷新其他鼠标按键状态。
    local fastTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCell()
        end
    end)

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)

    updateCell()
end

insert(addonTable.FrameInitFuncs, InitFrame)
