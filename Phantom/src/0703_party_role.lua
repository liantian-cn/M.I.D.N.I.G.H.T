-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateColor = CreateColor
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitGroupRolesAssignedEnum = UnitGroupRolesAssignedEnum
local Linear = Enum.LuaCurveType.Linear
local NoRole = Constants.LFG_ROLEConstants.LFG_ROLE_NO_ROLE
local Tank = Enum.LFGRole.Tank
local Healer = Enum.LFGRole.Healer
local Damage = Enum.LFGRole.Damage

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_ROLE = addonTable.CELL_CLASSIFICATION.PARTY_ROLE

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }

-- 代码部分
--[[
摘要：输出小队成员职责的固定数值编码。

描述：
每个成员拥有一个 PARTY_ROLE Cell，职责曲线将无职责、坦克、治疗和输出映射为 0、10、20、30；
名册或职责事件只刷新本模块的输出。

主要变量信息：
PARTY_UNITS 和 PARTY_ROW_Y 保存固定成员映射；roleCurves 保存每个成员的颜色曲线。

修改记录：
2026-07-26：按小队属性拆分需求从旧小队单体实现中迁移职责状态。
]]

local function CreateRoleCurve(memberIndex)
    local roleCurve = CreateColorCurve()
    local red = PARTY_ROLE / 255
    local green = memberIndex / 255

    roleCurve:SetType(Linear)
    roleCurve:AddPoint(NoRole, CreateColor(red, green, 0, 1))
    roleCurve:AddPoint(Tank, CreateColor(red, green, 10 / 255, 1))
    roleCurve:AddPoint(Healer, CreateColor(red, green, 20 / 255, 1))
    roleCurve:AddPoint(Damage, CreateColor(red, green, 30 / 255, 1))
    return roleCurve
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}
    local roleCurves = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        cells[memberIndex] = Cell:New({
            x = 3,
            y = PARTY_ROW_Y[memberIndex],
            classification = PARTY_ROLE,
            index = memberIndex,
            default_value = 0,
        })
        roleCurves[memberIndex] = CreateRoleCurve(memberIndex)
    end

    local function updateCells()
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            if UnitExists(unitToken) then
                cells[memberIndex]:setCell(roleCurves[memberIndex]:Evaluate(UnitGroupRolesAssignedEnum(unitToken)))
            else
                cells[memberIndex]:clearCell()
            end
        end
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
    eventFrame:SetScript("OnEvent", updateCells)
    updateCells()
end

insert(addonTable.FrameInitFuncs, InitFrame)
