-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_EXIST = addonTable.CELL_CLASSIFICATION.PARTY_EXIST

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }

-- 代码部分
--[[
摘要：输出固定 party1 至 party4 的成员存在状态。

描述：
本模块独立维护 PARTY_EXIST 分类的四个 Cell；名册变化时逐个检查固定小队 token，
成员缺席时只清理自己的 Cell。

主要变量信息：
PARTY_UNITS 和 PARTY_ROW_Y 保存成员 token 与矩阵行的固定映射。

修改记录：
2026-07-26：按小队属性拆分需求从旧小队单体实现中迁移成员存在状态。
]]

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        cells[memberIndex] = Cell:New({
            x = 1,
            y = PARTY_ROW_Y[memberIndex],
            classification = PARTY_EXIST,
            index = memberIndex,
            default_value = 0,
        })
    end

    local function updateCells()
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            if UnitExists(unitToken) then
                cells[memberIndex]:setCellBoolean(true)
            else
                cells[memberIndex]:clearCell()
            end
        end
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", updateCells)
    updateCells()
end

insert(addonTable.FrameInitFuncs, InitFrame)
