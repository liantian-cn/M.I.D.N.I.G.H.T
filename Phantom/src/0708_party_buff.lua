-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_BUFF = addonTable.CELL_CLASSIFICATION.PARTY_BUFF

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分
--[[
摘要：创建小队成员 PartyBuff 的 AuraSlot 指示器。

描述：
为 party1 至 party4 创建四个固定的 AuraContainer，并为每个成员创建一个 PARTY_BUFF Cell。
每个 AuraContainer 使用 HELPFUL 过滤器，并通过 SPEC.PartyBuff.spellIDs 限定候选 Aura。
AuraContainer 自行处理原生 UNIT_AURA；名册变化时隐藏缺席成员，并通过 Hide/Show 重建仍存在固定 token 的 Aura 候选。
Mark of the Wild 在玩家自身的 Aura ID 为 1126，施加到其他单位时的 Aura ID 为 432661，因此 PartyBuff 白名单必须同时配置这两个 ID。

主要变量信息：
PARTY_UNITS 保存四个固定的小队单位令牌；PARTY_ROW_Y 保存四个成员对应的矩阵行坐标。
containers 保存四个 AuraContainer；CreateSpellIDMap 将职业配置的 Spell ID 列表转换为 Aura 候选白名单。

修改记录：
2026-07-26：按冻结 plan 恢复 PartyBuff 的 HELPFUL 与 Spell ID 候选过滤，修复其他单位爪子 Aura ID 配置缺失。
2026-07-26：按冻结 plan 补充名册清理和固定 party token 换人后的 Aura 候选重建。
]]

local function CreateSpellIDMap(spellIDs)
    local includeSpellIDs = {}

    for _, spellID in ipairs(spellIDs) do
        includeSpellIDs[spellID] = true
    end

    return includeSpellIDs
end

local function InitFrame()
    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local containers = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        local index = memberIndex
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        local y = PARTY_ROW_Y[index]
        local cell = Cell:New({
            x = 8,
            y = y,
            classification = PARTY_BUFF,
            index = index,
            default_value = 0,
        })
        cell.Frame:SetFrameLevel(parent:GetFrameLevel() + 5)
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 7 * size.CELL, -(y - 1) * size.CELL)
        container:SetFrameLevel(parent:GetFrameLevel() + 10)
        container:SetSize(size.CELL, size.CELL)
        container:SetUnit(unitToken)
        container:AddAuraSlot("party_buff", "HELPFUL", {
            candidateFilters = {
                includeSpellIDs = CreateSpellIDMap(addonTable.SPEC.PartyBuff.spellIDs),
            },
            initializeFrame = function(auraButton)
                auraButton:SetSize(size.CELL, size.CELL)
                auraButton:SetPoint("TOPLEFT", container, "TOPLEFT")
                auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)
                auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
                auraButton.ActiveOverlay:SetAllPoints(auraButton)
                auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
                auraButton.ActiveOverlay:SetVertexColor(PARTY_BUFF / 255, index / 255, 1, 1)
                end,
            })
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
