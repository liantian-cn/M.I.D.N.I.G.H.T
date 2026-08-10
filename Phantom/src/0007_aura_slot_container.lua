-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local Immediate = Enum.StatusBarInterpolation.Immediate
local RemainingTime = Enum.StatusBarTimerDirection.RemainingTime

-- 插件级变量定义/引用

-- 本地变量定义
local SLOT_KEY_PREFIX = "slot_"
local DEFAULT_MAX_APPLICATIONS = 2
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- 代码部分
local function CreateSpellIDMap(spellIDs)
    local includeSpellIDs = {}

    for _, spellID in ipairs(spellIDs) do
        includeSpellIDs[spellID] = true
    end

    return includeSpellIDs
end

local function ValidateMaxApplications(maxApplications, slotIndex)
    if maxApplications == nil then
        return DEFAULT_MAX_APPLICATIONS
    end

    assert(
        type(maxApplications) == "number"
        and maxApplications > 0
        and maxApplications < math.huge
        and maxApplications % 1 == 0,
        "slot " .. slotIndex .. ": maxApplications must be a positive finite integer"
    )

    return maxApplications
end

local function InitializeAuraButton(auraButton, SIZE, durationClassification, applicationClassification, slotIndex)
    local rd = durationClassification / 255
    local ra = applicationClassification / 255
    local g = slotIndex / 255

    auraButton:SetSize(4 * SIZE.CELL, 2 * SIZE.CELL)

    -- DurationBar: top row, horizontal, 4*CELL x CELL
    auraButton.DurationBar = CreateFrame("StatusBar", nil, auraButton)
    auraButton.DurationBar:SetSize(4 * SIZE.CELL, SIZE.CELL)
    auraButton.DurationBar:SetPoint("TOPLEFT", auraButton, "TOPLEFT", 0, 0)
    auraButton.DurationBar:SetOrientation("HORIZONTAL")
    auraButton.DurationBar:SetStatusBarTexture(WHITE_TEXTURE)
    auraButton.DurationBar:SetStatusBarColor(rd, g, 1, 1)

    auraButton.DurationBar.Background = auraButton.DurationBar:CreateTexture(nil, "BACKGROUND")
    auraButton.DurationBar.Background:SetAllPoints(auraButton.DurationBar)
    auraButton.DurationBar.Background:SetColorTexture(rd, g, 0, 1)

    auraButton:SetDurationBar(auraButton.DurationBar, {
        interpolation = Immediate,
        direction = RemainingTime,
    })

    -- ApplicationBar: bottom row, horizontal, 4*CELL x CELL
    auraButton.ApplicationBar = CreateFrame("StatusBar", nil, auraButton)
    auraButton.ApplicationBar:SetSize(4 * SIZE.CELL, SIZE.CELL)
    auraButton.ApplicationBar:SetPoint("BOTTOMLEFT", auraButton, "BOTTOMLEFT", 0, 0)
    auraButton.ApplicationBar:SetOrientation("HORIZONTAL")
    auraButton.ApplicationBar:SetStatusBarTexture(WHITE_TEXTURE)
    auraButton.ApplicationBar:SetStatusBarColor(ra, g, 1, 1)

    auraButton.ApplicationBar.Background = auraButton.ApplicationBar:CreateTexture(nil, "BACKGROUND")
    auraButton.ApplicationBar.Background:SetAllPoints(auraButton.ApplicationBar)
    auraButton.ApplicationBar.Background:SetColorTexture(ra, g, 0, 1)
end

-- Creates a fixed Spell ID AuraSlot container.
-- options.slots and each slot's spellIDs field must be dense ordered arrays; spellIDs contains spell IDs.
-- Each slot entry may include optional maxApplications (positive finite integer, defaults to 2).
function addonTable.CreateAuraSlotContainer(options)
    local maxSlots = options.max_slots
    assert(
        type(maxSlots) == "number" and maxSlots >= 0 and maxSlots < math.huge and maxSlots % 1 == 0,
        "options.max_slots must be a finite non-negative integer"
    )

    local SIZE = addonTable.SIZE
    local parent = addonTable.MartixFrame
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")

    container:SetPoint("TOPLEFT", parent, "TOPLEFT", (options.x - 1) * SIZE.CELL, -(options.y - 1) * SIZE.CELL)
    container:SetUnit(options.unitToken)

    local durationClassification = options.durationClassification
    local applicationClassification = options.applicationClassification

    for slotIndex, slotInfo in ipairs(options.slots) do
        if slotIndex > maxSlots then
            break
        end

        local index = slotIndex
        local maxApps = ValidateMaxApplications(slotInfo.maxApplications, index)

        container:AddAuraSlot(SLOT_KEY_PREFIX .. index, options.filterString, {
            candidateFilters = {
                includeSpellIDs = CreateSpellIDMap(slotInfo.spellIDs),
            },
            initializeFrame = function(frame)
                InitializeAuraButton(frame, SIZE, durationClassification, applicationClassification, index)
                frame:SetApplicationBar(frame.ApplicationBar, {
                    maxApplications = maxApps,
                    interpolation = Immediate,
                })
                frame:SetPoint("TOPLEFT", container, "TOPLEFT", (index - 1) * 4 * SIZE.CELL, 0)
            end,
        })
    end

    return container
end
