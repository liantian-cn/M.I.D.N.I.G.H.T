local addonName, addonTable = ...

------------------------------------------------------------
-- BAR FACTORY
------------------------------------------------------------
local function CreateBarInstance(config, parent, frameLevel)
    -- Initialize database
    if not SenseiClassResourceBarDB[config.dbName] then
        SenseiClassResourceBarDB[config.dbName] = {}
    end

    -- Create frame
    local bar = CreateFromMixins(config.mixin or addonTable.BarMixin)
    bar:Init(config, parent, frameLevel)

    -- Copy defaults if needed
    local curLayout = addonTable.LEM.GetActiveLayoutName() or "Default"
    if not SenseiClassResourceBarDB[config.dbName][curLayout] then
        SenseiClassResourceBarDB[config.dbName][curLayout] = CopyTable(bar.defaults)
    end

    bar:OnLoad()
    bar:GetFrame():SetScript("OnEvent", function(_, ...)
        bar:OnEvent(...)
    end)

    bar:ApplyVisibilitySettings()
    bar:ApplyLayout(nil, true)
    bar:UpdateDisplay(nil, true)

    return bar
end

------------------------------------------------------------
-- INITIALIZE BARS
------------------------------------------------------------
local function InitializeBar(config, frameLevel)
    local bar = CreateBarInstance(config, UIParent, math.max(0, frameLevel or 0))

    local defaults = CopyTable(addonTable.commonDefaults)
    for k, v in pairs(config.defaultValues or {}) do
        defaults[k] = v
    end

    local LEMSettingsLoader = CreateFromMixins(addonTable.LEMSettingsLoaderMixin)
    LEMSettingsLoader:Init(bar, defaults)
    LEMSettingsLoader:LoadSettings()

    return bar
end

local SCRB = CreateFrame("Frame")
SCRB:RegisterEvent("ADDON_LOADED")
SCRB:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

        addonTable.barInstances = addonTable.barInstances or {}

        for _, config in pairs(addonTable.RegisteredBar or {}) do
            if config.loadPredicate == nil or (type(config.loadPredicate) == "function" and config.loadPredicate(config) == true) then
                local frame = InitializeBar(config, config.frameLevel or 1)
                addonTable.barInstances[config.frameName] = frame
            end
        end

        addonTable.SettingsRegistrar()
    end
end)
