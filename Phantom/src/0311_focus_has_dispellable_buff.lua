-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local FOCUS_TARGET = addonTable.CELL_CLASSIFICATION.FOCUS_TARGET

-- 本地变量定义
local insert = table.insert
local CELL_INDEX = 11
local CELL_POSITION_X = 57
local CELL_POSITION_Y = 7
local UNIT_TOKEN = "focus"
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分

--[[
摘要：输出焦点拥有团队可驱散增益的状态。

描述：
通过 AuraSlot 显示团队成员可驱散或偷取的焦点增益；AuraContainer 自行处理 UNIT_AURA，
焦点切换和名册变化通过固定 token 的容器全量刷新重建候选。

主要变量信息：
UNIT_TOKEN 是固定 focus token；FOCUS_TARGET 和 CELL_INDEX 定义矩阵编码。

修改记录：
2026-07-26：按专精切换必须 /reload 的项目规则移除专精变化 Aura 全量刷新路径。
]]

local function InitializeAuraButton(auraButton, size, container, parent)
    auraButton:SetSize(size.CELL, size.CELL)
    auraButton:SetPoint("TOPLEFT", container, "TOPLEFT")
    auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)

    auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
    auraButton.ActiveOverlay:SetAllPoints(auraButton)
    auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
    auraButton.ActiveOverlay:SetVertexColor(FOCUS_TARGET / 255, CELL_INDEX / 255, 1, 1)
end

local function InitFrame()
    local size = addonTable.SIZE
    local parent = addonTable.MartixFrame
    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = FOCUS_TARGET,
        index = CELL_INDEX,
        default_value = 0,
    })
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
    local eventFrame = CreateFrame("Frame")

    cell.Frame:SetFrameLevel(parent:GetFrameLevel() + 5)

    container:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        (CELL_POSITION_X - 1) * size.CELL,
        -(CELL_POSITION_Y - 1) * size.CELL
    )
    container:SetFrameLevel(parent:GetFrameLevel() + 10)
    container:SetSize(size.CELL, size.CELL)
    container:SetUnit(UNIT_TOKEN)

    container:AddAuraSlot("dispellable_buff", "HELPFUL|RAID_PLAYER_DISPELLABLE", {
        candidateFilters = {
            includeDispelTypes = addonTable.SPEC.DISPEL_TYPES,
        },
        initializeFrame = function(frame)
            InitializeAuraButton(frame, size, container, parent)
        end,
    })

    -- AuraContainer 在内部更新 Aura 实例；固定 focus token 的单位身份与团队驱散能力变化需由外部事件触发全量刷新。
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function(self, event, unitTarget)
        container:UpdateAllAuras()
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
