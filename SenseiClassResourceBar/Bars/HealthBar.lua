local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local LSM = addonTable.LSM
local L = addonTable.L

local HealthBarMixin = Mixin({}, addonTable.BarMixin)

------------------------------------------------------------
-- BAR FACTORY
------------------------------------------------------------

function HealthBarMixin:Init(config, parent, frameLevel)
    addonTable.BarMixin.Init(self, config, parent, frameLevel)

    -- ABSORB BAR
	self.AbsorbBar = CreateFrame("StatusBar", nil, self.StatusBar)
	self.AbsorbBar:SetAllPoints()
    self.AbsorbBar:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "SCRB FG Solid"))
	self.AbsorbBar:SetFrameLevel(self.StatusBar:GetFrameLevel() + 1)
    self.AbsorbBar:Hide()

    self.AbsorbBar:GetStatusBarTexture():AddMaskTexture(self.Mask)

    -- HEAL ABSORB BAR
	self.HealAbsorbBar = CreateFrame("StatusBar", nil, self.StatusBar)
	self.HealAbsorbBar:SetAllPoints()
    self.HealAbsorbBar:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "SCRB FG Solid"))
	self.HealAbsorbBar:SetFrameLevel(self.StatusBar:GetFrameLevel() + 1)
    self.HealAbsorbBar:Hide()

    self.HealAbsorbBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
end

------------------------------------------------------------
-- GETTERS
------------------------------------------------------------

function HealthBarMixin:GetBarColor()
    local playerClass = select(2, UnitClass("player"))

    local data = self:GetData()

    local color = addonTable:GetOverrideHealthBarColor()

    if data and data.useClassColor == true then
        local r, g, b = GetClassColor(playerClass)
        return { r = r, g = g, b = b, a = color.a }
    else
        return color
    end
end

function HealthBarMixin:GetResource()
    return "HEALTH"
end

function HealthBarMixin:GetResourceValue()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")
    if max <= 0 then return nil, nil end

    return max, current
end

