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
local RAID_MEMBER_COUNT = 30

-- 代码部分
--[[
摘要：输出固定 raid1 至 raid30 的成员存在状态。

描述：
本模块独立维护 PARTY_EXIST 分类的三十个 Cell。每个 Cell 使用团队成员确认的块起点，
并以团队编号加 10 作为分类索引；名册变化时逐个检查固定 raid token，缺席成员只清理本模块输出。

主要变量信息：
RAID_LAYOUT 保存成员 token、块起点坐标与分类索引的固定映射。

修改记录：
2026-07-30：按团队属性冻结计划新增 raid1 至 raid30 的成员存在输出。
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

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        cells[raidNumber] = Cell:New({
            x = member.x,
            y = member.y,
            classification = PARTY_EXIST,
            index = member.index,
            default_value = 0,
        })
    end

    local function updateCells()
        for raidNumber, member in ipairs(RAID_LAYOUT) do
            if UnitExists(member.unitToken) then
                cells[raidNumber]:setCellBoolean(true)
            else
                cells[raidNumber]:clearCell()
            end
        end
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", updateCells)
    updateCells()
end

insert(addonTable.FrameInitFuncs, InitFrame)
