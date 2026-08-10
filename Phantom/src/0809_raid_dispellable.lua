-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PARTY_DISPELLABLE = addonTable.CELL_CLASSIFICATION.PARTY_DISPELLABLE

-- 本地变量定义
local insert = table.insert
local RAID_MEMBER_COUNT = 30
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分
--[[
摘要：创建固定 raid1 至 raid30 可驱散减益的 AuraSlot 指示器。

描述：
每名成员在块内第二行首个 Cell 使用 HARMFUL|RAID_PLAYER_DISPELLABLE 与 SPEC.DISPEL_TYPES 过滤。
AuraContainer 自行处理原生 Aura 更新；GROUP_ROSTER_UPDATE 对仍存在的固定 token 执行 Hide/Show 重建候选，
缺席 token 隐藏本模块容器，不读取 AuraData、不注册 UNIT_AURA，也不主动调用 Aura 全量刷新。

主要变量信息：
RAID_LAYOUT 保存固定团队布局与 index；containers 保存三十个独立 AuraContainer。

修改记录：
2026-07-30：按团队属性冻结计划新增团队可驱散减益指示器。
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
    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local containers = {}

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        local index = member.index
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        local cell = Cell:New({
            x = member.x,
            y = member.y + 1,
            classification = PARTY_DISPELLABLE,
            index = index,
            default_value = 0,
        })
        cell.Frame:SetFrameLevel(parent:GetFrameLevel() + 5)
        container:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            (member.x - 1) * size.CELL,
            -member.y * size.CELL
        )
        container:SetFrameLevel(parent:GetFrameLevel() + 10)
        container:SetSize(size.CELL, size.CELL)
        container:SetUnit(member.unitToken)
        container:AddAuraSlot("dispellable_debuff", "HARMFUL|RAID_PLAYER_DISPELLABLE", {
            candidateFilters = {
                includeDispelTypes = addonTable.SPEC.DISPEL_TYPES,
            },
            initializeFrame = function(auraButton)
                auraButton:SetSize(size.CELL, size.CELL)
                auraButton:SetPoint("TOPLEFT", container, "TOPLEFT")
                auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)
                auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
                auraButton.ActiveOverlay:SetAllPoints(auraButton)
                auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
                auraButton.ActiveOverlay:SetVertexColor(PARTY_DISPELLABLE / 255, index / 255, 1, 1)
            end,
        })
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
