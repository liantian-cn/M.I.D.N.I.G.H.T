-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
-- 无

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert

-- 代码部分
--[[
摘要：在矩阵左上角和右下角创建两组固定的 2x2 对角标记。

描述：
矩阵框架初始化后，分别在 X=1..2、Y=1..2 和 X=59..60、Y=16..17 创建八个 Cell。
每组主对角线使用深色近黑 RGB (15, 25, 20)，副对角线使用浅色近黑 RGB (25, 15, 20)。
构造参数与最终显式染色使用相同 RGB，使初始颜色、显示颜色和 clearCell() 恢复颜色保持一致。

主要变量信息：
DEEP_* 和 LIGHT_* 分别保存两种标记颜色的 8 位 RGB 分量。

修改记录：
2026-07-29：根据角落标记需求新增两组静态 2x2 矩阵边界标记。
]]

local DEEP_RED = 15
local DEEP_GREEN = 25
local DEEP_BLUE = 20
local LIGHT_RED = 25
local LIGHT_GREEN = 15
local LIGHT_BLUE = 20

local function CreateMarkerCell(x, y, red, green, blue)
    local cell = Cell:New({
        x = x,
        y = y,
        classification = red,
        index = green,
        default_value = blue,
    })
    cell:setCellRGBA(red / 255, green / 255, blue / 255)
end

local function InitFrame()
    -- 左上角和右下角采用相同的主对角深色、副对角浅色方向标记。
    CreateMarkerCell(1, 1, DEEP_RED, DEEP_GREEN, DEEP_BLUE)
    CreateMarkerCell(2, 2, DEEP_RED, DEEP_GREEN, DEEP_BLUE)
    CreateMarkerCell(1, 2, LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE)
    CreateMarkerCell(2, 1, LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE)

    CreateMarkerCell(59, 16, DEEP_RED, DEEP_GREEN, DEEP_BLUE)
    CreateMarkerCell(60, 17, DEEP_RED, DEEP_GREEN, DEEP_BLUE)
    CreateMarkerCell(59, 17, LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE)
    CreateMarkerCell(60, 16, LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE)
end

insert(addonTable.FrameInitFuncs, InitFrame)
