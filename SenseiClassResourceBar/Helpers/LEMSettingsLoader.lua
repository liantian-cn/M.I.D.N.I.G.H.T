local _, addonTable = ...

local LSM = addonTable.LSM or LibStub("LibSharedMedia-3.0")
local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local LEMSettingsLoaderMixin = {}

local function BuildLemSettings(bar, defaults)
    local config = bar:GetConfig()

    local uiWidth, uiHeight = GetPhysicalScreenSize()
    uiWidth = uiWidth / 2
    uiHeight = uiHeight / 2

    local settings = {
        {
            order = 100,
            name = L["CATEGORY_BAR_VISIBILITY"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_BAR_VISIBILITY"],
        },
        {
            parentId = L["CATEGORY_BAR_VISIBILITY"],
            order = 101,
            name = L["BAR_VISIBLE"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.barVisible,
            useOldStyle = true,
            values = addonTable.availableBarVisibilityOptions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].barVisible) or defaults.barVisible
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].barVisible = value
            end,
        },
        {
            parentId = L["CATEGORY_BAR_VISIBILITY"],
            order = 102,
            name = L["BAR_STRATA"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.barStrata,
            useOldStyle = true,
            values = addonTable.availableBarStrataOptions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].barStrata) or defaults.barStrata
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].barStrata = value
                bar:ApplyLayout(layoutName)
            end,
            tooltip = L["BAR_STRATA_TOOLTIP"],
        },
        {
            parentId = L["CATEGORY_BAR_VISIBILITY"],
            order = 105,
            name = L["HIDE_WHILE_MOUNTED_OR_VEHICULE"],
            kind = LEM.SettingType.Checkbox,
            default = defaults.hideWhileMountedOrVehicule,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.hideWhileMountedOrVehicule ~= nil then
                    return data.hideWhileMountedOrVehicule
                else
                    return defaults.hideWhileMountedOrVehicule
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].hideWhileMountedOrVehicule = value
            end,
            tooltip = L["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"],
        },
        {
            order = 200,
            name = L["CATEGORY_POSITION_AND_SIZE"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_POSITION_AND_SIZE"],
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 201,
            name = L["POSITION"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.positionMode,
            useOldStyle = true,
            values = addonTable.availablePositionModeOptions(config),
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].positionMode) or defaults.positionMode
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].positionMode = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 202,
            name = L["X_POSITION"],
            kind = LEM.SettingType.Slider,
            default = defaults.x,
            minValue = uiWidth * -1,
            maxValue = uiWidth,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.x) or defaults.x
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].x = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 203,
            name = L["Y_POSITION"],
            kind = LEM.SettingType.Slider,
            default = defaults.y,
            minValue = uiHeight * -1,
            maxValue = uiHeight,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.y) or defaults.y
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].y = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 204,
            name = L["RELATIVE_FRAME"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.relativeFrame,
            useOldStyle = true,
            values = addonTable.availableRelativeFrames(config),
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].relativeFrame) or defaults.relativeFrame
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].relativeFrame = value
                -- Need to reset some settings so it does not go somewhere unintended
                SenseiClassResourceBarDB[config.dbName][layoutName].x = defaults.x
                SenseiClassResourceBarDB[config.dbName][layoutName].y = defaults.y
                SenseiClassResourceBarDB[config.dbName][layoutName].point = defaults.point
                SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = defaults.relativePoint
                bar:ApplyLayout(layoutName)
                LEM.internal:RefreshSettingValues({L["X_POSITION"], L["Y_POSITION"], L["ANCHOR_POINT"], L["RELATIVE_POINT"]})
            end,
            tooltip = L["RELATIVE_FRAME_TOOLTIP"],
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 205,
            name = L["ANCHOR_POINT"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.point,
            useOldStyle = true,
            values = addonTable.availableAnchorPoints,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].point) or defaults.point
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].point = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 206,
            name = L["RELATIVE_POINT"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.relativePoint,
            useOldStyle = true,
            values = addonTable.availableRelativePoints,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint) or defaults.relativePoint
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 210,
            kind = LEM.SettingType.Divider,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 211,
            name = L["BAR_SIZE"],
            kind = LEM.SettingType.Slider,
            default = defaults.scale,
            minValue = 0.25,
            maxValue = 2,
            valueStep = 0.01,
            formatter = function(value)
                return string.format("%d%%", addonTable.rounded(value, 2) * 100)
            end,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.scale, 2) or defaults.scale
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].scale = addonTable.rounded(value, 2)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 212,
            name = L["WIDTH_MODE"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.widthMode,
            useOldStyle = true,
            values = addonTable.availableWidthModes,
            get = function(layoutName)
                local widthMode = (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].widthMode) or defaults.widthMode
                return addonTable.availableCustomFrames[widthMode] or widthMode
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].widthMode = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 213,
            name = L["WIDTH"],
            kind = LEM.SettingType.Slider,
            default = defaults.width,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.width) or defaults.width
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].width = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
            isEnabled = function (layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.widthMode == "Manual"
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 214,
            name = L["MINIMUM_WIDTH"],
            kind = LEM.SettingType.Slider,
            default = defaults.minWidth,
            minValue = 0,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.minWidth) or defaults.minWidth
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].minWidth = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
            tooltip = L["MINIMUM_WIDTH_TOOLTIP"],
            isEnabled = function (layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data ~= nil and data.widthMode ~= "Manual"
            end,
        },
        {
            parentId = L["CATEGORY_POSITION_AND_SIZE"],
            order = 215,
            name = L["HEIGHT"],
            kind = LEM.SettingType.Slider,
            default = defaults.height,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.height) or defaults.height
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].height = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 300,
            name = L["CATEGORY_BAR_SETTINGS"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_BAR_SETTINGS"],
            defaultCollapsed = true,
        },
        {
            parentId = L["CATEGORY_BAR_SETTINGS"],
            order = 301,
            name = L["FILL_DIRECTION"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.fillDirection,
            useOldStyle = true,
            values = addonTable.availableFillDirections,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].fillDirection) or defaults.fillDirection
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fillDirection = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_BAR_SETTINGS"],
            order = 302,
            name = L["FASTER_UPDATES"],
            kind = LEM.SettingType.Checkbox,
            default = defaults.fasterUpdates,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.fasterUpdates ~= nil then
                    return data.fasterUpdates
                else
                    return defaults.fasterUpdates
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fasterUpdates = value
                if value then
                    bar:EnableFasterUpdates()
                else
                    bar:DisableFasterUpdates()
                end
            end,
        },
        {
            parentId = L["CATEGORY_BAR_SETTINGS"],
            order = 303,
            name = L["SMOOTH_PROGRESS"],
            kind = LEM.SettingType.Checkbox,
            default = defaults.smoothProgress,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.smoothProgress ~= nil then
                    return data.smoothProgress
                else
                    return defaults.smoothProgress
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].smoothProgress = value
            end,
        },
        {
            order = 400,
            name = L["CATEGORY_BAR_STYLE"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_BAR_STYLE"],
            defaultCollapsed = true,
        },
        {
            parentId = L["CATEGORY_BAR_STYLE"],
            order = 402,
            name = L["BAR_TEXTURE"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.foregroundStyle,
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
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle) or defaults.foregroundStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle = value
                bar:ApplyLayout(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return not data.useResourceAtlas
            end,
        },
        {
            parentId = L["CATEGORY_BAR_STYLE"],
            order = 403,
            name = L["BAR_BACKGROUND"],
            kind = LEM.SettingType.DropdownColor,
            default = defaults.backgroundStyle,
            colorDefault = defaults.backgroundColor,
            useOldStyle = true,
            height = 200,
            generator = function(dropdown, rootDescription, settingObject)
                dropdown.texturePool = {}

                local layoutName = LEM.GetActiveLayoutName() or "Default"
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if not data then return end

                if not dropdown._SCRB_Background_Dropdown_OnMenuClosed_hooked then
                    hooksecurefunc(dropdown, "OnMenuClosed", function()
                        for _, texture in pairs(dropdown.texturePool) do
                            texture:Hide()
                        end
                    end)
                    dropdown._SCRB_Background_Dropdown_OnMenuClosed_hooked = true
                end

                dropdown:SetDefaultText(settingObject.get(layoutName))

                local textures = LSM:HashTable(LSM.MediaType.BACKGROUND)
                local sortedTextures = CopyTable(addonTable.availableBackgroundStyles)
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
                            local textureBackground = dropdown.texturePool[index]
                            if not textureBackground then
                                textureBackground = dropdown:CreateTexture(nil, "BACKGROUND")
                                dropdown.texturePool[index] = textureBackground
                            end

                            textureBackground:SetParent(self)
                            textureBackground:SetAllPoints(self)
                            textureBackground:SetTexture(texturePath)

                            textureBackground:Show()
                        end)
                    end
                end
            end,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle) or defaults.backgroundStyle
            end,
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.backgroundColor or defaults.backgroundColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle = value
                bar:ApplyLayout(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundColor = value
                bar:ApplyBackgroundSettings(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_BAR_STYLE"],
            order = 404,
            name = L["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"],
            kind = LEM.SettingType.Checkbox,
            default = defaults.useStatusBarColorForBackgroundColor,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.useStatusBarColorForBackgroundColor ~= nil then
                    return data.useStatusBarColorForBackgroundColor
                else
                    return defaults.useStatusBarColorForBackgroundColor
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].useStatusBarColorForBackgroundColor = value
                bar:ApplyBackgroundSettings(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_BAR_STYLE"],
            order = 405,
            name = L["BAR_BORDER"],
            kind = LEM.SettingType.DropdownColor,
            default = defaults.maskAndBorderStyle,
            colorDefault = defaults.borderColor,
            useOldStyle = true,
            values = addonTable.availableMaskAndBorderStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle) or defaults.maskAndBorderStyle
            end,
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.borderColor or defaults.borderColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle = value
                bar:ApplyMaskAndBorderSettings(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].borderColor = value
                bar:ApplyMaskAndBorderSettings(layoutName)
            end,
        },
        {
            order = 600,
            name = L["CATEGORY_TEXT_SETTINGS"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_TEXT_SETTINGS"],
            defaultCollapsed = true,
        },
        {
            parentId = L["CATEGORY_TEXT_SETTINGS"],
            order = 601,
            name = L["SHOW_RESOURCE_NUMBER"],
            kind = LEM.SettingType.CheckboxColor,
            default = defaults.showText,
            colorDefault = defaults.textColor,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.showText ~= nil then
                    return data.showText
                else
                    return defaults.showText
                end
            end,
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.textColor or defaults.textColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].showText = value
                bar:ApplyTextVisibilitySettings(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textColor = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_TEXT_SETTINGS"],
            order = 602,
            name = L["RESOURCE_NUMBER_FORMAT"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.textFormat,
            useOldStyle = true,
            values = addonTable.availableTextFormats,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textFormat) or defaults.textFormat
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textFormat = value
                bar:UpdateDisplay(layoutName)
            end,
            tooltip = L["RESOURCE_NUMBER_FORMAT_TOOLTIP"],
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText == true
            end,
        },
        {
            parentId = L["CATEGORY_TEXT_SETTINGS"],
            order = 603,
            name = L["RESOURCE_NUMBER_PRECISION"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.textPrecision,
            useOldStyle = true,
            values = addonTable.availableTextPrecisions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textPrecision) or defaults.textPrecision
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textPrecision = value
                bar:UpdateDisplay(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText and addonTable.textPrecisionAllowedForType[data.textFormat] ~= nil
            end,
        },
        {
            parentId = L["CATEGORY_TEXT_SETTINGS"],
            order = 604,
            name = L["RESOURCE_NUMBER_ALIGNMENT"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.textAlign,
            useOldStyle = true,
            values = addonTable.availableTextAlignmentStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textAlign) or defaults.textAlign
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textAlign = value
                bar:ApplyFontSettings(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText == true
            end,
        },
        {
            order = 700,
            name = L["CATEGORY_FONT"],
            kind = LEM.SettingType.Collapsible,
            id = L["CATEGORY_FONT"],
            defaultCollapsed = true,
        },
        {
            parentId = L["CATEGORY_FONT"],
            order = 701,
            name = L["FONT"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.font,
            useOldStyle = true,
            height = 200,
            generator = function(dropdown, rootDescription, settingObject)
                dropdown.fontPool = {}

                local layoutName = LEM.GetActiveLayoutName() or "Default"
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if not data then return end

                if not dropdown._SCRB_FontFace_Dropdown_OnMenuClosed_hooked then
                    hooksecurefunc(dropdown, "OnMenuClosed", function()
                        for _, fontDisplay in pairs(dropdown.fontPool) do
                            fontDisplay:Hide()
                        end
                    end)
                    dropdown._SCRB_FontFace_Dropdown_OnMenuClosed_hooked = true
                end

                local fonts = LSM:HashTable(LSM.MediaType.FONT)
                local sortedFonts = {}
                for fontName in pairs(fonts) do
                    table.insert(sortedFonts, fontName)
                end
                table.sort(sortedFonts)

                for index, fontName in ipairs(sortedFonts) do
                    local fontPath = fonts[fontName]

                    local button = rootDescription:CreateRadio(fontName, function(d)
                        return d.get(layoutName) == d.value
                    end, function(d)
                        d.set(layoutName, d.value)
                    end, {
                        get = settingObject.get,
                        set = settingObject.set,
                        value = fontPath
                    })

                    button:AddInitializer(function(self)
                        local fontDisplay = dropdown.fontPool[index]
                        if not fontDisplay then
                            fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                            dropdown.fontPool[index] = fontDisplay
                        end

                        self.fontString:Hide()

                        fontDisplay:SetParent(self)
                        fontDisplay:SetPoint("LEFT", self.fontString, "LEFT", 0, 0)
                        local ok = addonTable.setFontStringFont(fontDisplay, fontPath, 12)
                        if not ok then
                            addonTable.setFontStringFont(fontDisplay, defaults.font, 12)
                        end
                        fontDisplay:SetText(fontName)
                        fontDisplay:Show()
                    end)
                end
            end,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].font) or defaults.font
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].font = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_FONT"],
            order = 702,
            name = L["FONT_SIZE"],
            kind = LEM.SettingType.Slider,
            default = defaults.fontSize,
            minValue = 5,
            maxValue = 50,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.fontSize) or defaults.fontSize
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontSize = addonTable.rounded(value)
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            parentId = L["CATEGORY_FONT"],
            order = 703,
            name = L["FONT_OUTLINE"],
            kind = LEM.SettingType.Dropdown,
            default = defaults.fontOutline,
            useOldStyle = true,
            values = addonTable.availableOutlineStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline) or defaults.fontOutline
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
    }

    -- Add config-specific settings
    if config.lemSettings and type(config.lemSettings) == "function" then
        local customSettings = config.lemSettings(bar, defaults)
        for _, setting in ipairs(customSettings) do
            table.insert(settings, setting)
        end
    end

    -- Sort settings by order field
    table.sort(settings, function(a, b)
        local orderA = a.order or 999
        local orderB = b.order or 999
        return orderA < orderB
    end)

    return settings
