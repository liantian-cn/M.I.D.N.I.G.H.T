-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_TARGET = addonTable.CELL_CLASSIFICATION.PARTY_TARGET

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }

-- 代码部分
--[[
摘要：输出小队成员是否为玩家当前目标。

描述：
本模块只更新 PARTY_TARGET 分类；目标切换、固定 token 的 UNIT_TARGET 和名册变化都会重新检查四个成员，
缺席成员清理自己的 Cell。

主要变量信息：
PARTY_UNITS 和 PARTY_ROW_Y 保存四个成员的固定 token 与行坐标。

修改记录：
2026-07-26：按小队属性拆分需求从旧小队单体实现中迁移目标状态。
]]

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        cells[memberIndex] = Cell:New({
            x = 2,
            y = PARTY_ROW_Y[memberIndex],
            classification = PARTY_TARGET,
            index = memberIndex,
            default_value = 0,
        })
    end

    local function updateCells()
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            if UnitExists(unitToken) then
                cells[memberIndex]:setCellBoolean(UnitIsUnit(unitToken, "target"))
            else
                cells[memberIndex]:clearCell()
            end
        end
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_TARGET", "party1", "party2", "party3", "party4")
    eventFrame:SetScript("OnEvent", updateCells)
    updateCells()
end

insert(addonTable.FrameInitFuncs, InitFrame)
