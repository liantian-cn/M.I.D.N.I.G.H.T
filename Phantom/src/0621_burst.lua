-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local GetTime = GetTime
local SlashCmdList = SlashCmdList

-- 插件级变量定义/引用
local BurstRemaining = addonTable.BurstRemaining
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert
local max = math.max
local min = math.min
local random = math.random
local tonumber = tonumber

-- 代码部分

--[[
摘要：      输出当前爆发状态的剩余时间
分类：      环境信息
分类索引：  21
位置：      5行59列

描述：
注册 /burst 命令，将有效数值参数解释为爆发持续秒数，并更新插件级爆发截止时间。
刷新时读取爆发剩余时间，将其限制在 0 至 51 秒，再按 51 秒满量程编码到 Cell B 通道；
模块初始化时立即写入一次，之后约每 0.5 秒刷新。

主要变量信息：
- BurstRemaining：返回当前爆发剩余时间的插件级函数。
- addonTable.BurstTime：/burst 命令更新的爆发截止时间。
- remaining：限制在 0 至 51 秒的当前剩余时间。
- lowTimeElapsed：累计刷新间隔，初始随机错开。
- cell：环境信息分类第 21 个 Cell，位于第 5 行第 59 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、命令、Cell 编码与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 21
local CELL_POSITION_X = 59
local CELL_POSITION_Y = 5
local DEFAULT_VALUE = 0

-- /burst 接受可转换为数字的秒数，并据此更新爆发截止时间。
_G.SLASH_BURST1 = "/burst"
SlashCmdList["BURST"] = function(msg)
    local delaySeconds = tonumber(msg)
    if delaySeconds then
        addonTable.BurstTime = GetTime() + delaySeconds
    end
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_VALUE,
    })

    -- 剩余时间限制为 0 至 51 秒，并映射到 B 通道的完整 0 至 1 范围。
    local function updateCell()
        local remaining = min(51, max(0, BurstRemaining()))
        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            remaining / 51
        )
    end

    -- 低频刷新约每 0.5 秒推进一次，并保留未消费的累计时间。
    local lowTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
            updateCell()
        end
    end)

    updateCell()
end

insert(addonTable.FrameInitFuncs, InitFrame)