end

function LEMSettingsLoaderMixin:Init(bar, defaults)
    self.bar = bar
    self.defaults = CopyTable(defaults)

    local frame = bar:GetFrame()
    local config = bar:GetConfig()

    local function OnPositionChanged(frame, layoutName, point, x, y)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
        SenseiClassResourceBarDB[config.dbName][layoutName].point = point
        SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = point
        SenseiClassResourceBarDB[config.dbName][layoutName].x = x
        SenseiClassResourceBarDB[config.dbName][layoutName].y = y
        bar:ApplyLayout(layoutName)
        LEM.internal:RefreshSettingValues({L["X_POSITION"], L["Y_POSITION"]})
    end

    LEM:RegisterCallback("enter", function()
        -- Support for Edit Mode Transparency from BetterBlizzFrames
        if not bar._SCRB_EditModeAlphaSlider_hooked and BBF and BBF.EditModeAlphaSlider then
            BBF.EditModeAlphaSlider:RegisterCallback("OnValueChanged", function(_, value)
                local rounded = math.floor((value / 0.05) + 0.5) * 0.05

                if frame and frame.Selection then
                    frame.Selection:SetAlpha(rounded)
                end
            end, bar._SCRB_EditModeAlphaSlider)

            if BetterBlizzFramesDB and BetterBlizzFramesDB["editModeSelectionAlpha"] then
                BBF.EditModeAlphaSlider:TriggerEvent("OnValueChanged", BetterBlizzFramesDB["editModeSelectionAlpha"])
            end

            bar._SCRB_EditModeAlphaSlider_hooked = true
        end

        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("exit", function()
        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("layout", function(layoutName)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)

        bar:OnLayoutChange(layoutName)
        bar:InitCooldownManagerWidthHook(layoutName)
        bar:InitCustomFrameWidthHook(layoutName)

        RunNextFrame(function() bar:ApplyVisibilitySettings(layoutName) end)
        bar:ApplyLayout(layoutName, true)
        bar:UpdateDisplay(layoutName, true)
    end)

    LEM:RegisterCallback("layoutduplicate", function(_, duplicateIndices, _, _, layoutName)
        local original = LEM:GetLayouts()[duplicateIndices[1]].name
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][original] and CopyTable(SenseiClassResourceBarDB[config.dbName][original]) or CopyTable(defaults)

        bar:InitCooldownManagerWidthHook(layoutName)
        bar:InitCustomFrameWidthHook(layoutName)

        bar:ApplyVisibilitySettings(layoutName)
        bar:ApplyLayout(layoutName, true)
        bar:UpdateDisplay(layoutName, true)
    end)

    LEM:RegisterCallback("layoutrenamed", function(oldLayoutName, newLayoutName)
        if #LEM.internal.layoutNameSnapshot ~= #C_EditMode.GetLayouts().layouts then
            return
        end

        SenseiClassResourceBarDB[config.dbName][newLayoutName] = SenseiClassResourceBarDB[config.dbName][oldLayoutName] and CopyTable(SenseiClassResourceBarDB[config.dbName][oldLayoutName]) or CopyTable(defaults)
        SenseiClassResourceBarDB[config.dbName][oldLayoutName] = nil

        bar:InitCooldownManagerWidthHook(newLayoutName)
        bar:InitCustomFrameWidthHook(newLayoutName)

        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("layoutdeleted", function(_, layoutName)
        SenseiClassResourceBarDB[config.dbName] = SenseiClassResourceBarDB[config.dbName] or {}
        SenseiClassResourceBarDB[config.dbName][layoutName] = nil

        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:AddFrame(frame, OnPositionChanged, defaults)
end

function LEMSettingsLoaderMixin:LoadSettings()
    local frame = self.bar:GetFrame()

    LEM:AddFrameSettings(frame, BuildLemSettings(self.bar, self.defaults))

    local buttonSettings = {
        {
            text = L["POWER_COLOR_SETTINGS"],
            click = function() -- Cannot directly close Edit Mode because it is protected
                if not addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit then
                    addonTable.prettyPrint(L["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"])
                end

                addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = true

                if not addonTable._SCRB_EditModeManagerFrame_OnHide_hooked then

                    EditModeManagerFrame:HookScript("OnHide", function()
                        if addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit == true then
                            C_Timer.After(0.1, function ()
                                Settings.OpenToCategory(addonTable.rootSettingsCategory:GetID())
                            end)
                            addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = false
                        end
                    end)

                    addonTable._SCRB_EditModeManagerFrame_OnHide_hooked = true
                end
            end
        },
        {
            text = L["EXPORT_BAR"],
            click = function()
                local exportString = addonTable.exportBarAsString(self.bar:GetConfig().dbName)
                if not exportString then
                    addonTable.prettyPrint(L["EXPORT_FAILED"])
                    return
                end
                StaticPopupDialogs["SCRB_EXPORT_SETTINGS"] = StaticPopupDialogs["SCRB_EXPORT_SETTINGS"]
                StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
                    self:SetFrameStrata("TOOLTIP")
                    local editBox = self.editBox or self:GetEditBox()
                    editBox:SetText(exportString)
                    editBox:HighlightText()
                    editBox:SetFocus()
                end
                StaticPopup_Show("SCRB_EXPORT_SETTINGS")
            end,
        },
        {
            text = L["IMPORT_BAR"],
            click = function()
                local dbName = self.bar:GetConfig().dbName
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"] = StaticPopupDialogs["SCRB_IMPORT_SETTINGS"]
                
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnAccept = function(self)
                    local editBox = self.editBox or self:GetEditBox()
                    local input = editBox:GetText() or ""

                    local ok, error = addonTable.importBarAsString(input, dbName)
                    if not ok then
					    addonTable.prettyPrint(L["IMPORT_FAILED_WITH_ERROR"] .. error)
                    end

                    addonTable.fullUpdateBars()
                    LEM.internal:RefreshSettingValues()
                end
                StaticPopup_Show("SCRB_IMPORT_SETTINGS")
            end
        }
    }

    if LEM.AddFrameSettingsButtons then
        LEM:AddFrameSettingsButtons(frame, buttonSettings)
    else
        for _, buttonSetting in ipairs(buttonSettings) do
            LEM:AddFrameSettingsButton(frame, buttonSetting)
        end
    end
end

addonTable.LEMSettingsLoaderMixin = LEMSettingsLoaderMixin