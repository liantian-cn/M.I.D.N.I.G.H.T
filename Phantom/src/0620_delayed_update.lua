-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local GetTime = GetTime
local SlashCmdList = SlashCmdList

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert
local random = math.random
local tonumber = tonumber

-- 代码部分

--[[
摘要：      输出 /delay 命令触发的手动延迟状态
分类：      环境信息
分类索引：  20
位置：      5行58列

描述：
注册 /delay 命令，将有效数值参数解释为从当前时刻开始的延迟秒数，并记录截止时间。
截止时间仍在未来时 Cell 写入真值，否则写入假值；命令触发后立即刷新，并约每 0.1 秒检查是否到期。

主要变量信息：
- delayTimestamp：手动延迟状态的截止时间。
- delaySeconds：命令参数转换得到的延迟秒数。
- fastTimeElapsed：累计刷新间隔，初始随机错开。
- cell：环境信息分类第 20 个 Cell，位于第 5 行第 58 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、命令、状态判断与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 20
local CELL_POSITION_X = 58
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
    local delayTimestamp = GetTime()

    -- 截止时间晚于当前时间时，Cell 使用布尔编码表示延迟仍然有效。
    local function updateCell()
        cell:setCellBoolean(delayTimestamp > GetTime())
    end

    -- /delay 接受可转换为数字的秒数，更新截止时间后立即同步 Cell。
    _G.SLASH_DELAY1 = "/delay"
    SlashCmdList["DELAY"] = function(msg)
        local delaySeconds = tonumber(msg)
        if delaySeconds then
            delayTimestamp = GetTime() + delaySeconds
            updateCell()
        end
    end

    -- 高频刷新约每 0.1 秒检查一次延迟状态是否到期。
    local fastTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCell()
        end
    end)

    updateCell()
end

insert(addonTable.FrameInitFuncs, InitFrame)
