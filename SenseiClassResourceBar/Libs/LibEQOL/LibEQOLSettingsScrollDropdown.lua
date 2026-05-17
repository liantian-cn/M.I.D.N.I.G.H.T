local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 23000001
local _, lib = pcall(LibStub, MODULE_MAJOR)
if not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

LibEQOL_ScrollDropdownMixin = CreateFromMixins(SettingsDropdownControlMixin)

local function CloneOption(option)
	if type(option) ~= "table" then
		local value = option
		return { value = value, label = tostring(value) }
	end

	local clone = {}
	for key, value in pairs(option) do
		clone[key] = value
	end

	clone.value = clone.value or clone.key or clone.id or clone.text or clone.label or clone.name
	local label = clone.text or clone.label or clone.name or clone.value
	clone.label = label
	clone.text = clone.text or clone.label or tostring(label or "")
	return clone
end

function LibEQOL_ScrollDropdownMixin:OnLoad()
	SettingsDropdownControlMixin.OnLoad(self)
end

function LibEQOL_ScrollDropdownMixin:Init(initializer)
	if not initializer or not initializer.GetData then return end

	self.initializer = initializer
	local data = initializer:GetData() or {}
	self.data = data

	self.options = data.options or data.values or {}
	self.optionfunc = data.optionfunc
	self.optionOrder = type(data.order) == "table" and data.order or nil
	self.callback = data.callback

	if data.customText ~= nil then
		self.customDefaultText = data.customText
	elseif data.customDefaultText ~= nil then
		self.customDefaultText = data.customDefaultText
	end

	SettingsDropdownControlMixin.Init(self, initializer)
	if data.label then self.Text:SetText(data.label) end
end

function LibEQOL_ScrollDropdownMixin:GetSetting()
	if self.initializer and self.initializer.GetSetting then return self.initializer:GetSetting() end
	if self.data and self.data.setting then return self.data.setting end
	return nil
end

function LibEQOL_ScrollDropdownMixin:GetOptions()
	if self.data and type(self.data.optionsFunc) == "function" then
		local ok, result = pcall(self.data.optionsFunc)
		if ok and type(result) == "table" then return result end
		return {}
	end

	local list = self.options or {}
	if self.optionfunc then
		local ok, result = pcall(self.optionfunc)
		if ok and type(result) == "table" then
			list = result
		end
	end

	if type(list) ~= "table" then return {} end

	local normalized = {}
	local usesIndex = #list > 0

	if usesIndex then
		for _, entry in ipairs(list) do
			if entry ~= nil then table.insert(normalized, CloneOption(entry)) end
		end
		return normalized
	end

	local orderedKeys = self.optionOrder
	local seen = nil
	if orderedKeys then
		seen = {}
		for _, key in ipairs(orderedKeys) do
			if key ~= "_order" and list[key] ~= nil then
				local entry = CloneOption(list[key])
				entry.value = entry.value or key
				table.insert(normalized, entry)
				seen[key] = true
			end
		end
	end

	for key, value in pairs(list) do
		if key ~= "_order" and (not seen or not seen[key]) then
			local entry = CloneOption(value)
			entry.value = entry.value or key
			table.insert(normalized, entry)
		end
	end

	table.sort(normalized, function(a, b)
		return tostring(a.label or a.value or "") < tostring(b.label or b.value or "")
	end)

	return normalized
end

local function FindSelectionText(options, value)
	for _, opt in ipairs(options or {}) do
		local optValue = opt and opt.value
		if type(optValue) == "table" then
			optValue = optValue.value or optValue.key or optValue.id or optValue.text or optValue.label or optValue.name or optValue[1]
		end
		if optValue == value then
			return opt.text or opt.label or tostring(optValue)
		end
	end
	return nil
end

local function NormalizeSelectionValue(value)
	if type(value) ~= "table" then
		return value
	end
	local normalized = value.value or value.key or value.id or value.text or value.label or value.name or value[1]
	if type(normalized) == "table" then
		normalized = normalized.value or normalized.key or normalized.id or normalized.text or normalized.label or normalized.name or normalized[1]
	end
	return normalized