function HealthBarMixin:GetTagValues(_, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    -- Pre-compute values instead of creating closures for better performance
    local currentStr = string.format("%s", AbbreviateNumbers(current))
    local percentStr = string.format(pFormat, UnitHealthPercent("player", true, CurveConstants.ScaleTo100))
    local maxStr = string.format("%s", AbbreviateNumbers(max))

    return {
        ["[current]"] = function() return currentStr end,
        ["[percent]"] = function() return percentStr end,
        ["[max]"] = function() return maxStr end,
    }
end

function HealthBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self.Frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self.Frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.Frame:RegisterEvent("PET_BATTLE_OPENING_START")
    self.Frame:RegisterEvent("PET_BATTLE_CLOSE")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        self.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

	-- Create the global click-casting registry if it doesn't exist
    if not ClickCastFrames then ClickCastFrames = {} end

    if self.Frame:IsProtected() then
        self:ApplyMouseSettings()
        self._mouseUpdatePending = false
        self.Frame:SetAttribute("unit", "player")
        self.Frame:SetAttribute("*type1", "target")
        self.Frame:SetAttribute("*type2", "togglemenu")
        self.Frame.menu = function(frame)
            UnitPopup_ShowMenu(frame, "PLAYER", "player")
        end

        if not self._registerFrameOnShowAndHide then
            self.Frame:HookScript("OnShow", function()
                self:OnShow()
            end)

            self.Frame:HookScript("OnHide", function()
                self:OnHide()
            end)
            self._registerFrameOnShowAndHide = true
        end
    end
end

function HealthBarMixin:OnLayoutChange()
    self:ApplyMouseSettings()
end

function HealthBarMixin:OnEvent(event, ...)
    local unit = ...
    self._curEvent = event

    if event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        RunNextFrame(function() self:ApplyVisibilitySettings() end)
        self:ApplyLayout(nil, true)
        self:UpdateDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then

            self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
            self:ApplyLayout(nil, true)
            self:UpdateDisplay()

    end

    if self.Frame:IsProtected() then
        if event == "PLAYER_ENTERING_WORLD" then
            self:ApplyMouseSettings()
        elseif event == "PLAYER_REGEN_ENABLED" and self._mouseUpdatePending then
            self:ApplyMouseSettings()
        end
    end
end

------------------------------------------------------------
-- DISPLAY related methods
------------------------------------------------------------

function HealthBarMixin:UpdateDisplay(layoutName, force)
    if not self:IsShown() and not force then return end

    local data = self:GetData(layoutName)
    if not data then return end

    self._currentAbsorb = UnitGetTotalAbsorbs("player") or 0
    if self.AbsorbBar:IsShown() then
        self.AbsorbBar:SetMinMaxValues(0, select(2, self.StatusBar:GetMinMaxValues()), data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)

        if LEM:IsInEditMode() then
            self.AbsorbBar:SetValue(UnitHealthMax("player") * 0.15)
        else
            self.AbsorbBar:SetValue(self._currentAbsorb, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
        end
    end

    self._currentHealAbsorb = UnitGetTotalHealAbsorbs("player") or 0
    if self.HealAbsorbBar:IsShown() then
        self.HealAbsorbBar:SetMinMaxValues(0, select(2, self.StatusBar:GetMinMaxValues()), data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)

        if LEM:IsInEditMode() then
            self.HealAbsorbBar:SetValue(UnitHealthMax("player") * 0.15)
        else
            self.HealAbsorbBar:SetValue(self._currentHealAbsorb, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
        end
    end

    addonTable.BarMixin.UpdateDisplay(self, layoutName, force)
end

------------------------------------------------------------
-- VISIBILITY related methods
------------------------------------------------------------

function HealthBarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    self:HideBlizzardPlayerContainer(layoutName, data)

    if self.Frame:IsProtected() then
        self:RegisterSecureVisibility()
    else
        addonTable.BarMixin.ApplyVisibilitySettings(self, layoutName, inCombat)
    end

    self:ApplyTextVisibilitySettings(layoutName, data)
end

function HealthBarMixin:ApplyMouseSettings()
    if not self.Frame:IsProtected() then return end

    local data = self:GetData()
    local shouldEnable = data.enableHealthBarMouseInteraction == nil and self.defaults.enableHealthBarMouseInteraction or data.enableHealthBarMouseInteraction

    if InCombatLockdown() then
        self._mouseUpdatePending = true
        return -- defer until PLAYER_REGEN_ENABLED
    end

    -- Apply
    self.Frame:EnableMouse(shouldEnable)
    if shouldEnable then
        self.Frame:RegisterForClicks("AnyUp")
    else
        self.Frame:RegisterForClicks()
    end
    self._mouseUpdatePending = false

    -- Enable click-casting or not, this is for third-party and not Blizzard one
    if shouldEnable then
        ClickCastFrames[self.Frame] = true
    else
        ClickCastFrames[self.Frame] = nil
    end
end

function HealthBarMixin:RegisterSecureVisibility()
    if not self.Frame:IsProtected() then return end
    if InCombatLockdown() then return end

    -- Don't hide in Edit Mode, unless config disables it
    if LEM:IsInEditMode() then
        local conditional = "show"
        if type(self.config.allowEditPredicate) == "function" and self.config.allowEditPredicate() == false then
            conditional = "hide"
        end
        RegisterAttributeDriver(self.Frame, "state-visibility", conditional)
        return
    end

    local data = self:GetData()
    local conditions = { "[petbattle] hide" } -- Always hide in Pet Battles

    -- Hide based on role
    local spec = C_SpecializationInfo.GetSpecialization()
    local role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))
    if data.hideHealthOnRole and data.hideHealthOnRole[role] then
        table.insert(conditions, "hide")
    end

    -- Hide while mounted or in vehicle (or druid travel/mount form)
    if data.hideWhileMountedOrVehicule then
        local playerClass = select(2, UnitClass("player"))
        local hideForms = {}
        if playerClass == "DRUID" then
            local TRAVEL_FORM = 783
            local MOUNT_FORM  = 210053

            for i = 1, GetNumShapeshiftForms() do
                local spellID = select(4, GetShapeshiftFormInfo(i))
                if spellID == TRAVEL_FORM or spellID == MOUNT_FORM then
                    table.insert(hideForms, "[form:" .. i .. "]")
                end
            end
        end

        local conditionString = "[mounted][vehicleui][possessbar][overridebar]"
        if #hideForms > 0 then
            conditionString = conditionString .. table.concat(hideForms)
        end

        table.insert(conditions, conditionString .. " hide")
    end

    local setting = data.barVisible
    if setting == "Always Visible" then table.insert(conditions, "show")
    elseif setting == "Hidden" then table.insert(conditions, "hide")
    elseif setting == "In Combat" then table.insert(conditions, "[combat] show; hide")
    elseif setting == "Has Target Selected" then table.insert(conditions, "[@target, exists] show; hide")
    elseif setting == "Has Target Selected OR In Combat" then table.insert(conditions, "[combat][@target, exists] show; hide")
    else table.insert(conditions, "show") end

    RegisterAttributeDriver(self.Frame, "state-visibility", table.concat(conditions, "; "))
end

function HealthBarMixin:HideBlizzardPlayerContainer(layoutName, data)
    -- MSUF compatibility
    if C_AddOns.IsAddOnLoaded("MidnightSimpleUnitFrames") then return end
    if InCombatLockdown() then return end

    data = data or self:GetData(layoutName)
    if not data then return end

    if PlayerFrame then
        if data.hideBlizzardPlayerContainerUi and not LEM:IsInEditMode() then
            RegisterAttributeDriver(PlayerFrame, "state-visibility", "hide")
            RegisterAttributeDriver(PlayerFrame, "alpha", "0")
            PlayerFrame.SCRB_forcedHidden = true
        elseif PlayerFrame.SCRB_forcedHidden then
            UnregisterAttributeDriver(PlayerFrame, "state-visibility")
            UnregisterAttributeDriver(PlayerFrame, "alpha")
            PlayerFrame:Show()
            PlayerFrame:SetAlpha(1)
            PlayerFrame.SCRB_forcedHidden = nil
        end
    end
end

------------------------------------------------------------
-- LAYOUT related methods
------------------------------------------------------------

function HealthBarMixin:ApplyLayout(layoutName, force)
    addonTable.BarMixin.ApplyLayout(self, layoutName, force)

    self:ApplyAbsorbBarSettings()
    self:ApplyHealAbsorbBarSettings()
end

function HealthBarMixin:ApplyMaskAndBorderSettings(layoutName, data)
    addonTable.BarMixin.ApplyMaskAndBorderSettings(self, layoutName, data)

    if self.Mask then
        self.AbsorbBar:GetStatusBarTexture():RemoveMaskTexture(self.Mask)
        self.HealAbsorbBar:GetStatusBarTexture():RemoveMaskTexture(self.Mask)
    end

    self.AbsorbBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
    self.HealAbsorbBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
end

function HealthBarMixin:ApplyAbsorbBarSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    if (data.absorbBarEnabled == nil and not defaults.absorbBarEnabled) or (data.absorbBarEnabled == false) then
        self.AbsorbBar:Hide()
        return
    else
        self.AbsorbBar:Show()
    end

    local absorbBarStyleName = data.absorbBarStyle or defaults.absorbBarStyle
    local absorbBarTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, absorbBarStyleName)

    if absorbBarTexture then
        self.AbsorbBar:SetStatusBarTexture(absorbBarTexture)
    end

	self.AbsorbBar:ClearAllPoints()
    self.AbsorbBar:SetOrientation(self.StatusBar:GetOrientation())

    local position = data.absorbBarPosition or defaults.absorbBarPosition
    if position == "Fixed" then
        self.AbsorbBar:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT")
        self.AbsorbBar:SetPoint("BOTTOMRIGHT", self.StatusBar, "BOTTOMRIGHT")
        self.AbsorbBar:SetReverseFill(self.StatusBar:GetReverseFill())
    elseif position == "Reversed" then
        self.AbsorbBar:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT")
        self.AbsorbBar:SetPoint("BOTTOMRIGHT", self.StatusBar, "BOTTOMRIGHT")
        self.AbsorbBar:SetReverseFill(not self.StatusBar:GetReverseFill())
    elseif position == "Attach To Health" then
        if self.StatusBar:GetOrientation() == "VERTICAL" then
			self.AbsorbBar:SetPoint("LEFT", self.StatusBar, "LEFT")
			self.AbsorbBar:SetPoint("RIGHT", self.StatusBar, "RIGHT")

            if self.StatusBar:GetReverseFill() then
				self.AbsorbBar:SetPoint("TOP", self.StatusBar:GetStatusBarTexture(), "BOTTOM")
            else
				self.AbsorbBar:SetPoint("BOTTOM", self.StatusBar:GetStatusBarTexture(), "TOP")
            end

            self.AbsorbBar:SetHeight(self.StatusBar:GetHeight())
        else
            self.AbsorbBar:SetPoint("TOP", self.StatusBar, "TOP")
            self.AbsorbBar:SetPoint("BOTTOM", self.StatusBar, "BOTTOM")

            if self.StatusBar:GetReverseFill() then
				self.AbsorbBar:SetPoint("RIGHT", self.StatusBar:GetStatusBarTexture(), "LEFT")
            else
                self.AbsorbBar:SetPoint("LEFT", self.StatusBar:GetStatusBarTexture(), "RIGHT")
            end

            self.AbsorbBar:SetWidth(self.StatusBar:GetWidth())
        end

        self.AbsorbBar:SetReverseFill(self.StatusBar:GetReverseFill())
    end

    local color = data.absorbBarColor or defaults.absorbBarColor
    self.AbsorbBar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1);
