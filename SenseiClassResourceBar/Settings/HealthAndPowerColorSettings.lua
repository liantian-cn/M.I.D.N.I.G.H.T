local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")
local L = addonTable.L

local featureId = "SCRB_POWER_COLORS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
}

local HealthData = {
	{
		label = L["HEALTH"],
		key = "HEALTH",
	},
}

local PowerData = {
    {
        label = L["MANA"],
        key = Enum.PowerType.Mana, -- Key in config, passed to addonTable.GetOverrideResourceColor and addonTable.GetResourceColor to retrieve the color values
    },
    {
        label = L["RAGE"],
        key = Enum.PowerType.Rage,
    },
    {
        label = L["WHIRLWIND"],
        key = "WHIRLWIND",
    },
    {
        label = L["FOCUS"],
        key = Enum.PowerType.Focus,
    },
    {
        label = L["TIP_OF_THE_SPEAR"],
        key = "TIP_OF_THE_SPEAR",
    },
    {
        label = L["ENERGY"],
        key = Enum.PowerType.Energy,
    },
    {
        label = L["RUNIC_POWER"],
        key = Enum.PowerType.RunicPower,
    },
    {
        label = L["LUNAR_POWER"],
        key = Enum.PowerType.LunarPower,
    },
    {
        label = L["MAELSTROM"],
        key = Enum.PowerType.Maelstrom,
    },
    {
        label = L["MAELSTROM_WEAPON"],
        key = "MAELSTROM_WEAPON",
    },
    {
        label = L["MAELSTROM_WEAPON"] .. ' > 5',
        key = "MAELSTROM_WEAPON_ABOVE_5",
    },
    {
        label = L["INSANITY"],
        key = Enum.PowerType.Insanity,
    },
    {
        label = L["FURY"],
        key = Enum.PowerType.Fury,
    },
    {
        label = L["BLOOD_RUNE"],
        key = Enum.PowerType.RuneBlood,
    },
    {
        label = L["FROST_RUNE"],
        key = Enum.PowerType.RuneFrost,
    },
    {
        label = L["UNHOLY_RUNE"],
        key = Enum.PowerType.RuneUnholy,
    },
    {
        label = L["COMBO_POINTS"],
        key = Enum.PowerType.ComboPoints,
    },
    {
        label = L["OVERCHARGED_COMBO_POINTS"],
        key = "OVERCHARGED_COMBO_POINTS",
    },
    {
        label = L["SOUL_SHARDS"],
        key = Enum.PowerType.SoulShards,
    },
    {
        label = L["HOLY_POWER"],
        key = Enum.PowerType.HolyPower,
    },
    {
        label = L["CHI"],
        key = Enum.PowerType.Chi,
    },
    {
        label = L["STAGGER_LOW"],
        key = "STAGGER_LOW",
    },
    {
        label = L["STAGGER_MEDIUM"],
        key = "STAGGER_MEDIUM",
    },
    {
        label = L["STAGGER_HIGH"],
        key = "STAGGER_HEAVY",
    },
    {
        label = L["ARCANE_CHARGES"],
        key = Enum.PowerType.ArcaneCharges,
    },
    {
        label = L["ICICLES"],
        key = "ICICLES",
    },
    {
        label = L["SOUL_FRAGMENTS_VENGEANCE"],
        key = "SOUL_FRAGMENTS_VENGEANCE",
    },
    {
        label = L["SOUL_FRAGMENTS_DDH"],
        key = "SOUL_FRAGMENTS",
    },
    {
        label = L["SOUL_FRAGMENTS_VOID_META"],
        key = "SOUL_FRAGMENTS_VOID_META",
    },
    {
        label = L["ESSENCE"],
        key = Enum.PowerType.Essence,
    },
    {
        label = L["EBON_MIGHT"],
        key = "EBON_MIGHT",
    },
    {
        label = L["FREEZE"],
        key = "FREEZE",
    },
}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    if not SenseiClassResourceBarDB["_Settings"]["HealthColors"] then
		SenseiClassResourceBarDB["_Settings"]["HealthColors"] = {}
	end

    if not SenseiClassResourceBarDB["_Settings"]["PowerColors"] then
		SenseiClassResourceBarDB["_Settings"]["PowerColors"] = {}
	end

    local powerColorSection = SettingsLib:CreateExpandableSection(category, {
        name = L["SETTINGS_HEADER_POWER_COLORS"],
        expanded = true,
        colorizeTitle = true,
    })

    SettingsLib:CreateColorOverrides(category, {
        entries = PowerData,
        hasOpacity = true,
        getColor = function(key)
            local color = addonTable:GetOverrideResourceColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        setColor = function(key, r, g, b, a)
            SenseiClassResourceBarDB["_Settings"]["PowerColors"][key] = { r = r, g = g, b = b, a = a or 1 }
            addonTable.updateBars()
        end,
        getDefaultColor = function(key)
            local color = addonTable:GetResourceColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        colorizeLabel = true,
        parentSection = powerColorSection,
    })

    local healthColorSection = SettingsLib:CreateExpandableSection(category, {
        name = L["SETTINGS_HEADER_HEALTH_COLOR"],
        expanded = true,
        colorizeTitle = true,
    })

    SettingsLib:CreateColorOverrides(category, {
        entries = HealthData,
        hasOpacity = true,
        getColor = function(key)
            local color = addonTable:GetOverrideHealthBarColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        setColor = function(key, r, g, b, a)
            SenseiClassResourceBarDB["_Settings"]["HealthColors"][key] = { r = r, g = g, b = b, a = a or 1 }
            addonTable.updateBars()
        end,
        getDefaultColor = function(key)
            local color = addonTable:GetHealthBarColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        colorizeLabel = true,
        parentSection = healthColorSection,
    })
end