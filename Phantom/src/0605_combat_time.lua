-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitAffectingCombat = UnitAffectingCombat

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local floor = math.floor
local insert = table.insert
local min = math.min
local random = math.random

-- 代码部分

--[[
摘要：      输出当前战斗持续时间
分类：      环境信息
分类索引：  5
位置：      5行43列

描述：
非战斗状态持续记录最近时间并将 Cell 清零；进入战斗后，以该时间为起点计算整秒战斗时长。
时长最大编码为 255 秒，刷新循环约每 0.1 秒执行一次，并随机错开首次刷新。

主要变量信息：
- nonCombatTimestamp：最近一次非战斗刷新时间，作为下一次战斗计时起点。
- combatTime：向下取整并限制在 0 至 255 的当前战斗秒数。
- fastTimeElapsed：累计刷新间隔，初始随机错开。
- cell：环境信息分类第 5 个 Cell，位于第 5 行第 43 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、Cell 编码与刷新流程注释。
]]

-- 分类与 Cell 位置定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 5
local CELL_POSITION_X = 43
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
    local nonCombatTimestamp = GetTime()

    -- 战斗中写入经过秒数；脱战时重置计时起点并将 B 通道清零。
    local function updateCell()
        if UnitAffectingCombat("player") then
            local combatTime = min(255, floor(GetTime() - nonCombatTimestamp))
            cell:setCellRGBA(
                CELL_CLASSIFICATION / 255,
                CELL_CLASSIFICATION_INDEX / 255,
                combatTime / 255
            )
        else
            nonCombatTimestamp = GetTime()
            cell:setCellRGBA(CELL_CLASSIFICATION / 255, CELL_CLASSIFICATION_INDEX / 255, 0)
        end
    end

    -- 高频刷新约每 0.1 秒推进一次，保留余量以减小帧间隔波动造成的漂移。
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
