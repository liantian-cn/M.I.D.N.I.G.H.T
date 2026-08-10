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
local RAID_MEMBER_COUNT = 30

-- 代码部分
--[[
摘要：输出固定 raid1 至 raid30 是否为玩家当前目标。

描述：
本模块独立维护 PARTY_TARGET 分类的三十个 Cell。玩家目标变化和名册变化执行全量刷新；
UNIT_TARGET 使用 raid token 查询表，只更新事件指定的成员，并忽略非 raid1 至 raid30 的单位。

主要变量信息：
RAID_LAYOUT 保存固定坐标与分类索引；RAID_UNIT_INDEX 将事件 unit token 映射到团队编号。

修改记录：
2026-07-30：按团队属性冻结计划新增团队成员当前目标输出。
]]

local RAID_LAYOUT = {}
local RAID_UNIT_INDEX = {}

for raidNumber = 1, RAID_MEMBER_COUNT do
    local unitToken = "raid" .. raidNumber
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
        unitToken = unitToken,
        x = x,
        y = y,
        index = raidNumber + 10,
    }
    RAID_UNIT_INDEX[unitToken] = raidNumber
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        cells[raidNumber] = Cell:New({
            x = member.x + 1,
            y = member.y,
            classification = PARTY_TARGET,
            index = member.index,
            default_value = 0,
        })
    end

    local function updateMember(raidNumber)
        local member = RAID_LAYOUT[raidNumber]
        if UnitExists(member.unitToken) then
            cells[raidNumber]:setCellBoolean(UnitIsUnit(member.unitToken, "target"))
        else
            cells[raidNumber]:clearCell()
        end
    end

    local function updateAllMembers()
        for raidNumber = 1, RAID_MEMBER_COUNT do
            updateMember(raidNumber)
        end
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_TARGET")
    eventFrame:SetScript("OnEvent", function(self, event, unitToken)
        if event == "UNIT_TARGET" then
            local raidNumber = RAID_UNIT_INDEX[unitToken]
            if raidNumber then
                updateMember(raidNumber)
            end
        else
            updateAllMembers()
        end
    end)
    updateAllMembers()
end

insert(addonTable.FrameInitFuncs, InitFrame)
