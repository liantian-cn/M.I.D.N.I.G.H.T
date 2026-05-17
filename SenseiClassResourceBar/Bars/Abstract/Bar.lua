local _, addonTable = ...

local LSM = addonTable.LSM or LibStub("LibSharedMedia-3.0")
local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

------------------------------------------------------------
-- YOU SHOULD NOT USE DIRECTLY THIS MIXIN -- YOU NEED TO OVERWRITE SOME METHODS
------------------------------------------------------------

local BarMixin = {}

------------------------------------------------------------
-- BAR FACTORY
------------------------------------------------------------

function BarMixin:Init(config, parent, frameLevel)
    local Frame = CreateFrame(config.frameType or "Frame", config.frameName or "", parent or UIParent, config.frameTemplate or nil)
    Frame:SetClampedToScreen(true)

    Frame:SetFrameLevel(frameLevel)
    self.config = config
    self.barName = Frame:GetName()
    Frame.editModeName = config.editModeName

    local defaults = CopyTable(addonTable.commonDefaults)
    for k, v in pairs(self.config.defaultValues or {}) do
        defaults[k] = v
    end
    self.defaults = defaults

    -- BACKGROUND
    self.BackgroundFrame = CreateFrame("Frame", nil, Frame)
    self.BackgroundFrame:SetAllPoints()
    self.BackgroundFrame:SetClipsChildren(true)
    self.Background = self.BackgroundFrame:CreateTexture(nil, "BACKGROUND")
    self.Background:SetAllPoints()
    self.Background:SetColorTexture(0, 0, 0, 0.5)

    -- STATUS BAR
    self.StatusBar = CreateFrame("StatusBar", nil, self.BackgroundFrame)
    self.StatusBar:SetAllPoints()
    self.StatusBar:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "SCRB FG Fade Left"))
    self.StatusBar:SetFrameLevel(self.BackgroundFrame:GetFrameLevel() + 1)
    self.StatusBar:SetClipsChildren(true)

    -- MASK
    self.Mask = self.BackgroundFrame:CreateMaskTexture()
    self.Mask:SetAllPoints()
    self.Mask:SetTexture([[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\white.png]])

    self.StatusBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
    self.Background:AddMaskTexture(self.Mask)

    -- BORDER
    self.BorderFrame = CreateFrame("Frame", nil, Frame)
    self.BorderFrame:SetAllPoints()
    self.BorderFrame:SetFrameLevel(self.StatusBar:GetFrameLevel())
    self.BorderFrame:SetClipsChildren(true)
    self.Border = self.BorderFrame:CreateTexture(nil, "OVERLAY")
    self.Border:SetAllPoints()
    self.Border:SetBlendMode("BLEND")
    self.Border:SetVertexColor(0, 0, 0)
    self.Border:Hide()

    -- TEXT FRAME
    self.TextFrame = CreateFrame("Frame", nil, Frame)
    self.TextFrame:SetAllPoints()
    self.TextFrame:SetFrameLevel(self.BorderFrame:GetFrameLevel())

    self.TextValue = self.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.TextValue:SetPoint("CENTER", self.TextFrame, "CENTER", 0, 0)
    self.TextValue:SetJustifyH("CENTER")
    self.TextValue:SetFormattedText("")

    -- STATE
    self.smoothEnabled = false
    self.fasterUpdates = false

    -- Fragmented powers (Runes, Essences) specific visual elements
    self.FragmentedPowerBars = {}
    self.FragmentedPowerBarTexts = {}

    -- Performance optimizations: pre-allocated tables
    self._displayOrder = {}
    self._cachedTextFormat = nil
    self._cachedTextPattern = nil
    -- Pre-allocate rune tracking tables (for Death Knights)
    self._runeReadyList = {}
    self._runeCdList = {}
    -- Pre-allocate rune info structs to avoid per-rune allocations
    self._runeInfoPool = {}
    for i = 1, 6 do
        self._runeInfoPool[i] = { index = 0, remaining = 0, frac = 0 }
    end

    self.Frame = Frame
end

function BarMixin:InitCooldownManagerWidthHook(layoutName)
    local data = self:GetData(layoutName)
    if not data then return nil end

    self._SCRB_Essential_Utility_hook_widthMode = data.widthMode

    local v = _G["EssentialCooldownViewer"]
    if v and not (self._SCRB_Essential_hooked or false) then
        local hookEssentialCooldowns = function(_, width)
            if self._SCRB_Essential_Utility_hook_widthMode ~= "Sync With Essential Cooldowns" then
                return
            end

            -- For some weird reasons, this is triggered with the scale or something ?
            if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
                self:ApplyLayout(nil, true)
            end
        end

        hooksecurefunc(v, "SetSize", hookEssentialCooldowns)
        hooksecurefunc(v, "Show", hookEssentialCooldowns)
        hooksecurefunc(v, "Hide", hookEssentialCooldowns)

        self._SCRB_Essential_hooked = true
    end

    v = _G["UtilityCooldownViewer"]
    if v and not (self._SCRB_Utility_hooked or false) then
        local hookUtilityCooldowns = function(width)
            if self._SCRB_Essential_Utility_hook_widthMode ~= "Sync With Utility Cooldowns" then
                return
            end

            if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
                self:ApplyLayout(nil, true)
            end
        end

        hooksecurefunc(v, "SetSize", hookUtilityCooldowns)
        hooksecurefunc(v, "Show", hookUtilityCooldowns)
        hooksecurefunc(v, "Hide", hookUtilityCooldowns)

        self._SCRB_Utility_hooked = true
    end

    v = _G["BuffIconCooldownViewer"]
    if v and not (self._SCRB_tBuffs_hooked or false) then
        local hookTrackedBuffs = function(width)
            if self._SCRB_Tracked_Buff_hook_widthMode ~= "Sync With Tracked Buffs" then
                return
            end

            if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
                self:ApplyLayout(nil, true)
            end
        end

        hooksecurefunc(v, "SetSize", hookTrackedBuffs)
        hooksecurefunc(v, "Show", hookTrackedBuffs)
        hooksecurefunc(v, "Hide", hookTrackedBuffs)

        self._SCRB_tBuffs_hooked = true
    end
end

