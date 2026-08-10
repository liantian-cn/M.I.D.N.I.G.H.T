-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local UnitInParty           = UnitInParty
local UnitInRaid            = UnitInRaid

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell

-- 本地变量定义
local insert                = table.insert

-- 代码部分

--[[
摘要：      输出当前队伍类型的兼容编码
分类：      环境信息
分类索引：  2
位置：      5行40列

描述：
按团队、队伍、单人三种状态生成队伍类型编码。团队状态使用玩家在团队中的索引，
普通队伍固定写入 46，单人状态写入 0；初始化、队伍名单变化和进入世界时刷新。

主要变量信息：
- raidIndex：玩家在当前团队中的索引；不在团队时为空。
- value：最终写入 Cell B 通道的队伍类型编码。
- cell：环境信息分类第 2 个 Cell，位于第 5 行第 40 列。

修改记录：
- 2026-07-26：根据本次补充注释需求完善文件说明、编码映射与事件流程注释。

]]

-- 分类定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 2
local CELL_POSITION_X = 40
local CELL_POSITION_Y = 5

-- 默认值：cell初始化时的B通道值（0-255）
local DEFAULT_VALUE = 0

local function InitFrame()
    local eventFrame = CreateFrame("Frame") -- 每个文件独立的事件框架

    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_VALUE,
    })

    -- 编码优先判断团队，其次判断普通队伍，最后回落到单人状态。
    local function updateCell()
        local raidIndex = UnitInRaid("player")
        local value

        if raidIndex then
            value = raidIndex
        elseif UnitInParty("player") then
            value = 46
        else
            value = 0
        end

        -- R、G 通道标识环境信息分类及索引，B 通道保存队伍类型编码。
        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            value / 255
        )
    end

    updateCell()

    -- 队伍构成变化或进入世界后重新判定队伍类型。
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        updateCell()
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