end

function LibEQOL_ScrollDropdownMixin:RefreshDropdownText(value)
	local dropdown = self.Control and self.Control.Dropdown
	if not dropdown then return end

	local currentValue = NormalizeSelectionValue(value)
	if currentValue == nil then
		local setting = self:GetSetting()
		if setting and setting.GetValue then
			currentValue = NormalizeSelectionValue(setting:GetValue())
		end
	end

	local text = FindSelectionText(self:GetOptions(), currentValue)
	if text == nil then
		if currentValue ~= nil and currentValue ~= "" then
			text = tostring(currentValue)
		else
			text = self.customDefaultText ~= nil and tostring(self.customDefaultText) or ""
		end
	end

	if dropdown.OverrideText then
		dropdown:OverrideText(text)
	elseif dropdown.SetText then
		dropdown:SetText(text)
	elseif dropdown.Text and dropdown.Text.SetText then
		dropdown.Text:SetText(text)
	end
end

-- OVERRIDE: Avoid regenerating the dropdown menu on value changes when using scroll mode.
-- In scroll mode the menu is virtualized via ScrollBox and a full InitDropdown during an
-- open menu can cause elements to jump/reorder until the scrollbox reanchors.
function LibEQOL_ScrollDropdownMixin:SetValue(value)
	local useScroll = self.data and type(self.data.height) == "number" and self.data.height > 0
	if useScroll then
		self:RefreshDropdownText(value)
		return
	end

	if SettingsDropdownControlMixin.SetValue then
		SettingsDropdownControlMixin.SetValue(self, value)
	else
		self:RefreshDropdownText(value)
	end
end

function LibEQOL_ScrollDropdownMixin:InitDropdown()
	local setting = self:GetSetting()
	local initializer = self:GetElementData()

	local function optionsFunc()
		return self:GetOptions()
	end

	local initTooltip
	if Settings and Settings.CreateOptionsInitTooltip then
		initTooltip = Settings.CreateOptionsInitTooltip(setting, initializer:GetName(), initializer:GetTooltip(), optionsFunc)
	end

	self:SetupDropdownMenu(self.Control.Dropdown, setting, optionsFunc, initTooltip)
	self:RefreshDropdownText()
end

function LibEQOL_ScrollDropdownMixin:SetupDropdownMenu(button, setting, optionsFunc, initTooltip)
	local dropdown = button or (self.Control and self.Control.Dropdown)
	if not dropdown or not setting then return end

	local defaultText = ""
	if self.customDefaultText ~= nil then
		defaultText = tostring(self.customDefaultText)
	end
	dropdown:SetDefaultText(defaultText)

	dropdown:SetupMenu(function(owner, rootDescription)
		local useScroll = self.data and type(self.data.height) == "number" and self.data.height > 0

		if useScroll then
			rootDescription:SetScrollMode(self.data.height)
		else
			if rootDescription.SetGridMode then
				rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)
			end
		end

		local generator = self.data and self.data.generator
		if type(generator) == "function" then
			pcall(generator, owner, rootDescription, self.data)
		else
			local opts = optionsFunc() or {}
			for _, opt in ipairs(opts) do
				if opt and opt.value ~= nil then
					local label = opt.label or opt.text or tostring(opt.value)
					if rootDescription.CreateButton then
						rootDescription:CreateButton(label, function()
							setting:SetValue(opt.value)
							self:RefreshDropdownText(opt.value)
							if self.callback then self.callback(opt.value, opt) end
						end, opt)
						else
							rootDescription:CreateRadio(label, function()
								return setting:GetValue() == opt.value
							end, function()
								setting:SetValue(opt.value)
								self:RefreshDropdownText(opt.value)
								if self.callback then self.callback(opt.value, opt) end
							end, opt)
						end
				end
			end
		end

		if useScroll and rootDescription.DisableReacquireFrames then
			rootDescription:DisableReacquireFrames()
		end
	end)

	if initTooltip then
		dropdown:SetTooltipFunc(initTooltip)
		dropdown:SetDefaultTooltipAnchors()
	end
end
