--[[
文件定位:
  DejaVu 标记点模块。

状态:
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local insert = table.insert
local random = math.random

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI -- 初始化入口列表
local Cell = addonTable.Cell               -- 基础色块单元

local function CreateMarkSet(x, y, height)
    for i = 1, height do
        Cell:New(x, y - 1 + i, CreateColor(random(), random(), random(), 1))
    end
end

local function InitializeMarkPointCell() -- 初始化标记点槽位
    CreateMarkSet(0, 4, 5)
    CreateMarkSet(61, 4, 5)
    CreateMarkSet(0, 9, 5)
    CreateMarkSet(21, 9, 5)
    CreateMarkSet(54, 10, 2)
    CreateMarkSet(69, 10, 2)
    CreateMarkSet(69, 12, 2)
    CreateMarkSet(54, 13, 1)
    CreateMarkSet(54, 12, 1)
    CreateMarkSet(0, 14, 5)
    CreateMarkSet(21, 14, 5)
    CreateMarkSet(42, 14, 4)
    CreateMarkSet(0, 19, 9)
    CreateMarkSet(21, 19, 9)
    CreateMarkSet(42, 19, 9)
    CreateMarkSet(63, 19, 9)
    CreateMarkSet(63, 15, 2)
    CreateMarkSet(42, 17, 2)
    CreateMarkSet(0, 26, 2)
    CreateMarkSet(41, 26, 2)
end
insert(InitUI, InitializeMarkPointCell)
