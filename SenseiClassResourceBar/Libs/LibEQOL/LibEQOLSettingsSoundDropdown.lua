local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 23000001
local ok, lib = pcall(LibStub, MODULE_MAJOR)
if not ok or not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

LibEQOL_SoundDropdownMixin = CreateFromMixins(SettingsListElementMixin)

local DEFAULT_FRAME_WIDTH = 280
local DEFAULT_FRAME_HEIGHT = 26
local DEFAULT_MENU_HEIGHT = 200
local DEFAULT_LABEL_OFFSET_LEFT = 37
local DEFAULT_LABEL_OFFSET_RIGHT = -85
local DEFAULT_PREVIEW_POINT = { "LEFT", nil, "CENTER", -74, 0 }

local function ResolveString(defaultValue, ...)
	for _, candidate in ipairs({ ... }) do
		if type(candidate) == "string" and candidate ~= "" then return candidate end
	end
	return defaultValue
end

local DEFAULT_PLACEHOLDER = ResolveString("None", _G and _G.NONE)
local DEFAULT_PREVIEW_TOOLTIP = ResolveString("Preview Sound", _G.PREVIEW)
local DEFAULT_LABEL = ResolveString("Sound", _G and _G.SOUND)

local function CloneOption(option)
	if type(option) ~= "table" then return { value = option, label = tostring(option) } end

	local clone = {}
	for key, value in pairs(option) do
		clone[key] = value
	end

	clone.value = clone.value or clone.text or clone.label
	clone.label = clone.label or clone.text or tostring(clone.value or "")
	return clone
end

