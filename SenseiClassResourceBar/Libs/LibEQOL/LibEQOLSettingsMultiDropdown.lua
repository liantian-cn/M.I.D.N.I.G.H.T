local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 23000001
local _, lib = pcall(LibStub, MODULE_MAJOR)
if not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

LibEQOL_MultiDropdownMixin = CreateFromMixins(SettingsDropdownControlMixin)

local SUMMARY_CHAR_LIMIT = 80
local function NormalizeSelection(selection)
	local map = {}
	if type(selection) ~= "table" then
		return map
	end

	local hasArrayPart = #selection > 0
	local arrayHasNonBoolean = false

	if hasArrayPart then
		for i = 1, #selection do
			local value = selection[i]
			if value ~= nil and type(value) ~= "boolean" then
				arrayHasNonBoolean = true
				break
			end
		end
	end

	if hasArrayPart and arrayHasNonBoolean then
		for _, value in ipairs(selection) do
			if value ~= nil and (type(value) == "string" or type(value) == "number") then map[value] = true end
		end
	else
		for key, value in pairs(selection) do
			if value and (type(key) == "string" or type(key) == "number") then map[key] = true end
		end
	end
	return map
end

local function CopySelection(selection)
	local copy = {}
	if type(selection) ~= "table" then
		return copy
	end
	for key, value in pairs(selection) do
		if value then copy[key] = true end
	end
	return copy
end

local function SortMixedKeys(keys)
	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		if ta == tb then
			if ta == "number" then return a < b end
			if ta == "string" then return a < b end
			return tostring(a) < tostring(b)
		end
		if ta == "number" then return true end
		if tb == "number" then return false end
		return tostring(a) < tostring(b)
	end)
	return keys
end

function LibEQOL_MultiDropdownMixin:OnLoad()
	-- erzeugt self.Control, self.Control.Dropdown, Tooltip-Verhalten etc.
	SettingsDropdownControlMixin.OnLoad(self)

	if self.Summary then
		self.Summary:SetText("")
		self.Summary:Hide()
	end

	self.selectionCache = nil
	self.summaryAnchored = nil
	self:EnsureSummaryAnchors()
end

-- Guard against missing element data while defaulting/resetting
function LibEQOL_MultiDropdownMixin:GetSetting()
	if self.initializer and self.initializer.GetSetting then return self.initializer:GetSetting() end
	if self.data and self.data.GetSetting then return self.data:GetSetting() end
	return nil
end

function LibEQOL_MultiDropdownMixin:CloneOption(option)
	local cloned = {}
	if type(option) == "table" then
		for key, value in pairs(option) do
			cloned[key] = value
		end
	else
		cloned.value = option
	end

	if cloned.value == nil then cloned.value = cloned.text end
	if cloned.value == nil and cloned.label then cloned.value = cloned.label end

	local fallback = cloned.text or cloned.label or tostring(cloned.value or "")
	if cloned.value == nil then cloned.value = fallback end

	cloned.label = cloned.label or fallback
	cloned.text = cloned.text or fallback

	return cloned
end

function LibEQOL_MultiDropdownMixin:SetOptions(list)
	if type(list) ~= "table" then
		self.options = {}
		return
	end

	local usesIndexOrder = #list > 0
	local normalized = {}

	if usesIndexOrder then
		for _, option in ipairs(list) do
			table.insert(normalized, self:CloneOption(option))
		end
	else
		local orderedKeys = self.optionOrder
		local seen = nil
		if orderedKeys then
			seen = {}
			for _, key in ipairs(orderedKeys) do
				if key ~= "_order" and list[key] ~= nil then
					local option = list[key]
					if type(option) == "table" then
						table.insert(normalized, self:CloneOption(option))
					else
						table.insert(normalized, self:CloneOption({ value = key, text = option }))
					end
					seen[key] = true
				end
			end
		end

		for key, option in pairs(list) do
			if key ~= "_order" and (not seen or not seen[key]) then
				if type(option) == "table" then
					table.insert(normalized, self:CloneOption(option))
				else
					table.insert(normalized, self:CloneOption({ value = key, text = option }))
				end
			end
		end
	end

	self.options = normalized
	self.selectionCache = nil
end

function LibEQOL_MultiDropdownMixin:GetOptions()
	if self.optionfunc then
		local result = self.optionfunc()
		if type(result) == "table" then
			self:SetOptions(result)
		else
			self.options = {}
		end
	end

	return self.options or {}
end

