local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 23000001
local ok, lib = pcall(LibStub, MODULE_MAJOR)
if not ok or not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

LibEQOL_ColorOverridesMixin = CreateFromMixins(SettingsListElementMixin)

local DEFAULT_ROW_HEIGHT = 20
local DEFAULT_PADDING = 5
local DEFAULT_SPACING = 6

local function wipe(tbl)
	if not tbl then
		return
	end
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

function LibEQOL_ColorOverridesMixin:OnLoad()
	SettingsListElementMixin.OnLoad(self)
	self.container = self.ItemQualities or self.List or self
	self.ColorOverrideFramePool = CreateFramePool("FRAME", self.container, "ColorOverrideTemplate")
	self.colorOverrideFrames = {}
	-- Disable the default hover background from SettingsListElementTemplate; Blizzard's color overrides rows don't highlight.
	if self.Tooltip and self.Tooltip.HoverBackground then
		self.Tooltip.HoverBackground:SetAlpha(0)
	end
end

function LibEQOL_ColorOverridesMixin:Init(initializer)
	SettingsListElementMixin.Init(self, initializer)

	self.categoryID = initializer.data.categoryID
	self.entries = initializer.data.entries or {}
	self.getColor = initializer.data.getColor
	self.getColorMixin = initializer.data.getColorMixin
	self.setColor = initializer.data.setColor
	self.setColorMixin = initializer.data.setColorMixin
	self.getDefaultColor = initializer.data.getDefaultColor
	self.getDefaultColorMixin = initializer.data.getDefaultColorMixin
	self.headerText = initializer.data.headerText or ""
	self.rowHeight = initializer.data.rowHeight or DEFAULT_ROW_HEIGHT
	self.basePadding = initializer.data.basePadding or DEFAULT_PADDING
	self.minHeight = initializer.data.minHeight
	self.fixedHeight = initializer.data.height
	self.fixedSpacing = initializer.data.spacing
	self.parentCheck = initializer.data.parentCheck
	self.colorizeLabel = initializer.data.colorizeLabel or initializer.data.colorizeText
	self.hasOpacity = initializer.data.hasOpacity == true

	if self.Header then
		self.Header:SetText(self.headerText)
	end
	if self.NewFeature then
		self.NewFeature:SetShown(false)
	end

	if not self.callbacksRegistered then
		EventRegistry:RegisterCallback("Settings.Defaulted", self.ResetToDefaults, self)
		EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function(_, category)
			if self.categoryID == category:GetID() then
				self:ResetToDefaults()
			end
		end, self)
		self.callbacksRegistered = true
	end

	self:RefreshRows()
end

function LibEQOL_ColorOverridesMixin:GetSpacing()
	local container = self.container
	if self.fixedSpacing then
		return self.fixedSpacing
	end
	if container and container.spacing then
		return container.spacing
	end
	return self.fixedSpacing or DEFAULT_SPACING
end