local function NormalizeOptions(list, order)
	if type(list) ~= "table" then return {} end
	order = (type(order) == "table" and #order > 0 and order) or nil

	local normalized = {}
	local usesIndex = #list > 0

	if usesIndex then
		for _, entry in ipairs(list) do
			if entry ~= nil then table.insert(normalized, CloneOption(entry)) end
		end
	else
		for value, label in pairs(list) do
			if type(label) == "table" then
				local cloned = CloneOption(label)
				cloned.value = cloned.value or value
				table.insert(normalized, cloned)
			else
				table.insert(normalized, { value = value, label = tostring(label) })
			end
		end
	end

	if order then
		local lookup = {}
		for _, entry in ipairs(normalized) do
			lookup[entry.value] = entry
		end
		local ordered = {}
		local used = {}
		for _, key in ipairs(order) do
			local entry = lookup[key]
			if entry and not used[entry] then
				table.insert(ordered, entry)
				used[entry] = true
			end
		end
		for _, entry in ipairs(normalized) do
			if not used[entry] then table.insert(ordered, entry) end
		end
		normalized = ordered
	else
		table.sort(normalized, function(a, b)
			return tostring(a.label or a.value or "") < tostring(b.label or b.value or "")
		end)
	end

	return normalized
end

local function ApplySingleAnchor(widget, anchor, defaultRelative)
	if not widget then return end
	widget:ClearAllPoints()

	if type(anchor) == "table" then
		local point = anchor.point or anchor[1]
		local relative = anchor.relativeTo or anchor[2] or defaultRelative
		local relativePoint = anchor.relativePoint or anchor[3] or (relative and "CENTER" or "LEFT")
		local x = anchor.x or anchor.offsetX or anchor[4] or 0
		local y = anchor.y or anchor.offsetY or anchor[5] or 0

		if point then
			widget:SetPoint(point, relative, relativePoint, x, y)
			return
		end
	end

	if defaultRelative then
		widget:SetPoint("LEFT", defaultRelative, "CENTER", -74, 0)
	else
		widget:SetPoint("LEFT", DEFAULT_LABEL_OFFSET_LEFT, 0)
	end
end

local function ApplyAnchors(widget, anchors, fallbackRelative)
	if type(anchors) == "table" and anchors[1] and type(anchors[1]) == "table" then
		widget:ClearAllPoints()
		for _, anchor in ipairs(anchors) do
			local point = anchor.point or anchor[1]
			local relative = anchor.relativeTo or anchor[2] or fallbackRelative
			local relativePoint = anchor.relativePoint or anchor[3] or (relative and "CENTER" or "LEFT")
			local x = anchor.x or anchor.offsetX or anchor[4] or 0
			local y = anchor.y or anchor.offsetY or anchor[5] or 0
			widget:SetPoint(point or "LEFT", relative, relativePoint, x, y)
		end
		return
	end

	ApplySingleAnchor(widget, anchors, fallbackRelative)
end

local function SafeUnregister(handle)
	if handle and handle.Unregister then handle:Unregister() end
end

function LibEQOL_SoundDropdownMixin:OnLoad()
	SettingsListElementMixin.OnLoad(self)
	if self.NewFeature then self.NewFeature:SetShown(false) end
end

function LibEQOL_SoundDropdownMixin:Init(initializer)
	SettingsListElementMixin.Init(self, initializer)

	self.initializer = initializer
	self.data = initializer.data or {}
	self.setting = initializer:GetSetting() or self.data.setting
	self.parentCheck = self.data.parentCheck
	self.options = self.data.options
	self.optionfunc = self.data.optionfunc
	self.callback = self.data.callback
	self.soundResolver = self.data.soundResolver
	self.previewSoundFunc = self.data.previewSoundFunc
	self.playbackChannel = self.data.playbackChannel
	self.getPlaybackChannel = self.data.getPlaybackChannel
	self.placeholderText = ResolveString(DEFAULT_PLACEHOLDER, self.data.placeholderText)
	self.previewTooltip = ResolveString(DEFAULT_PREVIEW_TOOLTIP, self.data.previewTooltip)
	self.labelText = ResolveString(DEFAULT_LABEL, self.data.name, self.data.label)
	self.menuHeight = self.data.menuHeight or DEFAULT_MENU_HEIGHT
	self.frameWidth = self.data.frameWidth or DEFAULT_FRAME_WIDTH
	self.frameHeight = self.data.frameHeight or DEFAULT_FRAME_HEIGHT
	self.optionsChangedVersion = 0

	if not self.cbrHandles then self.cbrHandles = Settings.CreateCallbackHandleContainer() end

	self:SetSize(self.frameWidth, self.frameHeight)
	self:SetupLabel()
	self:SetupPreviewButton()
	self:SetupDropdown()
	self:UpdateDropdownText()
	self:RegisterSettingListener()
	self:EvaluateState()
end

function LibEQOL_SoundDropdownMixin:GetSetting()
	if self.setting then return self.setting end
	if self.initializer and self.initializer.GetSetting then self.setting = self.initializer:GetSetting() end
	return self.setting
end

function LibEQOL_SoundDropdownMixin:SetupLabel()
	if not self.Text then return end
	self.Text:SetFontObject(self.data.labelFontObject or "GameFontNormal")
	self.Text:SetText(self.labelText)
	self.Text:ClearAllPoints()
	local textLeft = (self:GetIndent() or 0) + DEFAULT_LABEL_OFFSET_LEFT
	self.Text:SetPoint("LEFT", textLeft, 0)
	self.Text:SetPoint("RIGHT", self, "CENTER", DEFAULT_LABEL_OFFSET_RIGHT, 0)
end

function LibEQOL_SoundDropdownMixin:SetupPreviewButton()
	if self.previewButton then return end

	local button = CreateFrame("Button", nil, self)
	button:SetSize(self.data.previewWidth or 20, self.frameHeight)
	local anchor = self.data.previewButtonAnchor or DEFAULT_PREVIEW_POINT
	if type(anchor) == "table" then
		anchor = { anchor[1] or anchor.point or "LEFT", anchor[2], anchor[3] or (anchor[2] and "CENTER" or "LEFT"), (anchor[4] or anchor.x or anchor.offsetX or 0) + 3, anchor[5] or anchor.y or anchor.offsetY or 0 }
	end
	ApplySingleAnchor(button, anchor, self)
	button:SetMotionScriptsWhileDisabled(true)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	if self.data.previewIconAtlas then
		icon:SetAtlas(self.data.previewIconAtlas)
	else
		icon:SetTexture(self.data.previewIconTexture or "Interface\\Common\\VoiceChat-Speaker")
	end
	icon:SetVertexColor(0.8, 0.8, 0.8)

	button.Icon = icon
	button:SetScript("OnEnter", function(control)
		if not control:IsEnabled() then return end
		icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(control, "ANCHOR_TOP")
		GameTooltip:SetText(self.previewTooltip)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		icon:SetVertexColor(0.8, 0.8, 0.8)
		GameTooltip:Hide()
	end)
	button:SetScript("OnClick", function()
		self:PreviewSound()
	end)

	self.previewButton = button
end


function LibEQOL_SoundDropdownMixin:SetupDropdown()
	if self.soundDropdown then return end

	-- Prefer modern Settings dropdown styling
	local template = self.data.dropdownTemplate or "SettingsDropdownWithButtonsTemplate"
	local frame = CreateFrame("Frame", nil, self, template)
	if frame.DecrementButton then frame.DecrementButton:Hide() end
	if frame.IncrementButton then frame.IncrementButton:Hide() end
	local dropdown = frame.Dropdown or frame

	if self.data.dropdownAnchors then
		ApplyAnchors(dropdown, self.data.dropdownAnchors, self.previewButton)
	else
		dropdown:ClearAllPoints()
		dropdown:SetPoint("LEFT", self.previewButton, "RIGHT", 4, 0)
		local availableWidth = (self.frameWidth or 280) - (self.previewButton:GetWidth() + 39)
		if availableWidth > 0 then
			dropdown:SetWidth(availableWidth)
		end
	end
	dropdown:SetHeight(self.frameHeight)

	dropdown:SetupMenu(function(_, rootDescription)
		rootDescription:SetScrollMode(self.menuHeight)
		self:BuildDropdownMenu(rootDescription)
	end)

	self.soundDropdown = dropdown
end

function LibEQOL_SoundDropdownMixin:BuildDropdownMenu(rootDescription)
	local entries = self:GetSoundEntries()
	for _, entry in ipairs(entries) do
		local value = entry.value
		local label = entry.label or value or "?"
		rootDescription:CreateRadio(label, function() return self:IsValueSelected(value) end, function()
			self:SetCurrentValue(value)
			self:UpdateDropdownText()
			if self.callback then self.callback(value, entry) end
		end, entry)
	end
end

function LibEQOL_SoundDropdownMixin:GetSoundEntries()
	local list
	if self.optionfunc then
		list = self.optionfunc()
	elseif self.options then
		list = self.options
	end

	if list then return NormalizeOptions(list, self.data and self.data.order) end

	local entries = {}
	if LSM then
		local sounds = LSM:List("sound") or {}
		for _, name in ipairs(sounds) do
			entries[#entries + 1] = { value = name, label = name }
		end
	end

	table.sort(entries, function(a, b) return tostring(a.label or a.value or "") < tostring(b.label or b.value or "") end)
	return entries
end

function LibEQOL_SoundDropdownMixin:IsValueSelected(value)
	return self:GetCurrentValue() == value
end


local function GetInitializerData(self)
	return self.data or (self.initializer and self.initializer.data) or {}
end

function LibEQOL_SoundDropdownMixin:GetCurrentValue()
	local data = GetInitializerData(self)
	if data.getValue then return data.getValue() end
	local setting = self:GetSetting()
	if setting then return setting:GetValue() end
	return nil
end

function LibEQOL_SoundDropdownMixin:SetCurrentValue(value)
	local data = GetInitializerData(self)
	if data.setValue then
		data.setValue(value)
	else
		local setting = self:GetSetting()
		if setting then setting:SetValue(value or "") end
	end
end

function LibEQOL_SoundDropdownMixin:GetLabelForValue(value)
	if not value or value == "" then return nil end
	for _, entry in ipairs(self:GetSoundEntries()) do
		if entry.value == value then return entry.label or entry.value end
	end
	return value
end

function LibEQOL_SoundDropdownMixin:UpdateDropdownText()
	if not self.soundDropdown then return end
	local value = self:GetCurrentValue()
	local label = self:GetLabelForValue(value)
	self.soundDropdown:OverrideText(label or self.placeholderText)
end

function LibEQOL_SoundDropdownMixin:GetPlaybackChannel()
	if type(self.getPlaybackChannel) == "function" then
		local channel = self.getPlaybackChannel()
		if channel and channel ~= "" then return channel end
	end
	if type(self.playbackChannel) == "string" and self.playbackChannel ~= "" then return self.playbackChannel end
end

function LibEQOL_SoundDropdownMixin:ResolveSoundFile(value)
	if not value or value == "" then return end
	if self.soundResolver then return self.soundResolver(value) end
	if LSM then return LSM:Fetch("sound", value, true) end
end

function LibEQOL_SoundDropdownMixin:PreviewSound()
	if type(self.previewSoundFunc) == "function" then
		self.previewSoundFunc(self:GetCurrentValue(), self)
		return
	end
	local soundFile = self:ResolveSoundFile(self:GetCurrentValue())
	if not soundFile then return end

	local channel = self:GetPlaybackChannel()
	if channel then
		PlaySoundFile(soundFile, channel)
	else
		PlaySoundFile(soundFile)
	end
end

function LibEQOL_SoundDropdownMixin:RegisterSettingListener()
	local setting = self:GetSetting()
	if not (setting and self.cbrHandles) then return end
	local variable = setting:GetVariable()
	if not variable then return end
	self.cbrHandles:SetOnValueChangedCallback(variable, function()
		self:UpdateDropdownText()
	end)
end

function LibEQOL_SoundDropdownMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self)
	local enabled = true
	if self.parentCheck then enabled = self.parentCheck() and true or false end

	if self.previewButton then self.previewButton:SetEnabled(enabled) end
	if self.soundDropdown then
		if enabled then
			self.soundDropdown:Enable()
		else
			self.soundDropdown:Disable()
		end
	end
	if self.Text then
		self.Text:SetFontObject(enabled and "GameFontNormal" or "GameFontDisable")
	end
end

function LibEQOL_SoundDropdownMixin:Release()
	SafeUnregister(self.cbrHandles)
	SettingsListElementMixin.Release(self)
end