function LibEQOL_MultiDropdownMixin:Init(initializer)
	if not initializer or not initializer.GetData then return end
	-- Unsere eigenen Daten zuerst setzen
	self.initializer = initializer

	local data = initializer:GetData() or {}
	-- data = { var = "abc", label = "...", options = {...}, db = myDB, getSelection = ..., setSelection = ... }

	self.var = data.var
	self.subvar = data.subvar
	self.db = data.db
	self.optionfunc = data.optionfunc
	self.optionOrder = type(data.order) == "table" and data.order or nil
	self.isSelectedFunc = data.isSelectedFunc or data.isSelected
	self.setSelectedFunc = data.setSelectedFunc or data.setSelected
	self.getSelectionFunc = data.getSelection or data.get
	self.setSelectionFunc = data.setSelection or data.set
	self.summaryFunc = data.summaryFunc or data.summary
	self.defaultSelection = self.defaultSelection or NormalizeSelection(data.defaultSelection or data.default)
	self.categoryID = self.categoryID or data.categoryID
	-- Default caption behaviour for empty state
	if data.customText ~= nil then
		self.customDefaultText = data.customText
	elseif data.customDefaultText ~= nil then
		self.customDefaultText = data.customDefaultText
	end
	self.hideSummary = data.hideSummary
	self.callback = data.callback
	self.data = data

	self:SetOptions(data.options or data.values or {})

	-- Jetzt Basis-Init, das InitDropdown + EvaluateState ruft (unsere überschriebenen Versionen)
	self._eqolSuppressSync = true -- avoid re-entrant RepairDisplay during init
	SettingsDropdownControlMixin.Init(self, initializer)
	self:EnsureDefaultCallbacks()
	self._eqolSuppressSync = nil
	-- Label ggf. anpassen
	if data.label then self.Text:SetText(data.label) end

	-- Summary initial anzeigen
	if not self.hideSummary then
		self:RefreshSummary()
	end
end

-- OVERRIDE: Avoid regenerating the dropdown menu on value changes when using scroll mode.
-- In scroll mode the menu is virtualized via ScrollBox and a full InitDropdown during an
-- open menu can cause elements to jump/reorder until the scrollbox reanchors.
function LibEQOL_MultiDropdownMixin:SetValue(value)
	local useScroll = self.data and type(self.data.height) == "number" and self.data.height > 0
	if useScroll then
		-- Keep caches in sync; open menu will refresh via MenuResponse.Refresh.
		self.selectionCache = nil
		if not self.hideSummary then
			self:RefreshSummary()
		end
		return
	end

	-- Default dropdown behavior for non-scroll mode.
	self:InitDropdown()
	if not self.hideSummary then
		self:RefreshSummary()
	end
end

-- Auswahlmodell

function LibEQOL_MultiDropdownMixin:GetLegacySelectionTable()
	if type(self.db) ~= "table" or not self.var then
		self.legacySelection = self.legacySelection or {}
		return self.legacySelection
	end

	local container = self.db[self.var]
	if type(container) ~= "table" then
		container = {}
		self.db[self.var] = container
	end

	if self.subvar then
		if type(container[self.subvar]) ~= "table" then container[self.subvar] = {} end
		container = container[self.subvar]
	end

	return container
end

function LibEQOL_MultiDropdownMixin:RefreshSelectionCache()
	local selection

	if self.getSelectionFunc then
		local ok, result = pcall(self.getSelectionFunc)
		if ok then selection = NormalizeSelection(result) end
	end

	if not selection and self.isSelectedFunc then
		selection = {}
		for _, opt in ipairs(self:GetOptions()) do
			if opt.value ~= nil then
				local ok, selected = pcall(self.isSelectedFunc, opt.value, opt)
				if ok and selected then selection[opt.value] = true end
			end
		end
	end

	if not selection then
		selection = NormalizeSelection(self:GetLegacySelectionTable())
	end

	self.selectionCache = selection or {}
	return self.selectionCache
end

function LibEQOL_MultiDropdownMixin:GetSelectionMap()
	return self.selectionCache or self:RefreshSelectionCache()
end

function LibEQOL_MultiDropdownMixin:GetSelectionMapSnapshot()
	return CopySelection(self:GetSelectionMap())
end

function LibEQOL_MultiDropdownMixin:IsSelected(key, option)
	if self.isSelectedFunc then
		local ok, result = pcall(self.isSelectedFunc, key, option)
		if ok and result ~= nil then return result and true or false end
	end

	return self:GetSelectionMap()[key] == true
end

function LibEQOL_MultiDropdownMixin:ApplyLegacySelection(selection)
	local target = self:GetLegacySelectionTable()
	for existing in pairs(target) do
		target[existing] = nil
	end
	for k, v in pairs(selection) do
		if v then target[k] = true end
	end