end

function HealthBarMixin:ApplyHealAbsorbBarSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    if (data.healAbsorbBarEnabled == nil and not defaults.healAbsorbBarEnabled) or (data.healAbsorbBarEnabled == false) then
        self.HealAbsorbBar:Hide()
        return
    else
        self.HealAbsorbBar:Show()
    end

    local healAbsorbBarStyleName = data.healAbsorbBarStyle or defaults.healAbsorbBarStyle
    local healAbsorbBarTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, healAbsorbBarStyleName)

    if healAbsorbBarTexture then
        self.HealAbsorbBar:SetStatusBarTexture(healAbsorbBarTexture)
    end

	self.HealAbsorbBar:ClearAllPoints()
    self.HealAbsorbBar:SetOrientation(self.StatusBar:GetOrientation())

    local position = data.healAbsorbBarPosition or defaults.healAbsorbBarPosition
    if position == "Fixed" then
        self.HealAbsorbBar:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT")
        self.HealAbsorbBar:SetPoint("BOTTOMRIGHT", self.StatusBar, "BOTTOMRIGHT")
        self.HealAbsorbBar:SetReverseFill(self.StatusBar:GetReverseFill())
    elseif position == "Reversed" then
        self.HealAbsorbBar:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT")
        self.HealAbsorbBar:SetPoint("BOTTOMRIGHT", self.StatusBar, "BOTTOMRIGHT")
        self.HealAbsorbBar:SetReverseFill(not self.StatusBar:GetReverseFill())
    elseif position == "Attach To Health" then
        if self.StatusBar:GetOrientation() == "VERTICAL" then
            self.HealAbsorbBar:SetPoint("LEFT", self.StatusBar, "LEFT")
            self.HealAbsorbBar:SetPoint("RIGHT", self.StatusBar, "RIGHT")

            if self.StatusBar:GetReverseFill() then
                self.HealAbsorbBar:SetPoint("BOTTOM", self.StatusBar:GetStatusBarTexture(), "TOP")
            else
                self.HealAbsorbBar:SetPoint("TOP", self.StatusBar:GetStatusBarTexture(), "BOTTOM")
            end

            self.HealAbsorbBar:SetHeight(self.StatusBar:GetHeight())
        else
            self.HealAbsorbBar:SetPoint("TOP", self.StatusBar, "TOP")
            self.HealAbsorbBar:SetPoint("BOTTOM", self.StatusBar, "BOTTOM")

            if self.StatusBar:GetReverseFill() then
                self.HealAbsorbBar:SetPoint("LEFT", self.StatusBar:GetStatusBarTexture(), "LEFT")
            else
                self.HealAbsorbBar:SetPoint("RIGHT", self.StatusBar:GetStatusBarTexture(), "RIGHT")
            end

            self.HealAbsorbBar:SetWidth(self.StatusBar:GetWidth())
        end

        self.HealAbsorbBar:SetReverseFill(not self.StatusBar:GetReverseFill())
    end

    local color = data.healAbsorbBarColor or defaults.healAbsorbBarColor
    self.HealAbsorbBar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1);
