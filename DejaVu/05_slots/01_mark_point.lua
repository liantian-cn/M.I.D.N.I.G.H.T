local addonName, addonTable = ...
local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local InitUI = addonTable.Event.Func.InitUI -- 初始化 UI 函数列表

local function InitializeMarkPoint()
    Cell:New(0, 0, COLOR.MARK_POINT.NEAR_BLACK_1)
    Cell:New(1, 1, COLOR.MARK_POINT.NEAR_BLACK_1)
end
table.insert(InitUI, InitializeMarkPoint) -- 第二帧创建面板