end

function LibEQOL_MultiDropdownMixin:SetSelected(key, shouldSelect, option)
	local selection = self:GetSelectionMapSnapshot()

	if shouldSelect then
		selection[key] = true
	else
		selection[key] = nil
	end

	if self.setSelectedFunc then
		pcall(self.setSelectedFunc, key, shouldSelect, option)
	elseif self.setSelectionFunc then
		pcall(self.setSelectionFunc, CopySelection(selection), option)
	else
		self:ApplyLegacySelection(selection)
	end

	if self.getSelectionFunc or self.isSelectedFunc or self.db or self.var or self.subvar then
		self.selectionCache = nil
		selection = self:GetSelectionMap()
	else
		self.selectionCache = selection
	end

	self:SyncSetting(selection)
end

function LibEQOL_MultiDropdownMixin:SyncSetting(selection)
	if self._eqolSuppressSync then return end
	local setting = self:GetSetting()
	if not setting then return end

	setting:SetValue(self:SerializeSelection(selection or self:GetSelectionMap()))
end

function LibEQOL_MultiDropdownMixin:ToggleOption(key, option)
	self:RefreshSelectionCache()
	local newState = not self:IsSelected(key, option)
	self:SetSelected(key, newState, option)
	self:RefreshSummary()
end

function LibEQOL_MultiDropdownMixin:SerializeSelection(tbl)
	if type(tbl) ~= "table" then return "" end

	local keys = {}
	for k, v in pairs(tbl) do
		if v and (type(k) == "string" or type(k) == "number") then table.insert(keys, k) end
	end
	SortMixedKeys(keys)
	return table.concat(keys, ",")
end

function LibEQOL_MultiDropdownMixin:RefreshSummary()
	if self.hideSummary or not self.Summary then return end

	self:RefreshSelectionCache()
	self:EnsureSummaryAnchors()

	local texts = {}
	for _, opt in ipairs(self:GetOptions()) do
		if opt.value ~= nil and self:IsSelected(opt.value, opt) then table.insert(texts, opt.text or tostring(opt.value)) end
	end

	local summary = nil
	if self.summaryFunc then
		local ok, custom = pcall(self.summaryFunc, self:GetSelectionMap(), texts)
		if ok and custom then summary = tostring(custom) end
	end

	summary = summary or self:FormatSummaryText(texts)
	self.Summary:SetText(summary)
	self.Summary:Show()
end

function LibEQOL_MultiDropdownMixin:ApplyDefaultSelection()
	local selection = CopySelection(self.defaultSelection or {})
	if self.setSelectionFunc then
		pcall(self.setSelectionFunc, selection)
	else
		self:ApplyLegacySelection(selection)
	end
	self.selectionCache = nil
	self:RefreshSummary()
	self:SyncSetting(selection)
end

function LibEQOL_MultiDropdownMixin:EnsureDefaultCallbacks()
	if self.defaultCallbacksRegistered then
		return
	end
	self.defaultCallbacksRegistered = true

	EventRegistry:RegisterCallback("Settings.Defaulted", function(_, setting)
		if setting == self:GetSetting() then
			self:ApplyDefaultSelection()
		end
	end, self)
	EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function(_, category)
		if not self.categoryID or not category or not category.GetID then
			return
		end
		if category:GetID() == self.categoryID then
			self:ApplyDefaultSelection()
		end
	end, self)
end

function LibEQOL_MultiDropdownMixin:EnsureSummaryAnchors()
	if self.summaryAnchored then return end

	if not (self.Summary and self.Control and self.Control.Dropdown) then return end

	self.summaryAnchored = true
	self.Summary:ClearAllPoints()
	self.Summary:SetPoint("TOPLEFT", self.Control.Dropdown, "BOTTOMLEFT", 0, -2)
	self.Summary:SetPoint("TOPRIGHT", self.Control.Dropdown, "BOTTOMRIGHT", 0, -2)
	self.Summary:SetWidth(self.Control.Dropdown:GetWidth())
end

function LibEQOL_MultiDropdownMixin:GetSummaryWidthLimit()
	if self.Control and self.Control.Dropdown then return self.Control.Dropdown:GetWidth() end

	if self.Summary then return self.Summary:GetWidth() end
end

