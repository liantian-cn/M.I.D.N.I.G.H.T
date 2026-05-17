local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")
local L = addonTable.L

local featureId = "SCRB_IMPORT_EXPORT"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
	category = L["SETTINGS_CATEGORY_IMPORT_EXPORT"],
}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    SettingsLib:CreateText(category, L["SETTINGS_IMPORT_EXPORT_TEXT_1"])
    SettingsLib:CreateText(category, L["SETTINGS_IMPORT_EXPORT_TEXT_2"])

    SettingsLib:CreateButton(category, {
		text = L["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"],
		func = function()
			local exportString = addonTable.exportProfileAsString(false, true)
			if not exportString then
				addonTable.prettyPrint(L["EXPORT_FAILED"])
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

    SettingsLib:CreateButton(category, {
		text = L["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"],
		func = function()
			local exportString = addonTable.exportProfileAsString(true, true)
			if not exportString then
				addonTable.prettyPrint(L["EXPORT_FAILED"])
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

    SettingsLib:CreateButton(category, {
		text = L["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"],
		func = function()
			local exportString = addonTable.exportProfileAsString(true, false)
			if not exportString then
				addonTable.prettyPrint(L["EXPORT_FAILED"])
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

	SettingsLib:CreateButton(category, {
		text = L["SETTINGS_BUTTON_IMPORT"],
		func = function()
			StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnAccept = function(self)
				local editBox = self.editBox or self:GetEditBox()
				local input = editBox:GetText() or ""

				local ok, error = addonTable.importProfileFromString(input)
				if not ok then
					addonTable.prettyPrint(L["IMPORT_FAILED_WITH_ERROR"] .. error)
				end

				addonTable.fullUpdateBars()
			end
			StaticPopup_Show("SCRB_IMPORT_SETTINGS")
		end,
	})
end