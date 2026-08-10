-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists

-- 插件级变量定义/引用
local Cell = addonTable.Cell

-- 本地变量定义
local insert = table.insert
local MAX_RAID_HOT_GROUPS = 5
local RAID_MEMBER_COUNT = 30
local HOT_CLASSIFICATIONS = {
    addonTable.CELL_CLASSIFICATION.PARTY_HOT1,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT2,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT3,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT4,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT5,
}
local SLOT_KEY_PREFIX = "raid_hot_"
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分
--[[
摘要：创建固定 raid1 至 raid30 的五组可选单 Cell HOT 存在指示器。

描述：
每名成员使用一个 AuraContainer，并按 PartyHots 配置顺序创建最多五个 AuraSlot。每个槽严格使用
PLAYER|HELPFUL 和该组 spellIDs 白名单，只以 ActiveOverlay 的 B=1 表示玩家施放的匹配 HOT 存在。
少于五组时不创建未配置 Cell；超过五组时在任何团队 HOT 框架创建前断言。AuraContainer 自行处理
原生 Aura 更新，名册变化通过 Hide/Show 重建仍存在固定 raid token 的候选，缺席 token 保持隐藏。

主要变量信息：
RAID_LAYOUT 保存成员块起点与 index；HOT_CLASSIFICATIONS 保存五个共享 PARTY_HOT 分类；
containers 保存三十个团队 HOT AuraContainer。

修改记录：
2026-07-30：按团队属性冻结计划新增团队单 Cell HOT 存在指示器。
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

local function CreateSpellIDMap(spellIDs)
    local includeSpellIDs = {}
    for _, spellID in ipairs(spellIDs) do
        includeSpellIDs[spellID] = true
    end
    return includeSpellIDs
end

local function InitFrame()
    local partyHots = addonTable.SPEC.PartyHots
    -- 必须在创建任何团队 HOT Cell 或 AuraContainer 前校验固定五槽上限。
    assert(
        #partyHots <= MAX_RAID_HOT_GROUPS,
        "PartyHots group count " .. #partyHots .. " exceeds raid limit " .. MAX_RAID_HOT_GROUPS
    )

    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local containers = {}

    -- 每名成员只创建已配置的槽，未配置位置继续显示矩阵原始背景。
    for raidNumber, member in ipairs(RAID_LAYOUT) do
        local index = member.index
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        container:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            member.x * size.CELL,
            -member.y * size.CELL
        )
        container:SetFrameLevel(parent:GetFrameLevel() + 10)
        container:SetSize(MAX_RAID_HOT_GROUPS * size.CELL, size.CELL)
        container:SetUnit(member.unitToken)

        for slotIndex, hotGroup in ipairs(partyHots) do
            local hotIndex = slotIndex
            local classification = HOT_CLASSIFICATIONS[hotIndex]
            local cell = Cell:New({
                x = member.x + hotIndex,
                y = member.y + 1,
                classification = classification,
                index = index,
                default_value = 0,
            })
            cell.Frame:SetFrameLevel(parent:GetFrameLevel() + 5)
            container:AddAuraSlot(SLOT_KEY_PREFIX .. hotIndex, "PLAYER|HELPFUL", {
                candidateFilters = {
                    includeSpellIDs = CreateSpellIDMap(hotGroup.spellIDs),
                },
                initializeFrame = function(auraButton)
                    auraButton:SetSize(size.CELL, size.CELL)
                    auraButton:SetPoint("TOPLEFT", container, "TOPLEFT", (hotIndex - 1) * size.CELL, 0)
                    auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)
                    auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
                    auraButton.ActiveOverlay:SetAllPoints(auraButton)
                    auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
                    auraButton.ActiveOverlay:SetVertexColor(classification / 255, index / 255, 1, 1)
                end,
            })
        end
        containers[raidNumber] = container
    end

    local function updateVisibility(resetExisting)
        for raidNumber, member in ipairs(RAID_LAYOUT) do
            local container = containers[raidNumber]
            if UnitExists(member.unitToken) then
                if resetExisting then
                    container:Hide()
                end
                container:Show()
            else
                container:Hide()
            end
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function()
        updateVisibility(true)
    end)
    updateVisibility(false)
end

insert(addonTable.FrameInitFuncs, InitFrame)
