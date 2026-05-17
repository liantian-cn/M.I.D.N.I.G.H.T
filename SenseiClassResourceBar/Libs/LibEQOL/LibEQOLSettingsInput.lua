local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 23000001
local _, lib = pcall(LibStub, MODULE_MAJOR)
if not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

LibEQOL_InputControlMixin = CreateFromMixins(SettingsControlMixin)

local DEFAULT_INPUT_MAX_WIDTH = 170
local DEFAULT_INPUT_MIN_WIDTH = 80

local function formatInputValue(self, value)
	if self.formatter then
		local ok, formatted = pcall(self.formatter, value)
		if ok and formatted ~= nil then
			return tostring(formatted)
		end
	end
	if value == nil then
		return ""
	end
	return tostring(value)
end

local function parseNumeric(text)
	local cleaned = (text or ""):gsub(",", ".")
	return tonumber(cleaned)
end

local function normalizeRange(minValue, maxValue)
	if minValue ~= nil and maxValue ~= nil and minValue > maxValue then
		return maxValue, minValue
	end
	return minValue, maxValue
end

function LibEQOL_InputControlMixin:ConfigureEditBox(editBox, multiline)
	if not editBox then
		return
	end

	editBox:SetAutoFocus(false)

	local prevOnTextChanged = editBox:GetScript("OnTextChanged")
	editBox:SetScript("OnTextChanged", function(box, userInput)
		if prevOnTextChanged then
			prevOnTextChanged(box, userInput)
		end
		self:HandleTextChanged(box, userInput)
	end)

	local prevOnEscape = editBox:GetScript("OnEscapePressed")
	editBox:SetScript("OnEscapePressed", function(box)
		if prevOnEscape then
			prevOnEscape(box)
		end
		self:Revert(box)
	end)

	editBox:SetScript("OnEditFocusLost", function(box)
		self:Commit(box)
	end)

	editBox:SetScript("OnEditFocusGained", function(box)
		if self.selectAllOnFocus then
			box:HighlightText()
		end
	end)

	if not multiline then
		editBox:SetScript("OnEnterPressed", function(box)
			self:Commit(box)
			box:ClearFocus()
		end)
	end
end

function LibEQOL_InputControlMixin:OnLoad()
	SettingsControlMixin.OnLoad(self)

	self.Input = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
	self.Input:SetHeight(20)
	self.Input:SetJustifyH("LEFT")
	self.Input:SetPoint("LEFT", self, "CENTER", -80, 0)
	self.Input:SetPoint("RIGHT", self, "RIGHT", -12, 0)
	self:ConfigureEditBox(self.Input, false)

	self.ScrollFrame = CreateFrame("ScrollFrame", nil, self, "InputScrollFrameTemplate")
	self.ScrollFrame.hideCharCount = true
	self.ScrollFrame:SetScript("OnSizeChanged", function()
		self:UpdateScrollFrameWidth()
	end)
	self.ScrollFrame:Hide()
	if self.ScrollFrame.CharCount then
		self.ScrollFrame.CharCount:Hide()
	end

	self.ScrollEditBox = self.ScrollFrame.EditBox
	self.ScrollEditBox:SetJustifyH("LEFT")
	self:ConfigureEditBox(self.ScrollEditBox, true)
end

function LibEQOL_InputControlMixin:Init(initializer)
	SettingsControlMixin.Init(self, initializer)
	self.initializer = initializer

	local data = initializer.data or {}
	self.data = data
	self.multiline = not not data.multiline
	self.numeric = not not data.numeric
	self.readOnly = not not data.readOnly
	self.formatter = data.formatter
	self.selectAllOnFocus = data.selectAllOnFocus or self.readOnly
	self.maxChars = data.maxChars
	self.inputWidth = data.inputWidth
	self.multilineHeight = data.multilineHeight or data.height
	self.placeholder = data.placeholder
	self.justifyH = data.justifyH
	self.minValue, self.maxValue = normalizeRange(data.min, data.max)
	self.clampToRange = data.clampToRange ~= false

	self:ApplyLayout()
	self:SetValue(self:GetSetting():GetValue())
	self:EvaluateState()
end

function LibEQOL_InputControlMixin:GetEditBox()
	return self.multiline and self.ScrollEditBox or self.Input
end

function LibEQOL_InputControlMixin:UpdateScrollFrameWidth()
	local scrollFrame = self.ScrollFrame
	if not scrollFrame then
		return
	end
	local width = scrollFrame:GetWidth() or 0
	if width <= 0 then
		return
	end
	local editBox = scrollFrame.EditBox
	if editBox then
		editBox:SetWidth(width - 18)
		if editBox.Instructions then
			editBox.Instructions:SetWidth(width)
		end
	end
end

