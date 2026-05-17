local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local SecondaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function SecondaryResourceBarMixin:OnLoad()
    addonTable.PowerBarMixin.OnLoad(self)

    -- Modules for the special cases requiring more work
    addonTable.Whirlwind:OnLoad(self)
end

function SecondaryResourceBarMixin:OnEvent(event, ...)
    addonTable.PowerBarMixin.OnEvent(self, event, ...)

    -- Modules for the special cases requiring more work
    addonTable.Whirlwind:OnEvent(self, event, ...)
end

function SecondaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    self._resourceTable = self._resourceTable or {
        ["DEATHKNIGHT"] = Enum.PowerType.Runes,
        ["DEMONHUNTER"] = {
            [581] = "SOUL_FRAGMENTS_VENGEANCE", -- Vengeance
            [1480] = "SOUL_FRAGMENTS", -- Devourer
        },
        ["DRUID"]       = {
            [0]                     = {
                [102] = Enum.PowerType.Mana, -- Balance
            },
            [DRUID_CAT_FORM]        = Enum.PowerType.ComboPoints,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.Mana,
        },
        ["EVOKER"]      = Enum.PowerType.Essence,
        ["HUNTER"]      = {
            [255] = "TIP_OF_THE_SPEAR", -- Survival
        },
        ["MAGE"]        = {
            [62]   = Enum.PowerType.ArcaneCharges, -- Arcane
            [64]   = "ICICLES", -- Frost
        },
        ["MONK"]        = {
            [268]  = "STAGGER", -- Brewmaster
            [269]  = Enum.PowerType.Chi, -- Windwalker
        },
        ["PALADIN"]     = Enum.PowerType.HolyPower,
        ["PRIEST"]      = {
            [258]  = Enum.PowerType.Mana, -- Shadow
        },
        ["ROGUE"]       = Enum.PowerType.ComboPoints,
        ["SHAMAN"]      = {
            [262]  = Enum.PowerType.Mana, -- Elemental
            [263]  = "MAELSTROM_WEAPON", -- Enhancement
        },
        ["WARLOCK"]     = Enum.PowerType.SoulShards,
        ["WARRIOR"]     = {
            [72] = "WHIRLWIND", -- Fury
        },
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = self._resourceTable[playerClass]

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        resource = resource and resource[formID or 0]
    end

    if type(resource) == "table" then
        return resource[specID]
    else
        return resource
    end
end

function SecondaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end
    local data = self:GetData()
    if not data then return nil, nil end

    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1

        -- Sometimes the stagger is secret (even though Blizzard said it's not), so just skip the computation if secret
        if issecretvalue(stagger) then
            return maxHealth, stagger
        end

        self._lastStaggerPercent = self._lastStaggerPercent or ((stagger / maxHealth) * 100)
        local staggerPercent = (stagger / maxHealth) * 100
        if (staggerPercent >= 30 and self._lastStaggerPercent < 30)
            or (staggerPercent < 30 and self._lastStaggerPercent >= 30)
            or (staggerPercent >= 60 and self._lastStaggerPercent < 60)
            or (staggerPercent < 60 and self._lastStaggerPercent >= 60) then
            self:ApplyForegroundSettings()
        end
        self._lastStaggerPercent = staggerPercent

        return maxHealth, stagger
    end

    if resource == "SOUL_FRAGMENTS_VENGEANCE" then
        local current = C_Spell.GetSpellCastCount(228477) or 0 -- Soul Cleave
        local max = 6

        return max, current
    end

    if resource == "SOUL_FRAGMENTS" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(1225789) or C_UnitAuras.GetPlayerAuraBySpellID(1227702) -- Soul Fragments / Collapsing Star
        local current = auraData and auraData.applications or 0
        local max = C_SpellBook.IsSpellKnown(1247534) and 35 or 50 -- Soul Glutton

        -- For performance, only update the foreground when current is below 1, this happens when switching in/out of Void Metamorphosis
        if current <= 1 then
            self:ApplyForegroundSettings()
        end

        return max, current
    end

    if resource == Enum.PowerType.Runes then
        local current = 0
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

        -- Cache rune cooldown data to avoid redundant GetRuneCooldown calls in UpdateFragmentedPowerDisplay
        if not self._runeCooldownCache then
            self._runeCooldownCache = {}
        end

        for i = 1, max do
            local start, duration, runeReady = GetRuneCooldown(i)
            self._runeCooldownCache[i] = { start = start, duration = duration, runeReady = runeReady }
            if runeReady then
                current = current + 1
            end
        end

        return max, current
    end

    if resource == Enum.PowerType.SoulShards then
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        -- If true, current and max will be something like 14 for 1.4 shard, instead of 1
        local preciseResourceCount = specID == 267

        local current = UnitPower("player", resource, preciseResourceCount)
        local max = UnitPowerMax("player", resource, preciseResourceCount)
        if max <= 0 then return nil, nil end

        return max, current
    end

    if resource == "MAELSTROM_WEAPON" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179) -- Maelstrom Weapon
        local current = auraData and auraData.applications or 0
        local max = 10

        return max / 2, current
    end

    if resource == "TIP_OF_THE_SPEAR" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(260286) -- Tip of the Spear
        local current = auraData and auraData.applications or 0
        local max = 3

        return max, current
    end

    if resource == "ICICLES" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(205473) -- Icicles
        local current = auraData and auraData.applications or 0
        local max = 5

        return max, current
    end

    if resource == "WHIRLWIND" then
        return addonTable.Whirlwind:GetStacks()
    end

    -- Regular secondary resource types
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil end

    return max, current
end

function SecondaryResourceBarMixin:GetTagValues(resource, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    local tagValues = addonTable.PowerBarMixin.GetTagValues(self, resource, max, current, precision)

    if resource == "STAGGER" then
        local staggerPercentStr = string.format(pFormat, self._lastStaggerPercent)
        tagValues["[percent]"] = function() return staggerPercentStr end
    end

    if resource == "SOUL_FRAGMENTS_VENGEANCE" then
        tagValues["[percent]"] = function() return '' end -- As the value is secret, cannot get percent for it
    end

    if resource == Enum.PowerType.SoulShards then
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        if specID == 267 then
            current = current / 10
            max = max / 10
        end

        local currentStr = string.format("%s", AbbreviateNumbers(current))
        local maxStr = string.format("%s", AbbreviateNumbers(max))
        tagValues["[current]"] = function() return currentStr end
        tagValues["[max]"] = function() return maxStr end
    end

    if resource == "MAELSTROM_WEAPON" then
        local percentStr = string.format(pFormat, (current / (max * 2)) * 100)
        local maxStr = string.format("%s", AbbreviateNumbers(max * 2))
        tagValues["[percent]"] = function() return percentStr end
        tagValues["[max]"] = function() return maxStr end
    end

    return tagValues
end

function SecondaryResourceBarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    self:HideBlizzardSecondaryResource(layoutName, data)

    addonTable.PowerBarMixin.ApplyVisibilitySettings(self, layoutName, inCombat)
end

function SecondaryResourceBarMixin:HideBlizzardSecondaryResource(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    -- Blizzard Frames are protected in combat
    if data.hideBlizzardSecondaryResourceUi == nil or InCombatLockdown() then return end

    local playerClass = select(2, UnitClass("player"))
    local blizzardResourceFrames = {
        ["DEATHKNIGHT"] = RuneFrame,
        ["DRUID"] = DruidComboPointBarFrame,
        ["EVOKER"] = EssencePlayerFrame,
        ["MAGE"] = MageArcaneChargesFrame,
        ["MONK"] = MonkHarmonyBarFrame,
        ["PALADIN"] = PaladinPowerBarFrame,
        ["ROGUE"] = RogueComboPointBarFrame,
        ["WARLOCK"] = WarlockPowerFrame,
    }

    for class, f in pairs(blizzardResourceFrames) do
        if f and playerClass == class then
            if data.hideBlizzardSecondaryResourceUi == true then
                if LEM:IsInEditMode() then
                    if class ~= "DRUID" or (class == "DRUID" and GetShapeshiftFormID() == DRUID_CAT_FORM) then
                        f:Show()
                    end
                else
                    f:Hide()
                end
            elseif class ~= "DRUID" or (class == "DRUID" and GetShapeshiftFormID() == DRUID_CAT_FORM) then
                f:Show()
            end
        end
    end
end

addonTable.SecondaryResourceBarMixin = SecondaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.SecondaryResourceBar = {
    mixin = addonTable.SecondaryResourceBarMixin,
    dbName = "SecondaryResourceBarDB",
    editModeName = L["SECONDARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "SecondaryResourceBar",
    frameLevel = 6,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
        hideBlizzardSecondaryResourceUi = false,
        hideManaOnRole = {},
        hideCustomResources = {},
        showManaAsPercent = false,
        showTicks = true,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local config = bar:GetConfig()
        local dbName = config.dbName

        return {
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 103,
                name = L["HIDE_MANA_ON_ROLE"],
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideManaOnRole,
                values = addonTable.availableRoleOptions,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideManaOnRole) or defaults.hideManaOnRole
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideManaOnRole = value
                end,
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 104,
                name = L["HIDE_CUSTOM_RESOURCES"],
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideCustomResources,
                values = addonTable.availableCustomResources,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideCustomResources) or defaults.hideCustomResources
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideCustomResources = value
                end,
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 106,
                name = L["HIDE_BLIZZARD_UI"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardSecondaryResourceUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardSecondaryResourceUi ~= nil then
                        return data.hideBlizzardSecondaryResourceUi
                    else
                        return defaults.hideBlizzardSecondaryResourceUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardSecondaryResourceUi = value
                    bar:HideBlizzardSecondaryResource(layoutName)
                end,
                tooltip = L["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 304,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 305,
                name = L["SHOW_TICKS_WHEN_AVAILABLE"],
                kind = LEM.SettingType.CheckboxColor,
                default = defaults.showTicks,
                colorDefault = defaults.tickColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showTicks ~= nil then
                        return data.showTicks
                    else
                        return defaults.showTicks
                    end
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.tickColor or defaults.tickColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showTicks = value
                    bar:UpdateTicksLayout(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickColor = value
                    bar:UpdateTicksLayout(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 306,
                name = L["TICK_THICKNESS"],
                kind = LEM.SettingType.Slider,
                default = defaults.tickThickness,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and addonTable.rounded(data.tickThickness) or defaults.tickThickness
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickThickness = addonTable.rounded(value)
                    bar:UpdateTicksLayout(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showTicks == true
                end,
            },
            {
                parentId = L["CATEGORY_BAR_STYLE"],
                order = 401,
                name = L["USE_RESOURCE_TEXTURE_AND_COLOR"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.useResourceAtlas,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useResourceAtlas ~= nil then
                        return data.useResourceAtlas
                    else
                        return defaults.useResourceAtlas
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useResourceAtlas = value
                    bar:ApplyLayout(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 605,
                name = L["SHOW_MANA_AS_PERCENT"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.showManaAsPercent,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showManaAsPercent ~= nil then
                        return data.showManaAsPercent
                    else
                        return defaults.showManaAsPercent
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showManaAsPercent = value
                    bar:UpdateDisplay(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showText == true
                end,
                tooltip = L["SHOW_MANA_AS_PERCENT_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 606,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 607,
                name = L["SHOW_RESOURCE_CHARGE_TIMER"],
                kind = LEM.SettingType.CheckboxColor,
                default = defaults.showFragmentedPowerBarText,
                colorDefault = defaults.fragmentedPowerBarTextColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showFragmentedPowerBarText ~= nil then
                        return data.showFragmentedPowerBarText
                    else
                        return defaults.showFragmentedPowerBarText
                    end
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.fragmentedPowerBarTextColor or defaults.fragmentedPowerBarTextColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showFragmentedPowerBarText = value
                    bar:ApplyTextVisibilitySettings(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextColor = value
                    bar:ApplyFontSettings(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 608,
                name = L["CHARGE_TIMER_PRECISION"],
                kind = LEM.SettingType.Dropdown,
                default = defaults.fragmentedPowerBarTextPrecision,
                useOldStyle = true,
                values = addonTable.availableTextPrecisions,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextPrecision) or defaults.fragmentedPowerBarTextPrecision
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextPrecision = value
                    bar:UpdateDisplay(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showFragmentedPowerBarText == true
                end,
            },
        }
    end
}
