-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local Immediate = Enum.StatusBarInterpolation.Immediate
local RemainingTime = Enum.StatusBarTimerDirection.RemainingTime

-- 插件级变量定义/引用

-- 本地变量定义
local insert = table.insert
local MAX_PARTY_HOT_GROUPS = 5
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }
local HOT_CLASSIFICATIONS = {
    addonTable.CELL_CLASSIFICATION.PARTY_HOT1,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT2,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT3,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT4,
    addonTable.CELL_CLASSIFICATION.PARTY_HOT5,
}
local SLOT_KEY_PREFIX = "party_hot_"
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- 代码部分
--[[
摘要：创建四名小队成员的五组 HOT DurationBar。

描述：
每组使用一个 AuraSlot，过滤器严格为 PLAYER|HELPFUL，仅匹配玩家本人施放的配置 HOT；
每行从 X=11 开始，每组占四个 Cell，未配置位置保持空白。AuraContainer 自行处理 UNIT_AURA，名册变化只重置固定 token 的容器。

主要变量信息：
MAX_PARTY_HOT_GROUPS 是五组上限；HOT_CLASSIFICATIONS 是五组 R 通道分类；PARTY_UNITS 和 PARTY_ROW_Y 保存固定成员布局。

修改记录：
2026-07-26：从旧小队 DurationBar 文件迁移 HOT 构造，并纳入独立小队模块生命周期。
]]

local function CreateSpellIDMap(spellIDs)
    local includeSpellIDs = {}
    for _, spellID in ipairs(spellIDs) do
        includeSpellIDs[spellID] = true
    end
    return includeSpellIDs
end

local function InitializeDurationButton(auraButton, size, classification, memberIndex, container, slotIndex)
    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    local red = classification / 255
    local green = memberIndex / 255

    auraButton:SetSize(4 * size.CELL, size.CELL)
    auraButton:SetPoint("TOPLEFT", container, "TOPLEFT", (slotIndex - 1) * 4 * size.CELL, 0)
    durationBar:SetAllPoints(auraButton)
    durationBar:SetOrientation("HORIZONTAL")
    durationBar:SetStatusBarTexture(WHITE_TEXTURE)
    durationBar:SetStatusBarColor(red, green, 1, 1)
    durationBar.Background = durationBar:CreateTexture(nil, "BACKGROUND")
    durationBar.Background:SetAllPoints(durationBar)
    durationBar.Background:SetColorTexture(red, green, 0, 1)
    auraButton.DurationBar = durationBar
    auraButton:SetDurationBar(durationBar, {
        interpolation = Immediate,
        direction = RemainingTime,
    })
end

local function InitFrame()
    local partyHots = addonTable.SPEC.PartyHots
    -- 在创建框架前校验 PartyHots 数量，确保配置不超过五组固定布局上限。
    assert(
        #partyHots <= MAX_PARTY_HOT_GROUPS,
        "PartyHots group count " .. #partyHots .. " exceeds limit " .. MAX_PARTY_HOT_GROUPS
    )

    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local containers = {}

    -- 为四个固定 party token 分别创建 HOT 容器，并按配置组创建对应的 DurationBar 槽位。
    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        local index = memberIndex
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        local y = PARTY_ROW_Y[index]
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 * size.CELL, -(y - 1) * size.CELL)
        container:SetFrameLevel(parent:GetFrameLevel() + 10)
        container:SetSize(MAX_PARTY_HOT_GROUPS * 4 * size.CELL, size.CELL)
        container:SetUnit(unitToken)

        for slotIndex, hotGroup in ipairs(partyHots) do
            local hotIndex = slotIndex
            container:AddAuraSlot(SLOT_KEY_PREFIX .. hotIndex, "PLAYER|HELPFUL", {
                candidateFilters = {
                    includeSpellIDs = CreateSpellIDMap(hotGroup.spellIDs),
                },
                initializeFrame = function(auraButton)
                    InitializeDurationButton(
                        auraButton,
                        size,
                        HOT_CLASSIFICATIONS[hotIndex],
                        index,
                        container,
                        hotIndex
                    )
                end,
            })
        end
        containers[index] = container
    end

    local function updateVisibility(resetExisting)
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            local container = containers[memberIndex]
            if UnitExists(unitToken) then
                if resetExisting then
                    container:Hide()
                end
                container:Show()
            else
                container:Hide()
            end
        end
    end

    -- 名册变化时重置容器可见性，使仍存在的固定 token 重建 Aura 候选。
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function()
        updateVisibility(true)
    end)
    updateVisibility(false)
end

insert(addonTable.FrameInitFuncs, InitFrame)