function LibEQOL_MultiDropdownMixin:GetSummaryMeasureFontString()
	if self.summaryMeasure and self.summaryMeasure:IsObjectType("FontString") then return self.summaryMeasure end

	if not self.Summary then return nil end

	local fs = self.Summary:GetParent():CreateFontString(nil, "OVERLAY")
	if not fs then return nil end

	fs:SetFontObject(self.Summary:GetFontObject())
	fs:Hide()
	fs:SetWordWrap(false)
	fs:SetNonSpaceWrap(false)
	fs:SetSpacing(0)
	self.summaryMeasure = fs
	return fs
end

function LibEQOL_MultiDropdownMixin:WouldExceedSummaryWidth(text, widthLimit)
	if not text or text == "" then return false end

	if not widthLimit then return #text > SUMMARY_CHAR_LIMIT end

	local measure = self:GetSummaryMeasureFontString()
	if not measure then return #text > SUMMARY_CHAR_LIMIT end

	measure:SetFontObject(self.Summary:GetFontObject())
	measure:SetText(text)
	local getWidth = measure.GetUnboundedStringWidth or measure.GetStringWidth
	return getWidth(measure) > widthLimit
end

function LibEQOL_MultiDropdownMixin:FormatSummaryText(texts)
	if #texts == 0 then return "–" end

	local widthLimit = self:GetSummaryWidthLimit()
	local summary = ""
	local overflow = 0

	for index, text in ipairs(texts) do
		local candidate = (summary == "") and text or (summary .. ", " .. text)
		if widthLimit and summary ~= "" and self:WouldExceedSummaryWidth(candidate, widthLimit) then
			overflow = #texts - index + 1
			break
		elseif widthLimit and summary == "" and self:WouldExceedSummaryWidth(candidate, widthLimit) then
			summary = text
			overflow = #texts - index
			break
		else
			summary = candidate
		end
	end

	if overflow > 0 then
		local overflowText = (" … (+%d)"):format(overflow)
		local candidate = summary .. overflowText
		if widthLimit and self:WouldExceedSummaryWidth(candidate, widthLimit) then candidate = summary .. " …" end
		summary = candidate
	end

	if not widthLimit and #summary > SUMMARY_CHAR_LIMIT then summary = summary:sub(1, SUMMARY_CHAR_LIMIT) .. " …" end

	return summary
end

-- Wir ersetzen komplett die Dropdown-Initialisierung des Basis-Mixins
function LibEQOL_MultiDropdownMixin:InitDropdown()
	local setting = self:GetSetting()
	local initializer = self:GetElementData()

	-- Wir bauen unsere eigene optionsFunc auf Basis self.options
	local function optionsFunc() return self:GetOptions() end

	-- Tooltip wie beim Original bauen
	local initTooltip = Settings.CreateOptionsInitTooltip(setting, initializer:GetName(), initializer:GetTooltip(), optionsFunc)

	-- Unsere Multi-Checkbox-Variante des Dropdown-Menüs
	self:SetupDropdownMenu(self.Control.Dropdown, setting, optionsFunc, initTooltip)

	-- Steppers brauchst du bei Multi-Select i.d.R. nicht
	if self.Control and self.Control.SetSteppersShown then self.Control:SetSteppersShown(false) end
end

-- OVERRIDE: kein Settings.InitDropdown mehr, wir bauen das Menü selbst
function LibEQOL_MultiDropdownMixin:SetupDropdownMenu(button, setting, optionsFunc, initTooltip)
	local dropdown = button or self.Control.Dropdown

	-- Default caption: empty unless explicitly requested
	local defaultText
	if self.customDefaultText ~= nil then
		defaultText = tostring(self.customDefaultText)
	else
		defaultText = ""
	end
	dropdown:SetDefaultText(defaultText)

	dropdown:SetupMenu(function(_, rootDescription)
		local useScroll = self.data and type(self.data.height) == "number" and self.data.height > 0

		if useScroll then
			rootDescription:SetScrollMode(self.data.height)
		else
			if rootDescription.SetGridMode then
				rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)
			end
		end

		self:RefreshSelectionCache()
		local opts = optionsFunc() or {}

		for _, opt in ipairs(opts) do
			if opt.value ~= nil then
				local label = opt.label or opt.text or tostring(opt.value)

				rootDescription:CreateCheckbox(label, function() return self:IsSelected(opt.value, opt) end, function()
					self:ToggleOption(opt.value, opt)
					if self.callback then self.callback(opt) end
				end, opt)
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

	dropdown:SetScript("OnEnter", function()
		ButtonStateBehaviorMixin.OnEnter(dropdown)
		DefaultTooltipMixin.OnEnter(dropdown)
	end)

	dropdown:SetScript("OnLeave", function()
		ButtonStateBehaviorMixin.OnLeave(dropdown)
		DefaultTooltipMixin.OnLeave(dropdown)
	end)
end
