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
local RAID_MEMBER_COUNT = 30

-- 代码部分
--[[
摘要：输出固定 raid1 至 raid30 的职责编码。

描述：
每个成员使用 PARTY_ROLE Cell 和独立颜色曲线，将无职责、坦克、治疗和输出映射为 0、10、20、30。
名册或职责事件全量检查固定团队 token，缺席成员只清理本模块输出。

主要变量信息：
RAID_LAYOUT 保存固定坐标与 index；roleCurves 保存按成员 index 编码的职责颜色曲线。

修改记录：
2026-07-30：按团队属性冻结计划新增团队职责输出。
]]

local RAID_LAYOUT = {}

for raidNumber = 1, RAID_MEMBER_COUNT do
    local x
    local y
    if raidNumber <= 10 then
        x = 31 + ((raidNumber - 1) % 5) * 6
        y = raidNumber <= 5 and 8 or 10
    else
        x = 1 + ((raidNumber - 11) % 10) * 6
        y = raidNumber <= 20 and 12 or 14
    end
    RAID_LAYOUT[raidNumber] = {
        unitToken = "raid" .. raidNumber,
        x = x,
        y = y,
        index = raidNumber + 10,
    }
end

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

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        cells[raidNumber] = Cell:New({
            x = member.x + 2,
            y = member.y,
            classification = PARTY_ROLE,
            index = member.index,
            default_value = 0,
        })
        roleCurves[raidNumber] = CreateRoleCurve(member.index)
    end

    local function updateCells()
        for raidNumber, member in ipairs(RAID_LAYOUT) do
            if UnitExists(member.unitToken) then
                cells[raidNumber]:setCell(roleCurves[raidNumber]:Evaluate(UnitGroupRolesAssignedEnum(member.unitToken)))
            else
                cells[raidNumber]:clearCell()
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
