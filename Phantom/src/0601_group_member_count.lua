-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local GetNumGroupMembers    = GetNumGroupMembers

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell

-- 本地变量定义
local insert                = table.insert

-- 代码部分

--[[
摘要：      输出当前适用队伍或团队的成员总数
分类：      环境信息
分类索引：  1
位置：      5行39列

描述：
读取当前队伍或团队的成员总数，人数包括玩家自己。模块初始化时立即写入一次，
并在队伍名单变化或玩家进入世界时重新读取人数。

主要变量信息：
- cell：环境信息分类第 1 个 Cell，位于第 5 行第 39 列。

修改记录：
- 2026-07-26：根据本次补充注释需求完善文件说明与更新流程注释。

]]

-- 分类定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 1
local CELL_POSITION_X = 39
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

    -- Cell 的 R、G 通道标识环境信息分类及索引，B 通道直接编码成员总数。
    local function updateCell()
        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            GetNumGroupMembers() / 255
        )
    end

    updateCell()

    -- 队伍构成变化或进入世界后刷新，确保切换队伍与场景时人数保持同步。
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        updateCell()
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
