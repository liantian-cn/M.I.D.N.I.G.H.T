local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local PrimaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function PrimaryResourceBarMixin:OnLayoutChange(layoutName)
    -- It was previously enabled when Maelstrom Weapon was primary, no longer the case so disable for now
    SenseiClassResourceBarDB[self.config.dbName][layoutName].showTicks = false
end

function PrimaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    self._resourceTable = self._resourceTable or {
        ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
        ["DEMONHUNTER"] = Enum.PowerType.Fury,
        ["DRUID"]       = {
            [0]                     = {
                [102] = Enum.PowerType.LunarPower, -- Balance
                [103] = Enum.PowerType.Mana, -- Feral
                [104] = Enum.PowerType.Mana, -- Guardian
                [105] = Enum.PowerType.Mana, -- Restoration
            },
            [DRUID_BEAR_FORM]       = Enum.PowerType.Rage,
            [DRUID_TREE_FORM]       = Enum.PowerType.Mana,
            [36]                    = Enum.PowerType.Mana, -- Tome of the Wilds: Treant Form
            [DRUID_CAT_FORM]        = Enum.PowerType.Energy,
            [DRUID_TRAVEL_FORM]     = Enum.PowerType.Mana,
            [DRUID_ACQUATIC_FORM]   = Enum.PowerType.Mana,
            [DRUID_FLIGHT_FORM]     = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.LunarPower,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.LunarPower,
        },
        ["EVOKER"]      = Enum.PowerType.Mana,
        ["HUNTER"]      = Enum.PowerType.Focus,
        ["MAGE"]        = Enum.PowerType.Mana,
        ["MONK"]        = {
            [268] = Enum.PowerType.Energy, -- Brewmaster
            [269] = Enum.PowerType.Energy, -- Windwalker
            [270] = Enum.PowerType.Mana, -- Mistweaver
        },
        ["PALADIN"]     = Enum.PowerType.Mana,
        ["PRIEST"]      = {
            [256] = Enum.PowerType.Mana, -- Disciple
            [257] = Enum.PowerType.Mana, -- Holy,
            [258] = Enum.PowerType.Insanity, -- Shadow,
        },
        ["ROGUE"]       = Enum.PowerType.Energy,
        ["SHAMAN"]      = {
            [262] = Enum.PowerType.Maelstrom, -- Elemental
            [263] = Enum.PowerType.Mana, -- Enhancement
            [264] = Enum.PowerType.Mana, -- Restoration
        },
        ["WARLOCK"]     = Enum.PowerType.Mana,
        ["WARRIOR"]     = Enum.PowerType.Rage,
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

function PrimaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end

    local data = self:GetData()
    if not data then return nil, nil end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil end

    return max, current
end

addonTable.PrimaryResourceBarMixin = PrimaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.PrimaryResourceBar = {
    mixin = addonTable.PrimaryResourceBarMixin,
    dbName = "PrimaryResourceBarDB",
    editModeName = L["PRIMARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "PrimaryResourceBar",
    frameLevel = 9,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 0,
        hideManaOnRole = {},
        showManaAsPercent = false,
        showTicks = true,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

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
                tooltip = L["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"],
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
        }
    end,
}