function BarMixin:InitCustomFrameWidthHook(layoutName)
    local data = self:GetData(layoutName)
    if not data then return nil end

    self._SCRB_Custom_Frames_hooked = self._SCRB_Custom_Frames_hooked or {}
    self._SCRB_Custom_Frame = data.widthMode

    local hookCustomFrame = function(customFrame, width)
        if not self._SCRB_Custom_Frame or not _G[self._SCRB_Custom_Frame] or _G[self._SCRB_Custom_Frame] ~= customFrame then
            return
        end

        if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
            self:ApplyLayout(nil, true)
        end
    end

    local v = _G[data.widthMode]
    if v and not self._SCRB_Custom_Frames_hooked[v] then
        self._SCRB_Custom_Frames_hooked[v] = true

        hooksecurefunc(v, "SetSize", hookCustomFrame)
        hooksecurefunc(v, "SetWidth", hookCustomFrame)
        hooksecurefunc(v, "Show", hookCustomFrame)
        hooksecurefunc(v, "Hide", hookCustomFrame)
    end
end

------------------------------------------------------------
-- FRAME methods
------------------------------------------------------------

function BarMixin:Show()
    self:OnShow()
    self.Frame:Show()
end

function BarMixin:Hide()
    self:OnHide()
    self.Frame:Hide()
end

function BarMixin:OnShow()
end

function BarMixin:OnHide()
end

function BarMixin:IsShown()
    return self.Frame:IsShown()
end

function BarMixin:SetFrameStrata(strata)
    self.Frame:SetFrameStrata(strata)
end

------------------------------------------------------------
-- GETTERs for some properties, should be used outside
------------------------------------------------------------

function BarMixin:GetFrame()
    return self.Frame
end

function BarMixin:GetConfig()
    return self.config
end

