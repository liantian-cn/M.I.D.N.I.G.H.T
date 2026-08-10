-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitHealthPercent = UnitHealthPercent

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_HEALTH = addonTable.CELL_CLASSIFICATION.PARTY_HEALTH

-- 本地变量定义
local insert = table.insert
local RAID_MEMBER_COUNT = 30

-- 代码部分
--[[
摘要：输出固定 raid1 至 raid30 的生命百分比。

描述：
生命百分比直接交给每个 Cell 的 zeroToOneCurve，避免在 Lua 中读取或计算可能受限的值。
名册变化全量刷新；UNIT_HEALTH 与 UNIT_MAXHEALTH 通过 token 查询表只更新事件指定成员。

主要变量信息：
RAID_LAYOUT 保存固定坐标与 index；RAID_UNIT_INDEX 将高频事件 token 映射到团队编号。

修改记录：
2026-07-30：按团队属性冻结计划新增团队生命百分比输出。
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
            x = member.x + 4,
            y = member.y,
            classification = PARTY_HEALTH,
            index = member.index,
            default_value = 0,
        })
    end

    local function updateMember(raidNumber)
        local member = RAID_LAYOUT[raidNumber]
        if UnitExists(member.unitToken) then
            cells[raidNumber]:setCell(UnitHealthPercent(member.unitToken, false, cells[raidNumber].zeroToOneCurve))
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
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:SetScript("OnEvent", function(self, event, unitToken)
        if event == "GROUP_ROSTER_UPDATE" then
            updateAllMembers()
        else
            local raidNumber = RAID_UNIT_INDEX[unitToken]
            if raidNumber then
                updateMember(raidNumber)
            end
        end
    end)
    updateAllMembers()
end

insert(addonTable.FrameInitFuncs, InitFrame)
