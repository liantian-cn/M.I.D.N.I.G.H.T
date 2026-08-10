-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local PLAYER_STATUS = addonTable.CELL_CLASSIFICATION.PLAYER_STATUS

-- 本地变量定义
local insert = table.insert
local CELL_INDEX = 27
local CELL_POSITION_X = 27
local CELL_POSITION_Y = 7
local AURA_BORDER_FULL_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_full.tga"

-- 代码部分

--[[
摘要：输出玩家自身的 PartyBuff 存在状态。

描述：
使用 WoW 12.1 AuraContainer 的单一 AuraSlot，在玩家拥有任一职业配置 PartyBuff 增益时覆盖状态 Cell。
候选范围只由 PartyBuff.spellIDs 决定；Aura 数据由受管容器处理，业务代码不读取 AuraData 或 Aura 索引。

主要变量信息：
CELL_INDEX：玩家状态分类索引 27。
CELL_POSITION_X、CELL_POSITION_Y：固定矩阵坐标 X=27、Y=7。

修改记录：
2026-07-26：根据小队模块需求新增玩家 PartyBuff 指示器。
]]

local function CreateSpellIDMap(spellIDs)
    local includeSpellIDs = {}

    for _, spellID in ipairs(spellIDs) do
        includeSpellIDs[spellID] = true
    end

    return includeSpellIDs
end

local function InitializeAuraButton(auraButton, size, container, parent)
    auraButton:SetSize(size.CELL, size.CELL)
    auraButton:SetPoint("TOPLEFT", container, "TOPLEFT")
    auraButton:SetFrameLevel(parent:GetFrameLevel() + 10)

    auraButton.ActiveOverlay = auraButton:CreateTexture(nil, "OVERLAY")
    auraButton.ActiveOverlay:SetAllPoints(auraButton)
    auraButton.ActiveOverlay:SetTexture(AURA_BORDER_FULL_TEXTURE)
    auraButton.ActiveOverlay:SetVertexColor(PLAYER_STATUS / 255, CELL_INDEX / 255, 1, 1)
end

local function InitFrame()
    local size = addonTable.SIZE
    local parent = addonTable.MartixFrame
    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = PLAYER_STATUS,
        index = CELL_INDEX,
        default_value = 0,
    })
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")

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
    container:SetUnit("player")

    container:AddAuraSlot("party_buff", "HELPFUL", {
        candidateFilters = {
            includeSpellIDs = CreateSpellIDMap(addonTable.SPEC.PartyBuff.spellIDs),
        },
        initializeFrame = function(frame)
            InitializeAuraButton(frame, size, container, parent)
        end,
    })
end

insert(addonTable.FrameInitFuncs, InitFrame)