function BarMixin:GetData(layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    return SenseiClassResourceBarDB[self.config.dbName][layoutName]
end

------------------------------------------------------------
-- GETTERS -- Need to be redefined as they return dummy data
------------------------------------------------------------

---@param _ string|number|nil The value returned by BarMixin:GetResource()
---@return table { r = int, g = int, b = int, atlasElementName = string|nil, atlas = string|nil, hasClassResourceVariant = bool|nil }
---https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UnitFrame/Mainline/PowerBarColorUtil.lua
function BarMixin:GetBarColor(_)
    return { r = 1, g = 1, b = 1, a = 1 }
end

---@return string|number|nil The resource, can be anything as long as you handle it in BarMixin:GetResourceValue
function BarMixin:GetResource()
    return nil
end

--- @param _ string|number|nil The value returned by BarMixin:GetResource()
--- @return number|nil Max Used for the status bar
--- @return number|nil Value Used for the status bar progression
function BarMixin:GetResourceValue(_)
    return nil, nil
end

--- @param resource string|number The value returned by BarMixin:GetResource()
--- @param max number The max returned by BarMixin:GetResourceValue()
--- @param current number The current returned by BarMixin:GetResourceValue()
--- @param precision number The precision if needed by the tag
--- @return table<string, fun(): string> values A table where keys are the tag (e.g "[current]") and values are functions returning the corresponding value as string
function BarMixin:GetTagValues(resource, max, current, precision)
    return {}
end

function BarMixin:OnLoad()
end

--- @param _ string The new layout
function BarMixin:OnLayoutChange(_)
end

---@param event string
---@param ... any
function BarMixin:OnEvent(event, ...)
end

-- You should handle what to change here too and set self.fasterUpdates to true
function BarMixin:EnableFasterUpdates()
    self.fasterUpdates = true
    if not self._OnUpdateFast then
        self._OnUpdateFast = function(frame, delta)
            frame.elapsed = (frame.elapsed or 0) + delta
            if frame.elapsed >= 0.1 then
                frame.elapsed = 0
                self:UpdateDisplay()
                self._curEvent = nil
            end
        end
    end
    self.Frame:SetScript("OnUpdate", self._OnUpdateFast)
end

-- You should handle what to change here too and set self.fasterUpdates to false
function BarMixin:DisableFasterUpdates()
    self.fasterUpdates = false
    if not self._OnUpdateSlow then
        self._OnUpdateSlow = function(frame, delta)
            frame.elapsed = (frame.elapsed or 0) + delta
            if frame.elapsed >= 0.25 then
                frame.elapsed = 0
                self:UpdateDisplay()
                self._curEvent = nil
            end
        end
    end
    self.Frame:SetScript("OnUpdate", self._OnUpdateSlow)
end

------------------------------------------------------------
-- DISPLAY related methods
------------------------------------------------------------

function BarMixin:GetTextFormat(data, resource)
    if not data then return "" end

    local textFormat = ""
    if (data.showManaAsPercent and resource == Enum.PowerType.Mana) or data.textFormat == "Percent" or data.textFormat == "Percent%" then
        textFormat = "[percent]" .. (data.textFormat == "Percent%" and "%" or "")
    elseif data.textFormat == nil or data.textFormat == "Current" then
        textFormat = "[current]"
    elseif data.textFormat == "Current / Maximum" then
        textFormat = "[current] / [max]"
    elseif data.textFormat == "Current - Percent" or data.textFormat == "Current - Percent%" then
        textFormat = "[current] - [percent]" .. (data.textFormat == "Current - Percent%" and "%" or "")
    end

    return textFormat
end

function BarMixin:UpdateDisplay(layoutName, force)
    if not self:IsShown() and not force then return end

    local data = self:GetData(layoutName)
    if not data then return end

    -- Cache data to avoid redundant GetData() calls

    local resource = self:GetResource()
    if not resource then
        if LEM:IsInEditMode() then
            -- "4" text for edit mode is resource does not exist (e.g. Secondary resource for warrior)
            self.StatusBar:SetMinMaxValues(0, 5)
            self.TextValue:SetFormattedText("4")
            self.StatusBar:SetValue(4)
        end
        return
    end

    local max, current = self:GetResourceValue(resource)
    if not max then
        if not LEM:IsInEditMode() then
            self:Hide()
        end
        return
    end

    local defaults = self.defaults or {}

    self.StatusBar:SetMinMaxValues(0, max, (data.smoothProgress == nil and defaults.smoothProgress or data.smoothProgress) and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
    self.StatusBar:SetValue(current, (data.smoothProgress == nil and defaults.smoothProgress or data.smoothProgress) and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)

    -----------

    if data.showText == true then
        local precision = data.textPrecision and math.max(0, string.len(data.textPrecision or defaults.textPrecision or "") - 3)
        local tagValues = self:GetTagValues(resource, max, current, precision)

        local textFormat = self:GetTextFormat(data, resource)

        -- Cache compiled format to avoid repeated pattern matching
        if self._cachedTextFormat ~= textFormat then
            self._cachedTextFormat = textFormat
            self._cachedTextPattern = {}
            for tag in textFormat:gmatch('%[..-%]+') do
                self._cachedTextPattern[#self._cachedTextPattern + 1] = tag
            end
            self._cachedFormat, self._cachedNum = textFormat:gsub('%%', '%%%%'):gsub('%[..-%]+', '%%s')
        end

        -- Thanks oUF
        local valuesToDisplay = {}
        for i = 1, #self._cachedTextPattern do
            local tag = self._cachedTextPattern[i]
            if tagValues and tagValues[tag] then
                valuesToDisplay[i] = tagValues[tag]()
            else
                valuesToDisplay[i] = ''
            end
        end

        self.TextValue:SetFormattedText(self._cachedFormat, unpack(valuesToDisplay, 1, self._cachedNum))
    end

    if addonTable.fragmentedPowerTypes[resource] then
        self:UpdateFragmentedPowerDisplay(layoutName, data, max)
    end
end

------------------------------------------------------------
-- VISIBILITY related methods
------------------------------------------------------------

function BarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    -- Cannot touch Protected Frame in Combat
    if self.Frame:IsProtected() and InCombatLockdown() then
        return
    end

    -- Don't hide while in edit mode...
    if LEM:IsInEditMode() then
        -- ...Unless config says otherwise
        if type(self.config.allowEditPredicate) == "function" and self.config.allowEditPredicate() == false then
            self:Hide()
            return
        end

        self:Show()
        return
    end

    local resource = self:GetResource()
    if not resource then
        self:Hide()
        return
    end

    local playerClass = select(2, UnitClass("player"))
    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
    local role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))
    local formID = GetShapeshiftFormID()

    -- Not on arcane mage!
    -- Hide mana based on role
    if resource == Enum.PowerType.Mana and data.hideManaOnRole and data.hideManaOnRole[role] and specID ~= 62 then
        self:Hide()
        return
    end

    -- Hide health based on role
    if data.hideHealthOnRole and data.hideHealthOnRole[role] then
        self:Hide()
        return
    end

    -- Hide custom resources (defined as one not represented in the default PlayerFrame)
    if data.hideCustomResources and data.hideCustomResources[resource] then

        self:Hide()
        return
    end

    local isDruidInFlightForm = playerClass == "DRUID" and (formID == DRUID_FLIGHT_FORM or formID == DRUID_TRAVEL_FORM or formID == DRUID_ACQUATIC_FORM)
    if data.hideWhileMountedOrVehicule and (IsMounted() or UnitInVehicle("player") or isDruidInFlightForm) then
        self:Hide()
        return
    end

    -- Always hide in Pet Battles
    if C_PetBattles.IsInBattle() then
        self:Hide()
        return
    end

    if data.barVisible == "Always Visible" then
        self:Show()
    elseif data.barVisible == "Hidden" then
        self:Hide()
    elseif data.barVisible == "In Combat" then
        inCombat = inCombat or InCombatLockdown()
        if inCombat then
            self:Show()
        else
            self:Hide()
        end
    elseif data.barVisible == "Has Target Selected" then
        if UnitExists("target") then
            self:Show()
        else
            self:Hide()
        end
    elseif data.barVisible == "Has Target Selected OR In Combat" then
        inCombat = inCombat or InCombatLockdown()
        if UnitExists("target") or inCombat then
            self:Show()
        else
            self:Hide()
        end
    else
        self:Show()
    end

    self:ApplyTextVisibilitySettings(layoutName, data)
end

function BarMixin:ApplyTextVisibilitySettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    self.TextValue:SetShown(data.showText ~= false)

    for _, fragmentedPowerBarText in ipairs(self.FragmentedPowerBarTexts) do
        fragmentedPowerBarText:SetShown(data.showFragmentedPowerBarText ~= false)
    end
end

------------------------------------------------------------
-- LAYOUT related methods
------------------------------------------------------------

function BarMixin:GetPoint(layoutName, ignorePositionMode)
    local defaults = self.defaults or {}

    local data = self:GetData(layoutName)
    if not data then
        return defaults.point or "CENTER",
            addonTable.resolveRelativeFrames(defaults.relativeFrame or "UIParent"),
            defaults.relativePoint or "CENTER",
            defaults.x or 0,
            defaults.y or 0
    end

    if not ignorePositionMode then
        if data and data.positionMode == "Use Primary Resource Bar Position If Hidden" then
            local primaryResource = addonTable.barInstances and addonTable.barInstances["PrimaryResourceBar"]

            if primaryResource then
                primaryResource:ApplyVisibilitySettings(layoutName, self._curEvent == "PLAYER_REGEN_DISABLED")
                if not primaryResource:IsShown() then
                    return primaryResource:GetPoint(layoutName, true)
                end
            end
        elseif data and data.positionMode == "Use Secondary Resource Bar Position If Hidden" then
            local secondaryResource = addonTable.barInstances and addonTable.barInstances["SecondaryResourceBar"]

            if secondaryResource then
                secondaryResource:ApplyVisibilitySettings(layoutName, self._curEvent == "PLAYER_REGEN_DISABLED")
                if not secondaryResource:IsShown() then
                    return secondaryResource:GetPoint(layoutName, true)
                end
            end
        elseif data and data.positionMode == "Use Health Bar Position If Hidden" then
            local health = addonTable.barInstances and addonTable.barInstances["HealthBar"]

            if health then
                health:ApplyVisibilitySettings(layoutName, self._curEvent == "PLAYER_REGEN_DISABLED")
                if not health:IsShown() then
                    return health:GetPoint(layoutName, true)
                end
            end
        end
    end

    local x = data.x or defaults.x
    local y = data.y or defaults.y

    local point = data.point or defaults.point
    local relativePoint = data.relativePoint or defaults.relativePoint
    local relativeFrame = data.relativeFrame or defaults.relativeFrame
    local resolvedRelativeFrame = addonTable.resolveRelativeFrames(relativeFrame) or UIParent
    -- Cannot anchor to itself or to a frame already anchored to this frame
    if self.Frame == resolvedRelativeFrame or self.Frame == select(2, resolvedRelativeFrame:GetPoint(1)) then
        resolvedRelativeFrame = UIParent
        data.relativeFrame = "UIParent"
        LEM.internal:RefreshSettingValues({L["RELATIVE_FRAME"]})
        addonTable.prettyPrint(L["RELATIVE_FRAME_CYCLIC_WARNING"])
    end

    return point, resolvedRelativeFrame, relativePoint, x, y
end

function BarMixin:GetSize(layoutName, data)
    local defaults = self.defaults or {}

    data = data or self:GetData(layoutName)
    if not data then return defaults.width or 200, defaults.height or 15 end

    local width = nil
    if data.widthMode ~= nil and addonTable.customFrameNamesToFrame[data.widthMode] then
        width = self:GetCustomFrameWidth(layoutName) or data.width or defaults.width
        if data.minWidth and data.minWidth > 0 then
            width = max(width, data.minWidth)
        end
    elseif data.widthMode ~= nil and data.widthMode ~= "Manual" then
        width = self:GetCooldownManagerWidth(layoutName) or data.width or defaults.width
        if data.minWidth and data.minWidth > 0 then
            width = max(width, data.minWidth)
        end
    else -- Use manual width
        width = data.width or defaults.width
    end

    local height = data.height or defaults.height

    local scale = addonTable.rounded(data.scale or defaults.scale or 1, 2)

    return addonTable.rounded(addonTable.getNearestPixel(width * scale, scale)), addonTable.rounded(addonTable.getNearestPixel(height * scale, scale))
end

function BarMixin:ApplyLayout(layoutName, force)
    if not self:IsShown() and not force then return end

    local data = self:GetData(layoutName)
    if not data then return end

    -- Init Fragmented Power Bars if needed
    local resource = self:GetResource()
    if addonTable.fragmentedPowerTypes[resource] then
        self:CreateFragmentedPowerBars(layoutName, data)
    end

    local defaults = self.defaults or {}

    -- Cannot touch Protected Frame in Combat
    if not self.Frame:IsProtected() or (self.Frame:IsProtected() and not InCombatLockdown()) then
        local width, height = self:GetSize(layoutName, data)
        self.Frame:SetSize(max(LEM:IsInEditMode() and 2 or 1, width), max(LEM:IsInEditMode() and 2 or 1, height))

        local point, relativeTo, relativePoint, x, y = self:GetPoint(layoutName)
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(point, relativeTo, relativePoint, x, y)
        -- Disable drag & drop if the relative frame is not UIParent, due to LEM limitation making x and y position incorrect when dragging
        LEM:SetFrameDragEnabled(self.Frame, relativeTo == UIParent)

        self:SetFrameStrata(data.barStrata or defaults.barStrata)
    end

    self:ApplyFontSettings(layoutName, data)
    self:ApplyFillDirectionSettings(layoutName, data)
    self:ApplyMaskAndBorderSettings(layoutName, data)
    self:ApplyForegroundSettings(layoutName, data)
    self:ApplyBackgroundSettings(layoutName, data)

    self:UpdateTicksLayout(layoutName, data)

    if data.fasterUpdates == nil and defaults.fasterUpdates or data.fasterUpdates then
        self:EnableFasterUpdates()
    else
        self:DisableFasterUpdates()
    end

    if addonTable.fragmentedPowerTypes[resource] then
        self:UpdateFragmentedPowerDisplay(layoutName, data)
    else
        self.StatusBar:SetAlpha(1)
        for i, _ in pairs(self.FragmentedPowerBars or {}) do
            if self.FragmentedPowerBars[i] then
                self.FragmentedPowerBars[i]:Hide()
                if self.FragmentedPowerBarTexts[i] then
                    self.FragmentedPowerBarTexts[i]:SetFormattedText("")
                end
            end
        end
    end
end

function BarMixin:ApplyFontSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local scale = data.scale or defaults.scale
    local font = data.font or defaults.font
    local size = data.fontSize or defaults.fontSize
    local outline = data.fontOutline or defaults.fontOutline
    -- Since 12.0.5, "NONE" is not valid
    if outline == "NONE" then
        outline = ""
    end

    local ok = addonTable.setFontStringFont(self.TextValue, font, size * scale, outline)
    if not ok then
        addonTable.setFontStringFont(self.TextValue, defaults.font, size * scale, outline)
    end
    self.TextValue:SetShadowColor(0, 0, 0, 0.8)
    self.TextValue:SetShadowOffset(1, -1)

    local color = data.textColor or defaults.textColor
    self.TextValue:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)

    color = data.fragmentedPowerBarTextColor or defaults.fragmentedPowerBarTextColor
    for _, fragmentedPowerBarText in ipairs(self.FragmentedPowerBarTexts) do
        ok = addonTable.setFontStringFont(fragmentedPowerBarText, font, size * scale, outline)
        if not ok then
            addonTable.setFontStringFont(fragmentedPowerBarText, defaults.font, size * scale, outline)
        end
        fragmentedPowerBarText:SetShadowColor(0, 0, 0, 0.8)
        fragmentedPowerBarText:SetShadowOffset(1, -1)
        fragmentedPowerBarText:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end

    -- Text alignment: LEFT, CENTER, RIGHT, TOP, BOTTOM
    local align = data.textAlign or defaults.textAlign or "CENTER"

    if align == "LEFT" or align == "RIGHT" or align == "CENTER" then
        self.TextValue:SetJustifyH(align)
    else
        self.TextValue:SetJustifyH("CENTER") -- Top/Bottom center horizontally
    end

    -- Re-anchor the text inside the text frame depending on alignment
    self.TextValue:ClearAllPoints()
    if align == "LEFT" then
        self.TextValue:SetPoint("LEFT", self.TextFrame, "LEFT", 4, 0)
    elseif align == "RIGHT" then
        self.TextValue:SetPoint("RIGHT", self.TextFrame, "RIGHT", -4, 0)
    elseif align == "TOP" then
        self.TextValue:SetPoint("TOP", self.TextFrame, "TOP", 0, 4)
    elseif align == "BOTTOM" then
        self.TextValue:SetPoint("BOTTOM", self.TextFrame, "BOTTOM", 0, -4)
    else -- Center
        self.TextValue:SetPoint("CENTER", self.TextFrame, "CENTER", addonTable.getNearestPixel(1, scale), 0)
    end
