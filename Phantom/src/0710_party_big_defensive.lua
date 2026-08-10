-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local BigDefensive = AuraContainerSortMethod.BigDefensive
local Normal = AuraContainerSortDirection.Normal

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_BIG_DEFENSIVE = addonTable.CELL_CLASSIFICATION.PARTY_BIG_DEFENSIVE

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分
--[[
摘要：创建小队成员大型防御效果的 AuraSlot 指示器。

描述：
过滤器保持 HELPFUL|BIG_DEFENSIVE，并保留 BigDefensive/Normal 排序；AuraContainer 自行处理 UNIT_AURA。
名册变化时，仍存在的固定 token 通过一次 Hide/Show 重建候选，缺席 token 隐藏容器。

主要变量信息：
cells 保存四个底层矩阵 Cell，containers 保存四个 Aura 容器；PARTY_BIG_DEFENSIVE 是矩阵分类。

修改记录：
2026-07-26：按小队属性拆分并移除普通业务事件触发的 Aura 全量刷新。
]]

local function InitFrame()
    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local cells = {}
    local containers = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        local index = memberIndex
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        local y = PARTY_ROW_Y[index]
        local cell = Cell:New({
            x = 10,
            y = y,
            classification = PARTY_BIG_DEFENSIVE,
            index = index,
            default_value = 0,
        })
        cell.Frame:SetFrameLevel(parent:GetFrameLevel() + 5)
        cells[index] = cell
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 9 * size.CELL, -(y - 1) * size.CELL)
        container:SetFrameLevel(parent:GetFrameLevel() + 10)
        container:SetSize(size.CELL, size.CELL)
        container:SetUnit(unitToken)
        container:AddAuraSlot("big_defensive", "HELPFUL|BIG_DEFENSIVE", {
            sortMethod = BigDefensive,
            sortDirection = Normal,
            initializeFrame = function(auraButton)
                auraButton:SetSize(size.CELL, size.CELL)
                auraButton:SetPoint("TOPLEFT", container, "TOPLEFT")
                auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)
                auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
                auraButton.ActiveOverlay:SetAllPoints(auraButton)
                auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
                auraButton.ActiveOverlay:SetVertexColor(PARTY_BIG_DEFENSIVE / 255, index / 255, 1, 1)
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

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function()
        updateVisibility(true)
    end)
    updateVisibility(false)
end

insert(addonTable.FrameInitFuncs, InitFrame)
