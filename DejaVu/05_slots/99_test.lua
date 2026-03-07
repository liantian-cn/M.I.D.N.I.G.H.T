local addonName, addonTable = ... -- luacheck: ignore addonName
local COLOR = addonTable.COLOR
local MegaCell = addonTable.MegaCell
local BadgeCell = addonTable.BadgeCell
local InitUI = addonTable.Event.Func.InitUI -- 初始化 UI 函数列表


local function TestSlot()
    local badgeCell = BadgeCell:New(10, 10)
    badgeCell:setCell(136243, COLOR.WHITE)
    local megaCell = MegaCell:New(12, 12)
    megaCell:setCell(136243)
end
table.insert(InitUI, TestSlot) -- 初始化时创建测试槽位
