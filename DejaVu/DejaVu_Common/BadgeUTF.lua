local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local byte = string.byte
local After = C_Timer.After
local random = math.random

-- WoW 官方 API
local CreateFrame = CreateFrame

local DejaVu = _G["DejaVu"]
local BadgeTitleTable = DejaVu.BadgeTitleTable
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell


local function char_to_rgb(str)
    local b1, b2, b3 = byte(str, 1, 3)
    return b1 or 0, b2 or 0, b3 or 0
end

After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local eventFrame = CreateFrame("Frame")
    local IconCell = BadgeCell:New(64, 26)
    local UTFCells = {
        [1] = Cell:New(66, 26),
        [2] = Cell:New(67, 26),
        [3] = Cell:New(68, 26),
        [4] = Cell:New(69, 26),
        [5] = Cell:New(70, 26),
        [6] = Cell:New(71, 26),
        [7] = Cell:New(72, 26),
        [8] = Cell:New(73, 26),
        [9] = Cell:New(74, 26),
        [10] = Cell:New(75, 26),
        [11] = Cell:New(76, 26),
        [12] = Cell:New(77, 26),
        [13] = Cell:New(78, 26),
        [14] = Cell:New(79, 26),
        [15] = Cell:New(80, 26),
        [16] = Cell:New(81, 26),
    }











    local lowTimeElapsed = -random()

    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
        end
    end)
end)
