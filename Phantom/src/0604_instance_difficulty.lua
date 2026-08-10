-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local GetInstanceInfo       = GetInstanceInfo

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell

-- 本地变量定义
local insert                = table.insert

-- 代码部分

--[[
摘要：      输出当前副本的原始难度 ID
分类：      环境信息
分类索引：  4
位置：      5行42列

描述：
从当前副本信息中读取原始 difficultyID 并写入 Cell。模块初始化时立即读取一次，
在进入世界、难度变化、副本信息更新或副本队伍规模变化时重新读取。

主要变量信息：
- difficultyID：GetInstanceInfo 返回的当前副本原始难度 ID。
- cell：环境信息分类第 4 个 Cell，位于第 5 行第 42 列。

修改记录：
- 2026-07-26：根据本次补充注释需求完善文件说明、Cell 编码与事件流程注释。

]]

-- 分类定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 4
local CELL_POSITION_X = 42
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

    -- R、G 通道标识环境信息分类及索引，B 通道直接编码 difficultyID。
    local function updateCell()
        local _, _, difficultyID = GetInstanceInfo()

        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            difficultyID / 255
        )
    end

    updateCell()

    -- 覆盖登录与副本上下文变化，确保原始难度 ID 及时同步。
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
    eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    eventFrame:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        updateCell()
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
