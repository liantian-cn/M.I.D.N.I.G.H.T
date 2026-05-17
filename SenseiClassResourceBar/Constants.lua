local _, addonTable = ...
-- Global variables available to other addons, only some functions are exposed
SCRB = SCRB or {}

addonTable.LSM = LibStub("LibSharedMedia-3.0")
local LSM = addonTable.LSM
local L = addonTable.L

addonTable.LEM = LibStub("LibEQOLEditMode-1.0")
addonTable.SettingsLib = LibStub("LibEQOLSettingsMode-1.0")
addonTable.LibSerialize = LibStub("LibSerialize")
addonTable.LibDeflate = LibStub("LibDeflate")

------------------------------------------------------------
-- LIBSHAREDMEDIA INTEGRATION
------------------------------------------------------------
local function InitLSM()
    LSM:Register(LSM.MediaType.BACKGROUND, "SCRB BG Bevelled", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBackgrounds\bevelled.png]])
    LSM:Register(LSM.MediaType.BACKGROUND, "SCRB BG Bevelled Grey", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBackgrounds\bevelled-grey.png]])

    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Left", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-left.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Bottom", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-bottom.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Top", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-top.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Solid", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\solid.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Absorb", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\absorb.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "None", [[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\transparent.png]])

    LSM:Register(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic.png]])
    LSM:Register(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic Thin", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic-thin.png]])

    LSM:Register(LSM.MediaType.FONT, "Friz Quadrata TT", [[Fonts\FRIZQT___CYR.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Morpheus", [[Fonts\MORPHEUS_CYR.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Arial Narrow", [[Fonts\ARIALN.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Skurri", [[Fonts\SKURRI_CYR.TTF]])
end
InitLSM()

------------------------------------------------------------
-- Constants
------------------------------------------------------------

------------------------------------------------------------
-- COMMON DEFAULTS & DROPDOWN OPTIONS
------------------------------------------------------------
addonTable.commonDefaults = {
    -- LEM settings
	enableOverlayToggle = true,
    settingsMaxHeight = select(2, GetPhysicalScreenSize()) * 0.6,
    point = "CENTER", -- Shared
    x = 0, -- Shared
    y = 0, -- Shared
    -- SCRB settings
    positionMode = "Self",
    relativeFrame = "UIParent",
    relativePoint = "CENTER",
    barVisible = "Always Visible",
    hideWhileMountedOrVehicule = false,
    barStrata = "MEDIUM",
    scale = 1,
    width = 200,
    minWidth = 0,
    widthMode = "Manual",
    height = 15,
    fillDirection = "Left to Right",
    smoothProgress = true,
    fasterUpdates = true,
    showText = true,
    textColor = {r = 1, g = 1, b = 1, a = 1},
    textFormat = "Current",
    textPrecision = "12",
    showFragmentedPowerBarText = false,
    fragmentedPowerBarTextColor = {r = 1, g = 1, b = 1, a = 1},
    fragmentedPowerBarTextPrecision = "12.3",
    font = LSM:Fetch(LSM.MediaType.FONT, "Friz Quadrata TT"),
    fontSize = 12,
    fontOutline = "OUTLINE",
    textAlign = "CENTER",
    maskAndBorderStyle = "Thin",
    borderColor = {r = 0, g = 0, b = 0, a = 1},
    backgroundStyle = "SCRB Semi-transparent",
    backgroundColor = {r = 1, g = 1, b = 1, a = 1},
    useStatusBarColorForBackgroundColor = false,
    foregroundStyle = "SCRB FG Fade Left",
}

addonTable.availableBarVisibilityOptions = {
    { text = L["ALWAYS_VISIBLE"], value = "Always Visible" },
    { text = L["IN_COMBAT"], value = "In Combat" },
    { text = L["HAS_TARGET_SELECTED"], value = "Has Target Selected" },
    { text = L["HAS_TARGET_SELECTED_OR_IN_COMBAT"], value = "Has Target Selected OR In Combat" },
    { text = L["HIDDEN"], value = "Hidden" },
}

addonTable.availableBarStrataOptions = {
    { text = L["TOOLTIP"], value = "TOOLTIP" },
    { text = L["DIALOG"], value = "DIALOG" },
    { text = L["HIGH"], value = "HIGH" },
    { text = L["MEDIUM"], value = "MEDIUM" },
    { text = L["LOW"], value = "LOW" },
    { text = L["BACKGROUND"], value = "BACKGROUND" },
}

addonTable.availableRoleOptions = {
    { text = L["TANK"], value = "TANK" },
    { text = L["HEALER"], value = "HEALER" },
    { text = L["DPS"], value = "DAMAGER" },
}

addonTable.availableCustomResources = {
    { text = L["TIP_OF_THE_SPEAR"], value = "TIP_OF_THE_SPEAR" },
    { text = L["ICICLES"], value = "ICICLES" },
    { text = L["WHIRLWIND"], value = "WHIRLWIND" },
    { text = L["SOUL_FRAGMENTS_VENGEANCE"], value = "SOUL_FRAGMENTS_VENGEANCE" },
    { text = L["MAELSTROM_WEAPON"], value = "MAELSTROM_WEAPON" },
}

addonTable.availablePositionModeOptions = function(config)
    local positions = {
        { text = L["POSITION_SELF"], value = "Self" },
    }

    if config.frameName == "PrimaryResourceBar" then
        table.insert(positions, { text = L["USE_HEALTH_BAR_POSITION_IF_HIDDEN"], value = "Use Health Bar Position If Hidden" })
        table.insert(positions, { text = L["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Secondary Resource Bar Position If Hidden" })
    elseif config.frameName == "SecondaryResourceBar" then
        table.insert(positions, { text = L["USE_HEALTH_BAR_POSITION_IF_HIDDEN"], value = "Use Health Bar Position If Hidden" })
        table.insert(positions, { text = L["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Primary Resource Bar Position If Hidden" })
    elseif config.frameName == "TertiaryResourceBar" then
        table.insert(positions, { text = L["USE_HEALTH_BAR_POSITION_IF_HIDDEN"], value = "Use Health Bar Position If Hidden" })
        table.insert(positions, { text = L["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Primary Resource Bar Position If Hidden" })
        table.insert(positions, { text = L["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Secondary Resource Bar Position If Hidden" })
    elseif config.frameName == "HealthBar" then
        table.insert(positions, { text = L["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Primary Resource Bar Position If Hidden" })
        table.insert(positions, { text = L["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"], value = "Use Secondary Resource Bar Position If Hidden" })
    end

    return positions
end

addonTable.availableRelativeFrames = function(config)
    local frames = {
        { text = L["UI_PARENT"], value = "UIParent" },
    }

    if config.frameName == "HealthBar" then
        table.insert(frames, { text = L["PRIMARY_RESOURCE_BAR"], value = "Primary Resource Bar" })
        table.insert(frames, { text = L["SECONDARY_RESOURCE_BAR"], value = "Secondary Resource Bar" })
    elseif config.frameName == "PrimaryResourceBar" then
        table.insert(frames, { text = L["HEALTH_BAR"], value = "Health Bar" })
        table.insert(frames, { text = L["SECONDARY_RESOURCE_BAR"], value = "Secondary Resource Bar" })
    elseif config.frameName == "SecondaryResourceBar" then
        table.insert(frames, { text = L["HEALTH_BAR"], value = "Health Bar" })
        table.insert(frames, { text = L["PRIMARY_RESOURCE_BAR"], value = "Primary Resource Bar" })
    else
        table.insert(frames, { text = L["HEALTH_BAR"], value = "Health Bar" })
        table.insert(frames, { text = L["PRIMARY_RESOURCE_BAR"], value = "Primary Resource Bar" })
        table.insert(frames, { text = L["SECONDARY_RESOURCE_BAR"], value = "Secondary Resource Bar" })
    end

    local additionalFrames = {
        { text = L["PLAYER_FRAME"], value = "PlayerFrame" },
        { text = L["TARGET_FRAME"], value = "TargetFrame" },
        { text = L["ESSENTIAL_COOLDOWNS"], value = "Essential Cooldowns" },
        { text = L["UTILITY_COOLDOWNS"], value = "Utility Cooldowns" },
        { text = L["TRACKED_BUFFS"], value = "Tracked Buffs" },
        { text = L["ACTION_BAR"], value = "Action Bar" },
    }

    for _, frame in pairs(additionalFrames) do
        table.insert(frames, frame)
    end

    for i = 2, 8 do
        table.insert(frames, { 
            text = string.format(L["ACTION_BAR_X"], i),
            value = "Action Bar " .. i,
        })
    end

    return frames
end

addonTable.resolveRelativeFrames = function(relativeFrame)
    local tbl = {
        ["UIParent"] = UIParent,
        ["Health Bar"] = addonTable.barInstances and addonTable.barInstances["HealthBar"] and addonTable.barInstances["HealthBar"].Frame,
        ["Primary Resource Bar"] = addonTable.barInstances and addonTable.barInstances["PrimaryResourceBar"] and addonTable.barInstances["PrimaryResourceBar"].Frame,
        ["Secondary Resource Bar"] = addonTable.barInstances and addonTable.barInstances["SecondaryResourceBar"] and addonTable.barInstances["SecondaryResourceBar"].Frame,
        ["PlayerFrame"] = PlayerFrame,
        ["TargetFrame"] = TargetFrame,
        ["Essential Cooldowns"] = _G["EssentialCooldownViewer"],
        ["Utility Cooldowns"] = _G["UtilityCooldownViewer"],
        ["Tracked Buffs"] = _G["BuffIconCooldownViewer"],
        ["Action Bar"] = _G["MainActionBar"],
        ["Action Bar 2"] = _G["MultiBarBottomLeft"],
        ["Action Bar 3"] = _G["MultiBarBottomRight"],
        ["Action Bar 4"] = _G["MultiBarRight"],
        ["Action Bar 5"] = _G["MultiBarLeft"],
        ["Action Bar 6"] = _G["MultiBar5"],
        ["Action Bar 7"] = _G["MultiBar6"],
        ["Action Bar 8"] = _G["MultiBar7"],
    }
    return tbl[relativeFrame] or UIParent
end

addonTable.availableAnchorPoints = {
    { text = L["TOPLEFT"], value = "TOPLEFT" },
    { text = L["TOP"], value = "TOP" },
    { text = L["TOPRIGHT"], value = "TOPRIGHT" },
    { text = L["LEFT"], value = "LEFT" },
    { text = L["CENTER"], value = "CENTER" },
    { text = L["RIGHT"], value = "RIGHT" },
    { text = L["BOTTOMLEFT"], value = "BOTTOMLEFT" },
    { text = L["BOTTOM"], value = "BOTTOM" },
    { text = L["BOTTOMRIGHT"], value = "BOTTOMRIGHT" },
}

addonTable.availableRelativePoints = {
    { text = L["TOPLEFT"], value = "TOPLEFT" },
    { text = L["TOP"], value = "TOP" },
    { text = L["TOPRIGHT"], value = "TOPRIGHT" },
    { text = L["LEFT"], value = "LEFT" },
    { text = L["CENTER"], value = "CENTER" },
    { text = L["RIGHT"], value = "RIGHT" },
    { text = L["BOTTOMLEFT"], value = "BOTTOMLEFT" },
    { text = L["BOTTOM"], value = "BOTTOM" },
    { text = L["BOTTOMRIGHT"], value = "BOTTOMRIGHT" },
}

addonTable.availableWidthModes = {
    { text = L["MANUAL"], value = "Manual" },
    { text = L["SYNC_WITH_ESSENTIAL_COOLDOWNS"], value = "Sync With Essential Cooldowns" },
    { text = L["SYNC_WITH_UTILITY_COOLDOWNS"], value = "Sync With Utility Cooldowns" },
    { text = L["SYNC_WITH_TRACKED_BUFFS"], value = "Sync With Tracked Buffs" },
}

addonTable.customFrameNamesToFrame = {}
addonTable.availableCustomFrames = {}

addonTable.availableFillDirections = {
    { text = L["LEFT_TO_RIGHT"], value = "Left to Right" },
    { text = L["RIGHT_TO_LEFT"], value = "Right to Left" },
    { text = L["TOP_TO_BOTTOM"], value = "Top to Bottom" },
    { text = L["BOTTOM_TO_TOP"], value = "Bottom to Top" },
}

addonTable.availableOutlineStyles = {
    { text = L["NONE"], value = "NONE" },
    { text = L["OUTLINE"], value = "OUTLINE" },
    { text = L["THICKOUTLINE"], value = "THICKOUTLINE" },
}

addonTable.availableTextFormats = {
    { text = L["CURRENT"], value = "Current" },
    { text = L["CURRENT_MAXIMUM"], value = "Current / Maximum" },
    { text = L["PERCENT"], value = "Percent" },
    { text = L["PERCENT_SYMBOL"], value = "Percent%" },
    { text = L["CURRENT_PERCENT"], value = "Current - Percent" },
    { text = L["CURRENT_PERCENT_SYMBOL"], value = "Current - Percent%" },
}

addonTable.textPrecisionAllowedForType = {
    ["Percent"] = true,
    ["Percent%"] = true,
    ["Current - Percent"] = true,
    ["Current - Percent%"] = true,
}

addonTable.availableTextPrecisions = {
    { text = "12" },
    { text = "12.3" },
    { text = "12.34" },
    { text = "12.345" },
}

addonTable.availableTextAlignmentStyles = {
    { text = L["TOP"], value = "TOP" },
    { text = L["LEFT"], value = "LEFT" },
    { text = L["CENTER"], value = "CENTER" },
    { text = L["RIGHT"], value = "RIGHT" },
    { text = L["BOTTOM"], value = "BOTTOM" },
}

addonTable.maskAndBorderStyles = {
    ["1 Pixel"] = {
        type = "fixed",
        thickness = 1,
    },
    ["Thin"] = {
        type = "fixed",
        thickness = 2,
    },
    ["Slight"] = {
        type = "fixed",
        thickness = 3,
    },
    ["Bold"] = {
        type = "fixed",
        thickness = 5,
    },
    ["Blizzard Classic"] = {
        type = "texture",
        mask = [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic-mask.png]],
        border = LSM:Fetch(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic"),
    },
    ["Blizzard Classic Thin"] = {
        type = "texture",
        mask = [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic-thin-mask.png]],
        border = LSM:Fetch(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic Thin"),
    },
    ["None"] = {},
    -- Add more styles here as needed
    -- ["style-name"] = {
    --     type = "", -- texture or fixed. Other value will not be displayed (i.e hidden)
    --     mask = "path/to/mask.png", -- Default to the whole status bar
    --     border = "path/to/border.png", -- Only for texture type
    --     thickness = 1, -- Only for fixed type
    -- },
}

addonTable.availableMaskAndBorderStyles = {}
for styleName, _ in pairs(addonTable.maskAndBorderStyles) do
    table.insert(addonTable.availableMaskAndBorderStyles, { text = styleName })
end

addonTable.backgroundStyles = {
    ["SCRB Semi-transparent"] = { type = "color", r = 0, g = 0, b = 0, a = 0.5 },
}

addonTable.availableBackgroundStyles = {}
for name, _ in pairs(addonTable.backgroundStyles) do
    table.insert(addonTable.availableBackgroundStyles, name)
end

addonTable.availableAbsorbBarPositions = {
    { text = L["BAR_POSITION_FIXED"], value = "Fixed" },
    { text = L["BAR_POSITION_REVERSED"], value = "Reversed" },
    { text = L["BAR_POSITION_ATTACH_HEALTH"], value = "Attach To Health" },
}

addonTable.availableHealAbsorbBarPositions = {
    { text = L["BAR_POSITION_FIXED"], value = "Fixed" },
    { text = L["BAR_POSITION_REVERSED"], value = "Reversed" },
    { text = L["BAR_POSITION_ATTACH_HEALTH"], value = "Attach To Health" },
}

-- Power types that should show discrete ticks
addonTable.tickedPowerTypes = {
    [Enum.PowerType.ArcaneCharges] = true,
    ["ICICLES"] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.Essence] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.SoulShards] = true,
    ["MAELSTROM_WEAPON"] = true,
    ["TIP_OF_THE_SPEAR"] = true,
    ["SOUL_FRAGMENTS_VENGEANCE"] = true,
    ["WHIRLWIND"] = true,
    ["FREEZE"] = true,
}

-- Power types that are fragmented (multiple independent segments)
addonTable.fragmentedPowerTypes = {
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.Essence] = true,
    [Enum.PowerType.Runes] = true,
    ["MAELSTROM_WEAPON"] = true,
}