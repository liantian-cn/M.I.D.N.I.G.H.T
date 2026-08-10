-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local ProcessAura = CustomAuraContainerAuraProcessingPolicy.ProcessAura
local Immediate = Enum.StatusBarInterpolation.Immediate
local RemainingTime = Enum.StatusBarTimerDirection.RemainingTime
local PreserveAsset = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset

-- 插件级变量定义/引用

-- 本地变量定义
local AURA_GROUP_KEY = "auras"
local AURA_BORDER_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\media\\aura\\aura_border_32_4px.tga"
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
-- Matches WoW 12.1 FrameCreationBatchSize (10) for deterministic
-- initial LIFO color mapping; no private API references.
local FRAME_ALLOCATION_BATCH_SIZE = 10

-- 代码部分
local function InitializeAuraButton(auraButton, SIZE, durationClassification, applicationClassification, g, auraColorCurve)
    local rd = durationClassification / 255
    local ra = applicationClassification / 255

    auraButton:SetSize(6 * SIZE.CELL, 2 * SIZE.CELL)

    auraButton.Icon = auraButton:CreateTexture(nil, "BACKGROUND")
    auraButton.Icon:SetSize(2 * SIZE.CELL, 2 * SIZE.CELL)
    auraButton.Icon:SetPoint("TOPLEFT", auraButton, "TOPLEFT", 0, 0)
    auraButton:SetIcon(auraButton.Icon)

    auraButton.AuraBorder = auraButton:CreateTexture(nil, "OVERLAY")
    auraButton.AuraBorder:SetTexture(AURA_BORDER_TEXTURE)
    auraButton.AuraBorder:SetAllPoints(auraButton.Icon)
    auraButton:AddDispelTypeTexture(auraButton.AuraBorder, {
        showWhenHarmful = true,
        showWhenHelpful = true,
        style = PreserveAsset,
        customDispelColorCurve = auraColorCurve,
    })

    -- DurationBar: horizontal, top-right, 4*CELL x CELL
    auraButton.DurationBar = CreateFrame("StatusBar", nil, auraButton)
    auraButton.DurationBar:SetSize(4 * SIZE.CELL, SIZE.CELL)
    auraButton.DurationBar:SetPoint("TOPRIGHT", auraButton, "TOPRIGHT", 0, 0)
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

    -- ApplicationBar: horizontal, bottom-right, 4*CELL x CELL
    auraButton.ApplicationBar = CreateFrame("StatusBar", nil, auraButton)
    auraButton.ApplicationBar:SetSize(4 * SIZE.CELL, SIZE.CELL)
    auraButton.ApplicationBar:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 0, 0)
    auraButton.ApplicationBar:SetOrientation("HORIZONTAL")
    auraButton.ApplicationBar:SetStatusBarTexture(WHITE_TEXTURE)
    auraButton.ApplicationBar:SetStatusBarColor(ra, g, 1, 1)

    auraButton.ApplicationBar.Background = auraButton.ApplicationBar:CreateTexture(nil, "BACKGROUND")
    auraButton.ApplicationBar.Background:SetAllPoints(auraButton.ApplicationBar)
    auraButton.ApplicationBar.Background:SetColorTexture(ra, g, 0, 1)

    auraButton:SetApplicationBar(auraButton.ApplicationBar, {
        maxApplications = 4,
        interpolation = Immediate,
    })
end

-- Creates a dynamic non-fixed Aura display container backed by one AuraGroup.
function addonTable.CreateAuraGroupContainer(options)
    assert(options.auraColorCurve, "CreateAuraGroupContainer: options.auraColorCurve is required")
    local SIZE = addonTable.SIZE
    local parent = addonTable.MartixFrame
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")

    container:SetPoint("TOPLEFT", parent, "TOPLEFT", (options.x - 1) * SIZE.CELL, -(options.y - 1) * SIZE.CELL)
    container:SetUnit(options.unitToken)

    if options.processAuraOptions ~= nil then
        container:SetAuraProcessingPolicy(ProcessAura, options.processAuraOptions)
    end

    local initCounter = 0
    local maxFrameCount = options.maxFrameCount
    -- Arithmetic-safe period for color-index mapping inside the closure.
    -- Only finite positive integers accepted; nil, 0, math.huge, and
    -- non-integer numbers use the no-error fallback (g=1/255).
    -- Original maxFrameCount is preserved unchanged for AddAuraGroup.
    local safeFrameCount = 0
    if type(maxFrameCount) == "number" and maxFrameCount > 0 and maxFrameCount < math.huge and maxFrameCount % 1 == 0 then
        safeFrameCount = maxFrameCount
    end

    container:AddAuraGroup(AURA_GROUP_KEY, options.filterString, {
        maxFrameCount = maxFrameCount,
        candidateFilters = options.candidateFilters,
        sortMethod = options.sortMethod,
        sortDirection = options.sortDirection,
        initializeFrame = function(auraButton)
            -- Blizzard creates FrameCreationBatchSize (10) frames in sequence,
            -- calling initializeFrame for each. LIFO acquisition pops the last
            -- created first. With current caller maxFrameCount=5, the first 5
            -- acquired frames (creation frames 10..6) receive G indexes 1..5;
            -- all 10 initial frames are assigned values 1..5.
            initCounter = initCounter + 1
            local g = (safeFrameCount > 0 and ((FRAME_ALLOCATION_BATCH_SIZE - initCounter) % safeFrameCount + 1) or 1) / 255
            InitializeAuraButton(auraButton, SIZE, options.durationClassification, options.applicationClassification, g, options.auraColorCurve)
        end,
        layout = {
            elementSpacingX = 0,
            elementSpacingY = 0,
            gapX = 0,
            gapY = 0,
        },
    })

    return container
end