end

function BarMixin:ApplyFillDirectionSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    if data.fillDirection == "Top to Bottom" or data.fillDirection == "Bottom to Top" then
        self.StatusBar:SetOrientation("VERTICAL")
    else
        self.StatusBar:SetOrientation("HORIZONTAL")
    end

    if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
        self.StatusBar:SetReverseFill(true)
    else
        self.StatusBar:SetReverseFill(false)
    end

    for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
        if data.fillDirection == "Top to Bottom" or data.fillDirection == "Bottom to Top" then
            fragmentedPowerBar:SetOrientation("VERTICAL")
        else
            fragmentedPowerBar:SetOrientation("HORIZONTAL")
        end

        if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
            fragmentedPowerBar:SetReverseFill(true)
        else
            fragmentedPowerBar:SetReverseFill(false)
        end
    end
end

function BarMixin:ApplyMaskAndBorderSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local styleName = data.maskAndBorderStyle or defaults.maskAndBorderStyle
    local style = addonTable.maskAndBorderStyles[styleName]
    if not style then return end

    local width, height = self.StatusBar:GetSize()
    local verticalOrientation = self.StatusBar:GetOrientation() == "VERTICAL"

    if self.Mask then
        self.StatusBar:GetStatusBarTexture():RemoveMaskTexture(self.Mask)
        self.Background:RemoveMaskTexture(self.Mask)
        self.Mask:ClearAllPoints()
    else
        self.Mask = self.StatusBar:CreateMaskTexture()
    end

    self.Mask:SetTexture(style.mask or [[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\white.png]])
    self.Mask:SetPoint("CENTER", self.BackgroundFrame, "CENTER")
    self.Mask:SetSize(verticalOrientation and height or width, verticalOrientation and width or height)
    self.Mask:SetRotation(verticalOrientation and math.rad(90) or 0)

    self.StatusBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
    self.Background:AddMaskTexture(self.Mask)

    if style.type == "fixed" then
        self._bordersInfo = self._bordersInfo or {
            top    = { "TOPLEFT", "TOPRIGHT" },
            bottom = { "BOTTOMLEFT", "BOTTOMRIGHT" },
            left   = { "TOPLEFT", "BOTTOMLEFT" },
            right  = { "TOPRIGHT", "BOTTOMRIGHT" },
        }

        if not self.FixedThicknessBorders then
            self.FixedThicknessBorders = {}
            for edge, _ in pairs(self._bordersInfo) do
                local t = self.BorderFrame:CreateTexture(nil, "OVERLAY")
                t:SetColorTexture(0, 0, 0, 1)
                self.FixedThicknessBorders[edge] = t
            end
        end

        self.Border:Hide()

        -- Linear multiplier: for example, thickness grows 1x at scale 1, 2x at scale 2
        local thickness = (style.thickness or 1) * math.max(data.scale or defaults.scale, 1)
        local pThickness = addonTable.getNearestPixel(thickness)

        local borderColor = data.borderColor or defaults.borderColor

        for edge, t in pairs(self.FixedThicknessBorders) do
            local points = self._bordersInfo[edge]
            t:ClearAllPoints()
            t:SetPoint(points[1], self.BorderFrame, points[1])
            t:SetPoint(points[2], self.BorderFrame, points[2])
            t:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)
            if edge == "top" or edge == "bottom" then
                t:SetHeight(pThickness)
            else
                t:SetWidth(pThickness)
            end
            t:Show()
        end
    elseif style.type == "texture" then
        self.Border:Show()
        self.Border:SetTexture(style.border)
        self.Border:ClearAllPoints()
        self.Border:SetPoint("CENTER", self.BorderFrame, "CENTER")
        self.Border:SetSize(verticalOrientation and height or width, verticalOrientation and width or height)
        self.Border:SetRotation(verticalOrientation and math.rad(90) or 0)

        local borderColor = data.borderColor or defaults.borderColor
        self.Border:SetVertexColor(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

        if self.FixedThicknessBorders then
            for _, t in pairs(self.FixedThicknessBorders) do
                t:Hide()
            end
        end
    else
        self.Border:Hide()

        if self.FixedThicknessBorders then
            for _, t in pairs(self.FixedThicknessBorders) do
                t:Hide()
            end
        end
    end
end

function BarMixin:GetCooldownManagerWidth(layoutName)
    local data = self:GetData(layoutName)
    if not data then return nil end

    if data.widthMode == "Sync With Essential Cooldowns" then
        local v = _G["EssentialCooldownViewer"]
        if v then
            return v:IsShown() and v:GetWidth() or nil
        end
    elseif data.widthMode == "Sync With Utility Cooldowns" then
        local v = _G["UtilityCooldownViewer"]
        if v then
            return v:IsShown() and v:GetWidth() or nil
        end
    elseif data.widthMode == "Sync With Tracked Buffs" then
        local v = _G["BuffIconCooldownViewer"]
        if v then
            return v:IsShown() and v:GetWidth() or nil
        end
    end

    return nil
end

function BarMixin:GetCustomFrameWidth(layoutName)
    local data = self:GetData(layoutName)
    if not data then return nil end

    local v = _G[addonTable.customFrameNamesToFrame[data.widthMode]]
    if v then
        return v:IsShown() and v:GetWidth() or nil
    end

    return nil
end

function BarMixin:ApplyBackgroundSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local bgStyleName = data.backgroundStyle or defaults.backgroundStyle
    local bgConfig = addonTable.backgroundStyles[bgStyleName]
        or (LSM:IsValid(LSM.MediaType.BACKGROUND, bgStyleName) and { type = "texture", value = LSM:Fetch(LSM.MediaType.BACKGROUND, bgStyleName) })
        or nil

    if not bgConfig then return end

    local bgColor = data.backgroundColor or defaults.backgroundColor
    if data.useStatusBarColorForBackgroundColor then
        local r, g, b, a = self.StatusBar:GetStatusBarColor()
        bgColor = { r = r * 0.25, g = g * 0.25, b = b * 0.25, a = a or 1 }
    end

    if bgConfig.type == "color" then
        -- Blend bgColor with bgConfig color based on how close bgColor is to white
        -- The closer bgColor is to white, the more bgConfig color shows through
        local whitenessFactor = (bgColor.r + bgColor.g + bgColor.b) / 3
        local resultR = (bgConfig.r or 1) * whitenessFactor + bgColor.r * (1 - whitenessFactor)
        local resultG = (bgConfig.g or 1) * whitenessFactor + bgColor.g * (1 - whitenessFactor)
        local resultB = (bgConfig.b or 1) * whitenessFactor + bgColor.b * (1 - whitenessFactor)
        self.Background:SetColorTexture(resultR, resultG, resultB, (bgConfig.a or 1) * (bgColor.a or 1))
    elseif bgConfig.type == "texture" then
        self.Background:SetTexture(bgConfig.value)
        self.Background:SetVertexColor(bgColor.r or 1, bgColor.g or 1, bgColor.b or 1, bgColor.a or 1)
    end
end

function BarMixin:ApplyForegroundSettings(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
    local fgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, fgStyleName)

    local resource = self:GetResource()
    local color = self:GetBarColor(resource)
    if data.useResourceAtlas == true and (color.atlasElementName or color.atlas) then
        if color.atlasElementName then
            if color.hasClassResourceVariant then
                fgTexture = "UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-Bar-"..color.atlasElementName
            else
                fgTexture = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-"..color.atlasElementName
            end
        elseif color.atlas then
            fgTexture = color.atlas
        end
    end

    if fgTexture then
        self.StatusBar:SetStatusBarTexture(fgTexture)

        for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
            fragmentedPowerBar:SetStatusBarTexture(fgTexture)
        end
    end

    if data.useResourceAtlas == true and (color.atlasElementName or color.atlas) then
        self.StatusBar:SetStatusBarColor(1, 1, 1, color.a or 1);
    else
        self.StatusBar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1);
    end
