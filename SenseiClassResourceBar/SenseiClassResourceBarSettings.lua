local addonName, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")

local function Register()
	if not SenseiClassResourceBarDB then
		SenseiClassResourceBarDB = {}
	end

	if not SenseiClassResourceBarDB["_Settings"] then
		SenseiClassResourceBarDB["_Settings"] = {}
	end

	local rootCategory = SettingsLib:CreateRootCategory(addonName)
    addonTable.rootSettingsCategory = rootCategory

	local categories = {
		["root"] = rootCategory,
	}

    for _, feature in pairs(addonTable.AvailableFeatures or {}) do
		local metadata = addonTable.FeaturesMetadata[feature] or {}
		local settingsPanelInitializer = addonTable.SettingsPanelInitializers[feature] or nil
		if metadata then
			local category
			if not metadata.category then
				category = rootCategory
			else
				category = categories[metadata.category] or SettingsLib:CreateCategory(rootCategory, metadata.category)
				categories[metadata.category] = category
			end

			if settingsPanelInitializer then
				settingsPanelInitializer(category)
			end
		end
    end
end

addonTable.SettingsRegistrar = Register