function LibEQOL_ColorOverridesMixin:RefreshRows()
	if not self.ColorOverrideFramePool then
		return
	end
	self.ColorOverrideFramePool:ReleaseAll()
	wipe(self.colorOverrideFrames)
	self.colorOverrideFrames = self.colorOverrideFrames or {}

	for index, entry in ipairs(self.entries or {}) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = index
		self:SetupRow(frame, entry)
		if self.rowHeight then
			frame:SetHeight(self.rowHeight)
		end
		frame:Show()
		self.colorOverrideFrames[#self.colorOverrideFrames + 1] = frame
	end

	if self.container and self.container.MarkDirty then
		self.container:MarkDirty()
	end
	self:RefreshAll()
	self:EvaluateState()
end

function LibEQOL_ColorOverridesMixin:SetupRow(frame, entry)
	frame.data = entry
	if frame.Text then
		if not frame._defaultTextColor then
			local r, g, b = frame.Text:GetTextColor()
			frame._defaultTextColor = { r, g, b }
		end
		frame.Text:SetText(entry.label or entry.key or "?")
	end
	frame.colorizeLabel = self.colorizeLabel
	if frame.ColorSwatch then
		frame.ColorSwatch:SetScript("OnClick", function()
			self:OpenColorPicker(frame)
		end)
	end
	self:ApplyTextColor(frame)
end

function LibEQOL_ColorOverridesMixin:ApplyTextColor(frame)
	if not frame or not frame.Text then
		return
	end
	local shouldColorize = frame.colorizeLabel
	if shouldColorize == nil then
		shouldColorize = self.colorizeLabel
	end
	local enabled = self._enabledState
	if (enabled == false) or not shouldColorize then
		local textColor = frame._defaultTextColor
		if enabled == false then
			textColor = { GRAY_FONT_COLOR:GetRGBA() }
		end
		if textColor then
			frame.Text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
		end
		return
	end
	local r, g, b = 0, 0, 0
	if self.ResolveColor then
		r, g, b = self:ResolveColor(frame.data.key, false)
	elseif self.getColor then
		r, g, b = self.getColor(frame.data.key)
	end
	if not (r and g and b) and frame.ColorSwatch and frame.ColorSwatch.Color then
		r, g, b = frame.ColorSwatch.Color:GetVertexColor()
	end
	r, g, b = r or 1, g or 1, b or 1
	frame.Text:SetTextColor(r, g, b, 1)
end

local function colorFromAny(color)
	if not color then
		return
	end
	if type(color) == "table" and color.GetRGBA then
		return color:GetRGBA()
	end
	if type(color) == "table" then
		return color.r, color.g, color.b, color.a
	end
end

function LibEQOL_ColorOverridesMixin:ResolveColor(key, useDefault)
	local r, g, b, a
	if useDefault then
		r, g, b, a = colorFromAny(self.getDefaultColorMixin and self.getDefaultColorMixin(key))
		if not r and self.getDefaultColor then
			r, g, b, a = self.getDefaultColor(key)
		end
	else
		r, g, b, a = colorFromAny(self.getColorMixin and self.getColorMixin(key))
		if not r and self.getColor then
			r, g, b, a = self.getColor(key)
		end
	end
	return r or 1, g or 1, b or 1, a
end

function LibEQOL_ColorOverridesMixin:ApplyColor(key, r, g, b, a)
	-- Prefer mixin setter when provided; fall back to numeric setter.
	if self.setColorMixin then
		self.setColorMixin(key, CreateColor(r or 1, g or 1, b or 1, a ~= nil and a or 1))
		return
	end
	if self.setColor then
		self.setColor(key, r or 1, g or 1, b or 1, a)
	end
end

function LibEQOL_ColorOverridesMixin:RefreshRow(frame)
	if not (frame.ColorSwatch and frame.ColorSwatch.Color) then
		return
	end
	local r, g, b, a = self:ResolveColor(frame.data.key, false)
	frame.ColorSwatch.Color:SetVertexColor(r, g, b, a or 1)
	self:ApplyTextColor(frame)
end

function LibEQOL_ColorOverridesMixin:RefreshAll()
	for _, frame in ipairs(self.colorOverrideFrames or {}) do
		self:RefreshRow(frame)
	end
end

function LibEQOL_ColorOverridesMixin:ResetToDefaults()
	if not (self.setColor or self.setColorMixin) then
		return
	end
	if not (self.getDefaultColor or self.getDefaultColorMixin) then
		return
	end
	for _, entry in ipairs(self.entries or {}) do
		local r, g, b, a = self:ResolveColor(entry.key, true)
		self:ApplyColor(entry.key, r, g, b, a)
	end
	self:RefreshAll()
end

function LibEQOL_ColorOverridesMixin:OpenColorPicker(frame)
	if not (self.setColor or self.setColorMixin) then
		return
	end
	local currentR, currentG, currentB, currentA = self:ResolveColor(frame.data.key, false)
	local hasOpacity = self.hasOpacity
	if hasOpacity then
		currentA = currentA or 1
	else
		currentA = nil
	end

	local function apply(r, g, b, a)
		self:ApplyColor(frame.data.key, r, g, b, hasOpacity and a or nil)
		self:RefreshRow(frame)
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		r = currentR,
		g = currentG,
		b = currentB,
		opacity = currentA,
		hasOpacity = hasOpacity,
		swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = hasOpacity and (ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or currentA) or nil
			apply(r, g, b, a)
		end,
		opacityFunc = hasOpacity and function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or currentA
			apply(r, g, b, a)
		end or nil,
		cancelFunc = function()
			local r, g, b, a = ColorPickerFrame:GetPreviousValues()
			r, g, b = r or currentR, g or currentG, b or currentB
			a = hasOpacity and (a or currentA) or nil
			apply(r, g, b, a)
		end,
	})
end

function LibEQOL_ColorOverridesMixin:Release()
	if self.ColorOverrideFramePool then
		self.ColorOverrideFramePool:ReleaseAll()
	end
	SettingsListElementMixin.Release(self)
end

function LibEQOL_ColorOverridesMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self)

	local enabled = true
	if self.parentCheck then
		enabled = self.parentCheck()
	end
	self._enabledState = enabled

	for _, frame in ipairs(self.colorOverrideFrames or {}) do
		if frame.ColorSwatch then
			frame.ColorSwatch:SetEnabled(enabled)
		end
		if frame.Text then
			frame.Text:SetFontObject(enabled and GameFontNormalSmall or GameFontDisableSmall)
		end
		self:ApplyTextColor(frame)
	end
end