end

addonTable.HealthBarMixin = HealthBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.HealthBar = {
    mixin = addonTable.HealthBarMixin,
    dbName = "healthBarDB",
    editModeName = L["HEALTH_BAR_EDIT_MODE_NAME"],
    frameName = "HealthBar",
    frameLevel = 0,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 40,
        barVisible = "Hidden",
        hideHealthOnRole = {},
        hideBlizzardPlayerContainerUi = false,
        useClassColor = true,
        enableHealthBarMouseInteraction = false,
        absorbBarEnabled = false,
        absorbBarPosition = "Attach To Health",
        absorbBarStyle = "SCRB FG Absorb",
        absorbBarColor = {r = 1, g = 1, b = 1, a = 1},
        healAbsorbBarEnabled = false,
        healAbsorbBarPosition = "Attach To Health",
        healAbsorbBarStyle = "SCRB FG Solid",
        healAbsorbBarColor = {r = 0, g = 0, b = 0, a = 0.5},
    },
    lemSettings = function(bar, defaults)
        local config = bar:GetConfig()
        local dbName = config.dbName

        return {
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 103,
                name = L["HIDE_HEALTH_ON_ROLE"],
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideHealthOnRole,
                values = addonTable.availableRoleOptions,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole) or defaults.hideHealthOnRole
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole = value
                    bar:ApplyVisibilitySettings(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 106,
                name = L["HIDE_BLIZZARD_UI"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardPlayerContainerUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardPlayerContainerUi ~= nil then
                        return data.hideBlizzardPlayerContainerUi
                    else
                        return defaults.hideBlizzardPlayerContainerUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardPlayerContainerUi = value
                    bar:HideBlizzardPlayerContainer(layoutName)

                    StaticPopup_Show("SCRB_RELOADUI")
                end,
                tooltip = L["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"],
            },
            -- {
            --     parentId = L["CATEGORY_BAR_VISIBILITY"],
            --     order = 107,
            --     name = L["ENABLE_HP_BAR_MOUSE_INTERACTION"],
            --     kind = LEM.SettingType.Checkbox,
            --     default = defaults.enableHealthBarMouseInteraction,
            --     get = function(layoutName)
            --         local data = SenseiClassResourceBarDB[dbName][layoutName]
            --         if data and data.enableHealthBarMouseInteraction ~= nil then
            --             return data.enableHealthBarMouseInteraction
            --         else
            --             return defaults.enableHealthBarMouseInteraction
            --         end
            --     end,
            --     set = function(layoutName, value)
            --         SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
            --         SenseiClassResourceBarDB[dbName][layoutName].enableHealthBarMouseInteraction = value
            --         bar:ApplyVisibilitySettings(layoutName)
            --     end,
            --     tooltip = L["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"],
            -- },
            {
                parentId = L["CATEGORY_BAR_STYLE"],
                order = 401,
                name = L["USE_CLASS_COLOR"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.useClassColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useClassColor ~= nil then
                        return data.useClassColor
                    else
                        return defaults.useClassColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useClassColor = value
                    bar:ApplyLayout(layoutName)
                end,
            },
            {
                order = 500,
                name = L["CATEGORY_ABSORB_BAR_STYLE"],
                kind = LEM.SettingType.Collapsible,
                id = L["CATEGORY_ABSORB_BAR_STYLE"],
                defaultCollapsed = true,
            },
            {
                parentId = L["CATEGORY_ABSORB_BAR_STYLE"],
                order = 501,
                name = L["ENABLE"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.absorbBarEnabled,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.absorbBarEnabled ~= nil then
                        return data.absorbBarEnabled
                    else
                        return defaults.absorbBarEnabled
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].absorbBarEnabled = value
                    bar:ApplyAbsorbBarSettings(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_ABSORB_BAR_STYLE"],
                order = 502,
                name = L["ABSORB_BAR_POSITION"],
                kind = LEM.SettingType.Dropdown,
                default = defaults.absorbBarPosition,
                useOldStyle = true,
                values = addonTable.availableAbsorbBarPositions,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].absorbBarPosition) or defaults.absorbBarPosition
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].absorbBarPosition = value
                    bar:ApplyAbsorbBarSettings(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data.absorbBarEnabled == true
                end,
            },
            {
                parentId = L["CATEGORY_ABSORB_BAR_STYLE"],
                order = 503,
                name = L["BAR_TEXTURE"],
                kind = LEM.SettingType.DropdownColor,
                default = defaults.absorbBarStyle,
                useOldStyle = true,
                height = 200,
                generator = function(dropdown, rootDescription, settingObject)
                    dropdown.texturePool = {}

                    local layoutName = LEM.GetActiveLayoutName() or "Default"
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    if not data then return end

                    if not dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked then
                        hooksecurefunc(dropdown, "OnMenuClosed", function()
                            for _, texture in pairs(dropdown.texturePool) do
                                texture:Hide()
                            end
                        end)
                        dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked = true
                    end

                    dropdown:SetDefaultText(settingObject.get(layoutName))

                    local textures = LSM:HashTable(LSM.MediaType.STATUSBAR)
                    local sortedTextures = {}
                    for textureName in pairs(textures) do
                        table.insert(sortedTextures, textureName)
                    end
                    table.sort(sortedTextures)

                    for index, textureName in ipairs(sortedTextures) do
                        local texturePath = textures[textureName]

                        local button = rootDescription:CreateButton(textureName, function()
                            dropdown:SetDefaultText(textureName)
                            settingObject.set(layoutName, textureName)
                        end)

                        if texturePath then
                            button:AddInitializer(function(self)
                                local textureStatusBar = dropdown.texturePool[index]
                                if not textureStatusBar then
                                    textureStatusBar = dropdown:CreateTexture(nil, "BACKGROUND")
                                    dropdown.texturePool[index] = textureStatusBar
                                end

                                textureStatusBar:SetParent(self)
                                textureStatusBar:SetAllPoints(self)
                                textureStatusBar:SetTexture(texturePath)

                                textureStatusBar:Show()
                            end)
                        end
                    end
                end,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].absorbBarStyle) or defaults.absorbBarStyle
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data and data.absorbBarColor or defaults.absorbBarColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].absorbBarStyle = value
                    bar:ApplyAbsorbBarSettings(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].absorbBarColor = value
                    bar:ApplyAbsorbBarSettings(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data.absorbBarEnabled == true
                end,
            },
            {
                order = 550,
                name = L["CATEGORY_HEAL_ABSORB_BAR_STYLE"],
                kind = LEM.SettingType.Collapsible,
                id = L["CATEGORY_HEAL_ABSORB_BAR_STYLE"],
                defaultCollapsed = true,
            },
            {
                parentId = L["CATEGORY_HEAL_ABSORB_BAR_STYLE"],
                order = 551,
                name = L["ENABLE"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.healAbsorbBarEnabled,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.healAbsorbBarEnabled ~= nil then
                        return data.healAbsorbBarEnabled
                    else
                        return defaults.healAbsorbBarEnabled
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].healAbsorbBarEnabled = value
                    bar:ApplyHealAbsorbBarSettings(layoutName)
                end,
            },
            {
                parentId = L["CATEGORY_HEAL_ABSORB_BAR_STYLE"],
                order = 552,
                name = L["HEAL_ABSORB_BAR_POSITION"],
                kind = LEM.SettingType.Dropdown,
                default = defaults.healAbsorbBarPosition,
                useOldStyle = true,
                values = addonTable.availableHealAbsorbBarPositions,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].healAbsorbBarPosition) or defaults.healAbsorbBarPosition
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].healAbsorbBarPosition = value
                    bar:ApplyHealAbsorbBarSettings(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data.healAbsorbBarEnabled == true
                end,
            },
            {
                parentId = L["CATEGORY_HEAL_ABSORB_BAR_STYLE"],
                order = 553,
                name = L["BAR_TEXTURE"],
                kind = LEM.SettingType.DropdownColor,
                default = defaults.healAbsorbBarStyle,
                useOldStyle = true,
                height = 200,
                generator = function(dropdown, rootDescription, settingObject)
                    dropdown.texturePool = {}

                    local layoutName = LEM.GetActiveLayoutName() or "Default"
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    if not data then return end

                    if not dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked then
                        hooksecurefunc(dropdown, "OnMenuClosed", function()
                            for _, texture in pairs(dropdown.texturePool) do
                                texture:Hide()
                            end
                        end)
                        dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked = true
                    end

                    dropdown:SetDefaultText(settingObject.get(layoutName))

                    local textures = LSM:HashTable(LSM.MediaType.STATUSBAR)
                    local sortedTextures = {}
                    for textureName in pairs(textures) do
                        table.insert(sortedTextures, textureName)
                    end
                    table.sort(sortedTextures)

                    for index, textureName in ipairs(sortedTextures) do
                        local texturePath = textures[textureName]

                        local button = rootDescription:CreateButton(textureName, function()
                            dropdown:SetDefaultText(textureName)
                            settingObject.set(layoutName, textureName)
                        end)

                        if texturePath then
                            button:AddInitializer(function(self)
                                local textureStatusBar = dropdown.texturePool[index]
                                if not textureStatusBar then
                                    textureStatusBar = dropdown:CreateTexture(nil, "BACKGROUND")
                                    dropdown.texturePool[index] = textureStatusBar
                                end

                                textureStatusBar:SetParent(self)
                                textureStatusBar:SetAllPoints(self)
                                textureStatusBar:SetTexture(texturePath)

                                textureStatusBar:Show()
                            end)
                        end
                    end
                end,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].healAbsorbBarStyle) or defaults.healAbsorbBarStyle
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data and data.healAbsorbBarColor or defaults.healAbsorbBarColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].healAbsorbBarStyle = value
                    bar:ApplyHealAbsorbBarSettings(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[config.dbName][layoutName].healAbsorbBarColor = value
                    bar:ApplyHealAbsorbBarSettings(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                    return data.healAbsorbBarEnabled == true
                end,
            },
        }
    end,
}