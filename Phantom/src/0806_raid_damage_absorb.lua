-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- 插件级变量定义/引用
local PARTY_DAMAGE_ABSORB = addonTable.CELL_CLASSIFICATION.PARTY_DAMAGE_ABSORB
local ABSORB_THRESHOLD = addonTable.PLAYER_DAMAGE_ABSORB_THRESHOLD

-- 本地变量定义
local insert = table.insert
local RAID_MEMBER_COUNT = 30
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- 代码部分
--[[
摘要：输出固定 raid1 至 raid30 的伤害吸收量阈值状态条。

描述：
每个成员使用 PARTY_DAMAGE_ABSORB 分类的单 Cell 状态条，直接接收可能为 secret 的吸收量。
名册变化全量刷新；UNIT_ABSORB_AMOUNT_CHANGED 通过 token 查询表只更新事件指定成员；缺席成员归零。

主要变量信息：
ABSORB_THRESHOLD 是共享吸收阈值；RAID_LAYOUT 保存固定位置与 index；RAID_UNIT_INDEX 路由高频事件。

修改记录：
2026-07-30：按团队属性冻结计划新增团队伤害吸收输出。
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
    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local absorbBars = {}

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        local absorbBar = CreateFrame("StatusBar", nil, parent)
        local red = PARTY_DAMAGE_ABSORB / 255
        local green = member.index / 255

        absorbBar:SetSize(size.CELL, size.CELL)
        absorbBar:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            (member.x + 4) * size.CELL,
            -(member.y - 1) * size.CELL
        )
        absorbBar:SetStatusBarTexture(WHITE_TEXTURE)
        absorbBar:SetStatusBarColor(red, green, 1, 1)
        absorbBar:SetMinMaxValues(ABSORB_THRESHOLD, ABSORB_THRESHOLD + 1)
        local background = absorbBar:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(absorbBar)
        background:SetColorTexture(red, green, 0, 1)
        absorbBars[raidNumber] = absorbBar
    end

    local function updateMember(raidNumber)
        local member = RAID_LAYOUT[raidNumber]
        if UnitExists(member.unitToken) then
            absorbBars[raidNumber]:SetValue(UnitGetTotalAbsorbs(member.unitToken))
        else
            absorbBars[raidNumber]:SetValue(0)
        end
    end

    local function updateAllMembers()
        for raidNumber = 1, RAID_MEMBER_COUNT do
            updateMember(raidNumber)
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
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