end

function BarMixin:UpdateTicksLayout(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local resource = self:GetResource()
    local max = 0;
    if resource == "MAELSTROM_WEAPON" then
        max = 5
    elseif resource == "TIP_OF_THE_SPEAR" then
        max = 3
    elseif resource == "ICICLES" then
        max = 5
    elseif resource == "WHIRLWIND" then
        max = addonTable.Whirlwind.IW_MAX_STACKS
    elseif resource == "SOUL_FRAGMENTS_VENGEANCE" then
        max = 6
    elseif resource == "FREEZE" then
        max = 20
    elseif type(resource) == "number" then
        max = UnitPowerMax("player", resource)
    end

    local defaults = self.defaults or {}

    -- Arbitrarily show 4 ticks for edit mode for preview, if spec does not support it
    if LEM:IsInEditMode() and data.showTicks == true and type(resource) ~= "string" and addonTable.tickedPowerTypes[resource] == nil then
        max = 5
        resource = Enum.PowerType.ComboPoints
    end

    self.Ticks = self.Ticks or {}
    if data.showTicks == false or not addonTable.tickedPowerTypes[resource] then
        for _, t in ipairs(self.Ticks) do
            t:Hide()
        end
        return
    end

    local width = self.StatusBar:GetWidth()
    local height = self.StatusBar:GetHeight()
    if width <= 0 or height <= 0 then return end

    local tickThickness = (data.tickThickness or defaults.tickThickness or 1) * math.max(data.scale or defaults.scale, 1)
    local pThickness = addonTable.getNearestPixel(tickThickness)
    local tickColor = data.tickColor or defaults.tickColor

    local needed = max - 1
    for i = 1, needed do
        local t = self.Ticks[i]
        if not t then
            t = self.BorderFrame:CreateTexture(nil, "OVERLAY")
            self.Ticks[i] = t
        end
        t:SetColorTexture(tickColor.r or 0, tickColor.g or 0, tickColor.b or 0, tickColor.a or 1)
        t:ClearAllPoints()
        if self.StatusBar:GetOrientation() == "VERTICAL" then
            local rawY = (i / max) * height
            t:SetSize(width, pThickness)
            t:SetPoint("BOTTOM", self.StatusBar, "BOTTOM", 0, rawY)
        else
            local rawX = (i / max) * width
            t:SetSize(pThickness, height)
            t:SetPoint("LEFT", self.StatusBar, "LEFT", rawX, 0)
        end
        t:Show()
    end

    -- Hide any extra ticks
    for i = needed + 1, #self.Ticks do
        local t = self.Ticks[i]
        if t then
            t:Hide()
        end
    end
end

function BarMixin:CreateFragmentedPowerBars(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local resource = self:GetResource()
    if not resource then return end

    local maxPower = resource == "MAELSTROM_WEAPON" and 5 or UnitPowerMax("player", resource) or 0

    for i = 1, maxPower or 0 do
        if not self.FragmentedPowerBars[i] then
            -- Create a small status bar for each resource (behind main bar, in front of background)
            local bar = CreateFrame("StatusBar", nil, self.BackgroundFrame)
            bar:SetClipsChildren(true)

            local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
            local fgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, fgStyleName)

            if fgTexture then
                bar:SetStatusBarTexture(fgTexture)
            end
            bar:GetStatusBarTexture():AddMaskTexture(self.Mask)
            bar:SetOrientation("HORIZONTAL")
            bar:SetFrameLevel(self.StatusBar:GetFrameLevel())
            self.FragmentedPowerBars[i] = bar

            -- Create text for reload time display
            local text = self.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("CENTER", bar, "CENTER", 0, 0)
            text:SetJustifyH("CENTER")
            text:SetFormattedText("")
            self.FragmentedPowerBarTexts[i] = text
        end
    end
end

function BarMixin:UpdateFragmentedPowerDisplay(layoutName, data, maxPower)
    data = data or self:GetData(layoutName)
    if not data then return end

    local resource = self:GetResource()
    if not resource then return end
    -- Use passed maxPower to avoid redundant UnitPowerMax call
    maxPower = maxPower or (resource == "MAELSTROM_WEAPON" and 5 or UnitPowerMax("player", resource))
    if maxPower <= 0 then return end

    local defaults = self.defaults or {}

    local barWidth = self.Frame:GetWidth()
    local barHeight = self.Frame:GetHeight()
    local fragmentedBarWidth = barWidth / maxPower
    local fragmentedBarHeight = barHeight / maxPower

    local r, g, b, a = self.StatusBar:GetStatusBarColor()
    local color = { r = r, g = g, b = b, a = a or 1 }

    if resource == Enum.PowerType.ComboPoints then
        local current = UnitPower("player", resource)
        -- Reuse cached maxPower to avoid redundant API call
        local maxCP = maxPower

        local overchargedCpColor = addonTable:GetOverrideResourceColor("OVERCHARGED_COMBO_POINTS") or color
        local charged = GetUnitChargedPowerPoints("player") or {}
        local chargedLookup = {}
        for _, index in ipairs(charged) do
            chargedLookup[index] = true
        end

        -- Reuse pre-allocated table for performance
        local displayOrder = self._displayOrder
        for i = 1, maxCP do
            displayOrder[i] = i
        end

        -- Reverse if needed
        if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
            for i = 1, math.floor(maxCP / 2) do
                displayOrder[i], displayOrder[maxCP - i + 1] = displayOrder[maxCP - i + 1], displayOrder[i]
            end
        end

        self.StatusBar:SetAlpha(0)
        for pos = 1, #displayOrder do
            local idx = displayOrder[pos]
            local cpFrame = self.FragmentedPowerBars[idx]
            local cpText  = self.FragmentedPowerBarTexts[idx]

            if cpFrame then
                cpFrame:ClearAllPoints()
                if self.StatusBar:GetOrientation() == "VERTICAL" then
                    cpFrame:SetSize(barWidth, fragmentedBarHeight)
                    cpFrame:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, (pos - 1) * fragmentedBarHeight)
                else
                    cpFrame:SetSize(fragmentedBarWidth, barHeight)
                    cpFrame:SetPoint("LEFT", self.Frame, "LEFT", (pos - 1) * fragmentedBarWidth, 0)
                end

                cpFrame:SetMinMaxValues(0, 1)

                if chargedLookup[idx] then
                    cpFrame:SetValue(1, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    if idx <= current then
                        cpFrame:SetStatusBarColor(overchargedCpColor.r, overchargedCpColor.g, overchargedCpColor.b, overchargedCpColor.a or 1)
                    else
                        cpFrame:SetStatusBarColor(overchargedCpColor.r * 0.5, overchargedCpColor.g * 0.5, overchargedCpColor.b * 0.5, overchargedCpColor.a or 1)
                    end
                else
                    if idx <= current then
                        cpFrame:SetValue(1, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                        cpFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    else
                        cpFrame:SetValue(0, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                        cpFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    end
                end
                cpText:SetFormattedText("")

                cpFrame:Show()
            end
        end
    elseif resource == Enum.PowerType.Essence then
        local current = UnitPower("player", resource)
        local maxEssence = UnitPowerMax("player", resource)
        local regenRate = GetPowerRegenForPowerType(resource) or 0.2
        if not issecretvalue(regenRate) then
            self._cachedRegenRate = regenRate
        else
            regenRate = self._cachedRegenRate or 0.2
        end
        local tickDuration = 5 / (5 / (1 / regenRate))
        local now = GetTime()

        self._NextEssenceTick = self._NextEssenceTick or nil
        self._LastEssence = self._LastEssence or current

        -- If we gained an essence, reset timer
        if current > self._LastEssence then
            if current < maxEssence then
                self._NextEssenceTick = now + tickDuration
            else
                self._NextEssenceTick = nil
            end
        end

        -- If missing essence and no timer, start it
        if current < maxEssence and not self._NextEssenceTick then
            self._NextEssenceTick = now + tickDuration
        end

        -- If full essence, hide timer
        if current >= maxEssence then
            self._NextEssenceTick = nil
        end

        self._LastEssence = current

        -- Reuse pre-allocated table for performance
        local displayOrder = self._displayOrder
        local stateList = {}
        for i = 1, maxEssence do
            if i <= current then
                stateList[i] = "full"
            elseif i == current + 1 then
                stateList[i] = self._NextEssenceTick and "partial" or "empty"
            else
                stateList[i] = "empty"
            end
            displayOrder[i] = i
        end

        self.StatusBar:SetValue(current)

        local precision = math.max(0, string.len(data.fragmentedPowerBarTextPrecision or defaults.fragmentedPowerBarTextPrecision or "") - 3)
        for pos = 1, #displayOrder do
            local idx = displayOrder[pos]
            local essFrame = self.FragmentedPowerBars[idx]
            local essText  = self.FragmentedPowerBarTexts[idx]
            local state = stateList[idx]

            if essFrame then
                essFrame:ClearAllPoints()
                if self.StatusBar:GetOrientation() == "VERTICAL" then
                    essFrame:SetSize(barWidth, fragmentedBarHeight)
                    essFrame:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, (pos - 1) * fragmentedBarHeight)
                else
                    essFrame:SetSize(fragmentedBarWidth, barHeight)
                    essFrame:SetPoint("LEFT", self.Frame, "LEFT", (pos - 1) * fragmentedBarWidth, 0)
                end

                essFrame:SetMinMaxValues(0, 1)

                if state == "full" then
                    essFrame:Hide()
                    essFrame:SetValue(1, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    essFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    essText:SetFormattedText("")
                elseif state == "partial" then
                    essFrame:Show()
                    local remaining = math.max(0, self._NextEssenceTick - now)
                    local value = 1 - (remaining / tickDuration)
                    essFrame:SetValue(value, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    essFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    essText:SetFormattedText(string.format("%." .. (precision or 1) .. "f", remaining))
                else
                    essFrame:Show()
                    essFrame:SetValue(0, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    essFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    essText:SetFormattedText("")
                end
            end
        end
    elseif resource == Enum.PowerType.Runes then
        -- Collect rune states: ready and recharging (reuse pre-allocated tables)
        local readyList = self._runeReadyList
        local cdList = self._runeCdList
        -- Clear previous data
        for i = #readyList, 1, -1 do readyList[i] = nil end
        for i = #cdList, 1, -1 do cdList[i] = nil end

        local now = GetTime()
        local poolIdx = 1
        for i = 1, maxPower do
            -- Try to use cached cooldown data first (for runes, cached by GetResourceValue)
            local start, duration, runeReady
            if self._runeCooldownCache and self._runeCooldownCache[i] then
                local cached = self._runeCooldownCache[i]
                start, duration, runeReady = cached.start, cached.duration, cached.runeReady
            else
                start, duration, runeReady = GetRuneCooldown(i)
            end

            if runeReady then
                -- Reuse pre-allocated struct
                local info = self._runeInfoPool[poolIdx]
                poolIdx = poolIdx + 1
                info.index = i
                table.insert(readyList, info)
            else
                -- Reuse pre-allocated struct
                local info = self._runeInfoPool[poolIdx]
                poolIdx = poolIdx + 1
                info.index = i
                if start and duration and duration > 0 then
                    local elapsed = now - start
                    info.remaining = math.max(0, duration - elapsed)
                    info.frac = math.max(0, math.min(1, elapsed / duration))
                else
                    info.remaining = math.huge
                    info.frac = 0
                end
                table.insert(cdList, info)
            end
        end

        -- Sort cdList by ascending remaining time (least remaining on the left of the CD group)
        table.sort(cdList, function(a, b)
            return a.remaining < b.remaining
        end)

        -- Build final display order: ready runes first (left), then CD runes sorted by remaining
        local displayOrder = self._displayOrder
        local readyLookup = {}
        local cdLookup = {}
        local orderIndex = 1
        for _, v in ipairs(readyList) do
            displayOrder[orderIndex] = v.index
            orderIndex = orderIndex + 1
            readyLookup[v.index] = true
        end
        for _, v in ipairs(cdList) do
            displayOrder[orderIndex] = v.index
            orderIndex = orderIndex + 1
            cdLookup[v.index] = v
        end
        local totalRunes = orderIndex - 1

        if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
            for i = 1, math.floor(totalRunes / 2) do
                displayOrder[i], displayOrder[totalRunes - i + 1] = displayOrder[totalRunes - i + 1], displayOrder[i]
            end
        end

        self.StatusBar:SetValue(#readyList)

        local precision = math.max(0, string.len(data.fragmentedPowerBarTextPrecision or defaults.fragmentedPowerBarTextPrecision or "") - 3)
        for pos = 1, totalRunes do
            local runeIndex = displayOrder[pos]
            local runeFrame = self.FragmentedPowerBars[runeIndex]
            local runeText = self.FragmentedPowerBarTexts[runeIndex]

            if runeFrame then
                runeFrame:ClearAllPoints()

                if self.StatusBar:GetOrientation() == "VERTICAL" then
                    runeFrame:SetSize(barWidth, fragmentedBarHeight)
                    runeFrame:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, (pos - 1) * fragmentedBarHeight)
                else
                    runeFrame:SetSize(fragmentedBarWidth, barHeight)
                    runeFrame:SetPoint("LEFT", self.Frame, "LEFT", (pos - 1) * fragmentedBarWidth, 0)
                end

                runeFrame:SetMinMaxValues(0, 1)
                if readyLookup[runeIndex] then
                    runeFrame:Hide()
                    runeFrame:SetValue(1, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    runeText:SetFormattedText("")
                    runeFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                else
                    runeFrame:Show()
                    local cdInfo = cdLookup[runeIndex]
                    runeFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    if cdInfo then
                        runeFrame:SetValue(cdInfo.frac, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                        runeText:SetFormattedText(string.format("%." .. (precision or 1) .. "f", math.max(0, cdInfo.remaining)))
                    else
                        runeFrame:SetValue(0, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                        runeText:SetFormattedText("")
                    end
                end
            end
        end
    elseif resource == "MAELSTROM_WEAPON" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179) -- Maelstrom Weapon
        local current = auraData and auraData.applications or 0
        local above5MwColor = addonTable:GetOverrideResourceColor("MAELSTROM_WEAPON_ABOVE_5") or color

        -- Reuse pre-allocated table for performance
        local displayOrder = self._displayOrder
        for i = 1, maxPower do
            displayOrder[i] = i
        end

        if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
            for i = 1, math.floor(maxPower / 2) do
                displayOrder[i], displayOrder[maxPower - i + 1] = displayOrder[maxPower - i + 1], displayOrder[i]
            end
        end

        self.StatusBar:SetAlpha(0)
        for pos = 1, #displayOrder do
            local idx = displayOrder[pos]
            local mwFrame = self.FragmentedPowerBars[idx]
            local mwText = self.FragmentedPowerBarTexts[idx]

            if mwFrame then
                mwFrame:ClearAllPoints()
                if self.StatusBar:GetOrientation() == "VERTICAL" then
                    mwFrame:SetSize(barWidth, fragmentedBarHeight)
                    mwFrame:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, (pos - 1) * fragmentedBarHeight)
                else
                    mwFrame:SetSize(fragmentedBarWidth, barHeight)
                    mwFrame:SetPoint("LEFT", self.Frame, "LEFT", (pos - 1) * fragmentedBarWidth, 0)
                end

                mwFrame:SetMinMaxValues(0, 1)

                if idx <= current then
                    mwFrame:SetValue(1, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    if current > 5 and idx <= math.fmod(current - 1, 5) + 1 then
                        mwFrame:SetStatusBarColor(above5MwColor.r, above5MwColor.g, above5MwColor.b, above5MwColor.a or 1)
                    else
                        mwFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    end
                else
                    mwFrame:SetValue(0, data.smoothProgress and Enum.StatusBarInterpolation.ExponentialEaseOut or nil)
                    mwFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                end
                mwText:SetFormattedText("")

                mwFrame:Show()
            end
        end
    end

    self:ApplyFontSettings(layoutName)

    for i = maxPower + 1, #self.FragmentedPowerBars do
        if self.FragmentedPowerBars[i] then
            self.FragmentedPowerBars[i]:Hide()
            if self.FragmentedPowerBarTexts[i] then
                self.FragmentedPowerBarTexts[i]:SetFormattedText("")
            end
        end
    end
end

addonTable.BarMixin = BarMixin