function LibEQOL_InputControlMixin:ApplyLayout()
	if self.multiline then
		self.Input:Hide()
		self.ScrollFrame:Show()
		local height = tonumber(self.multilineHeight) or 80
		self:SetHeight(height)
		self.ScrollFrame:ClearAllPoints()
		local inputWidth = self.inputWidth
		local totalWidth = self:GetWidth() or 0
		local leftOffset = -80
		local rightPadding = 24
		local leftX = totalWidth * 0.5 + leftOffset
		local available = totalWidth - leftX - rightPadding
		if available < DEFAULT_INPUT_MIN_WIDTH then
			available = DEFAULT_INPUT_MIN_WIDTH
		end
		if inputWidth and inputWidth > 0 then
			local width = inputWidth
			if width > available then
				width = available
			end
			if width > DEFAULT_INPUT_MAX_WIDTH then
				width = DEFAULT_INPUT_MAX_WIDTH
			end
			self.ScrollFrame:SetPoint("TOPLEFT", self, "TOP", leftOffset, -6)
			self.ScrollFrame:SetPoint("BOTTOMLEFT", self, "BOTTOM", leftOffset, 6)
			self.ScrollFrame:SetWidth(width)
		else
			self.ScrollFrame:SetPoint("TOPLEFT", self, "TOP", leftOffset, -6)
			self.ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -rightPadding, 6)
		end
		self:UpdateScrollFrameWidth()
		if InputScrollFrame_SetInstructions then
			InputScrollFrame_SetInstructions(self.ScrollFrame, self.placeholder or "")
		end
	else
		self.ScrollFrame:Hide()
		self.Input:Show()
		self:SetHeight(26)
		self.Input:ClearAllPoints()
		self.Input:SetPoint("LEFT", self, "CENTER", -80, 0)
		local maxWidth = DEFAULT_INPUT_MAX_WIDTH
		local totalWidth = self:GetWidth() or 0
		if totalWidth > 0 then
			local leftOffset = -80
			local rightPadding = 24
			local leftX = totalWidth * 0.5 + leftOffset
			local available = totalWidth - leftX - rightPadding
			if available < DEFAULT_INPUT_MIN_WIDTH then
				available = DEFAULT_INPUT_MIN_WIDTH
			end
			if available < maxWidth then
				maxWidth = available
			end
		end
		if self.inputWidth and self.inputWidth > 0 then
			local inputWidth = self.inputWidth
			if inputWidth > maxWidth then
				inputWidth = maxWidth
			end
			self.Input:SetWidth(inputWidth)
		else
			self.Input:SetWidth(maxWidth)
		end
	end

	local editBox = self:GetEditBox()
	if self.maxChars then
		editBox:SetMaxLetters(self.maxChars)
	else
		editBox:SetMaxLetters(0)
	end
	if self.justifyH then
		editBox:SetJustifyH(self.justifyH)
	end
end

function LibEQOL_InputControlMixin:HandleTextChanged(box, userInput)
	if self._suppressInput then
		return
	end
	if self.readOnly and userInput then
		self._suppressInput = true
		box:SetText(self.displayValue or "")
		box:HighlightText()
		self._suppressInput = nil
	end
end

function LibEQOL_InputControlMixin:Revert(box)
	self._suppressInput = true
	box:SetText(self.displayValue or "")
	box:HighlightText()
	self._suppressInput = nil
	box:ClearFocus()
end

function LibEQOL_InputControlMixin:Commit(box)
	if self.readOnly or not self:IsEnabled() then
		self:Revert(box)
		return
	end
	local text = box:GetText() or ""
	local value = text
	if self.numeric then
		local num = parseNumeric(text)
		if not num then
			self:Revert(box)
			return
		end
		value = num

		if self.minValue ~= nil and value < self.minValue then
			if self.clampToRange then
				value = self.minValue
			else
				self:Revert(box)
				return
			end
		end

		if self.maxValue ~= nil and value > self.maxValue then
			if self.clampToRange then
				value = self.maxValue
			else
				self:Revert(box)
				return
			end
		end
	end

	if self:ShouldInterceptSetting(value) then
		self:Revert(box)
		return
	end

	if value ~= self.currentValue then
		self.currentValue = value
		self:GetSetting():SetValue(value)
	end

	self:SetValue(self.currentValue)
end

function LibEQOL_InputControlMixin:SetValue(value)
	self.currentValue = value
	self.displayValue = formatInputValue(self, value)
	local editBox = self:GetEditBox()
	self._suppressInput = true
	editBox:SetText(self.displayValue or "")
	self._suppressInput = nil
end

function LibEQOL_InputControlMixin:OnSettingValueChanged(setting, value)
	SettingsControlMixin.OnSettingValueChanged(self, setting, value)
	self:SetValue(value)
end

function LibEQOL_InputControlMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self)
	local enabled = self:IsEnabled()
	self:DisplayEnabled(enabled)
	local editBox = self:GetEditBox()
	if enabled then
		editBox:Enable()
	else
		editBox:Disable()
	end
end
