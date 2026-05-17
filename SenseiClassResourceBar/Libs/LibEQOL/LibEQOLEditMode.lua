local MODULE_MAJOR, BASE_MAJOR, MINOR = "LibEQOLEditMode-1.0", "LibEQOL-1.0", 23000001
local LibStub = _G.LibStub
assert(LibStub, MODULE_MAJOR .. " requires LibStub")
local C_Timer = _G.C_Timer

-- Primary sublib name; BASE_MAJOR remains as an alias for existing callers.
local moduleLib, moduleMinor = LibStub:GetLibrary(MODULE_MAJOR, true)
local baseLib, baseMinor = LibStub:GetLibrary(BASE_MAJOR, true)
local lib = moduleLib or baseLib
local oldMinor = moduleMinor or baseMinor

if baseMinor and (not oldMinor or baseMinor > oldMinor) then
	lib, oldMinor = baseLib, baseMinor
end

if oldMinor and oldMinor >= MINOR then
	LibStub.libs[MODULE_MAJOR] = lib
	LibStub.minors[MODULE_MAJOR] = oldMinor
	LibStub.libs[BASE_MAJOR] = lib
	LibStub.minors[BASE_MAJOR] = oldMinor
	return
end

if not lib then
	lib = LibStub:NewLibrary(MODULE_MAJOR, MINOR)
else
	LibStub.libs[MODULE_MAJOR] = lib
	LibStub.minors[MODULE_MAJOR] = MINOR
end
LibStub.libs[BASE_MAJOR] = lib
LibStub.minors[BASE_MAJOR] = MINOR

-- Namespaces/state ----------------------------------------------------------------
lib.internal = lib.internal or {}
local Internal = lib.internal

local State = {
	selectionRegistry = lib.selectionRegistry or {},
	frameHandlers = lib.frameHandlers or {},
	defaultPositions = lib.defaultPositions or {},
	settingSheets = lib.settingSheets or {},
	buttonSpecs = lib.buttonSpecs or {},
	resetToggles = lib.resetToggles or {},
	settingsResetToggles = lib.settingsResetToggles or {},
	collapseFlags = lib.collapseFlags or {},
	collapseExclusiveFlags = lib.collapseExclusiveFlags or {},
	settingsSpacingOverrides = lib.settingsSpacingOverrides or {},
	settingsMaxHeightOverrides = lib.settingsMaxHeightOverrides or {},
	sliderHeightOverrides = lib.sliderHeightOverrides or {},
	rowHeightOverrides = lib.rowHeightOverrides or {},
	widgetPools = lib.widgetPools or {},
	overlayToggleFlags = lib.overlayToggleFlags or {},
	dragPredicates = lib.dragPredicates or {},
	managerToggleSpecs = lib.managerToggleSpecs or {},
	managerToggleState = lib.managerToggleState or {},
	managerToggleOrder = lib.managerToggleOrder or {},
	managerCategorySpecs = lib.managerCategorySpecs or {},
	managerCategoryOrder = lib.managerCategoryOrder or {},
	layoutSnapshot = Internal.layoutNameSnapshot,
	pendingDeletedLayouts = lib.pendingDeletedLayouts or {},
}

lib.selectionRegistry = State.selectionRegistry
lib.frameHandlers = State.frameHandlers
lib.defaultPositions = State.defaultPositions
lib.settingSheets = State.settingSheets
lib.buttonSpecs = State.buttonSpecs
lib.resetToggles = State.resetToggles
lib.settingsResetToggles = State.settingsResetToggles
lib.collapseFlags = State.collapseFlags
lib.collapseExclusiveFlags = State.collapseExclusiveFlags
lib.settingsSpacingOverrides = State.settingsSpacingOverrides
lib.settingsMaxHeightOverrides = State.settingsMaxHeightOverrides
lib.sliderHeightOverrides = State.sliderHeightOverrides
lib.rowHeightOverrides = State.rowHeightOverrides
lib.widgetPools = State.widgetPools
lib.overlayToggleFlags = State.overlayToggleFlags
lib.dragPredicates = State.dragPredicates
lib.managerToggleSpecs = State.managerToggleSpecs
lib.managerToggleState = State.managerToggleState
lib.managerToggleOrder = State.managerToggleOrder
lib.managerCategorySpecs = State.managerCategorySpecs
lib.managerCategoryOrder = State.managerCategoryOrder
lib.pendingDeletedLayouts = State.pendingDeletedLayouts

local DEFAULT_SETTINGS_SPACING = 2
local DEFAULT_SLIDER_HEIGHT = 32
local COLOR_BUTTON_WIDTH = 22
local DEFAULT_INPUT_MAX_WIDTH = 193
local DEFAULT_INPUT_MIN_WIDTH = 80
local DROPDOWN_COLOR_MAX_WIDTH = 200
local DEFAULT_MANAGER_TOGGLE_MAX_HEIGHT = 220
local DEFAULT_MANAGER_TOGGLE_ROW_HEIGHT = 32
local MANAGER_TOGGLE_PANEL_PADDING = 12
local MANAGER_TOGGLE_CATEGORY_SPACING = 8
local MANAGER_TOGGLE_SECTION_SPACING = 4
local MANAGER_TOGGLE_COLUMN_SPACING = 12
local MANAGER_TOGGLE_EXPANDER_HEIGHT = 24
local MANAGER_TOGGLE_EXPANDER_SPACING = 2
local DEFAULT_MANAGER_TOGGLE_CATEGORY_ID = "_default"
local DEFAULT_MANAGER_TOGGLE_CATEGORY_LABEL = "Other"

local function normalizeManagerCategoryId(id, label)
	if id and id ~= "" then
		return id
	end
	if label and label ~= "" then
		return label
	end
	return DEFAULT_MANAGER_TOGGLE_CATEGORY_ID
end

local function normalizeSpacing(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil or numberValue < 0 then
		return fallback
	end
	return numberValue
end

local function normalizePositive(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil or numberValue <= 0 then
		return fallback
	end
	return numberValue
end

local function setRowHeightOverride(frame, kind, value)
	if not frame then
		return
	end
	local normalized = normalizePositive(value, nil)
	local overrides = State.rowHeightOverrides[frame]
	if normalized == nil then
		if overrides then
			overrides[kind] = nil
			if next(overrides) == nil then
				State.rowHeightOverrides[frame] = nil
			end
		end
		return
	end
	if not overrides then
		overrides = {}
		State.rowHeightOverrides[frame] = overrides
	end
	overrides[kind] = normalized
end

local function getRowHeightOverride(frame, kind)
	local overrides = frame and State.rowHeightOverrides[frame]
	if overrides then
		return overrides[kind]
	end
end

local function applyRowHeightOverride(frame, selectionParent, kind)
	if not frame then
		return
	end
	local height = getRowHeightOverride(selectionParent, kind)
	if height then
		frame.fixedHeight = height
		frame:SetHeight(height)
	end
	return height
end

local function getFrameSettingsSpacing(frame)
	if not frame then
		return DEFAULT_SETTINGS_SPACING
	end
	local override = State.settingsSpacingOverrides[frame]
	return normalizeSpacing(override, DEFAULT_SETTINGS_SPACING)
end

local function getFrameSliderHeight(frame)
	if not frame then
		return DEFAULT_SLIDER_HEIGHT
	end
	local override = getRowHeightOverride(frame, "slider")
	if override then
		return normalizePositive(override, DEFAULT_SLIDER_HEIGHT)
	end
	local legacy = State.sliderHeightOverrides[frame]
	return normalizePositive(legacy, DEFAULT_SLIDER_HEIGHT)
end

local function getFrameSettingsMaxHeight(frame)
	if not frame then
		return nil
	end
	return normalizePositive(State.settingsMaxHeightOverrides[frame], nil)
end

local function FixScrollBarInside(scroll)
	local sb = scroll and scroll.ScrollBar
	if not sb or scroll._eqolScrollBarFixed then
		return
	end
	scroll._eqolScrollBarFixed = true

	local keepW = sb:GetWidth()

	sb:ClearAllPoints()
	sb:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -2, -16)
	sb:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -2, 16)

	if (sb:GetWidth() or 0) < 1 then
		sb:SetWidth((keepW and keepW > 0) and keepW or 16)
	end
end

local function UpdateScrollChildWidthFor(scroll, child)
	if not (scroll and child) then
		return
	end

	local sb = scroll.ScrollBar
	local sbW = 0
	if sb and sb:IsShown() then
		sbW = sb:GetWidth() or 0
		if sbW < 1 then
			sbW = 16
		end
	end

	local paddingRight = 6
	local w = (scroll:GetWidth() or 0) - sbW - paddingRight
	if w < 1 then
		return
	end

	if child._eqolLastWidth ~= w then
		child._eqolLastWidth = w
		child:SetWidth(w)
		for _, row in ipairs({ child:GetChildren() }) do
			if row and row.SetWidth then
				row:SetWidth(w)
				if row.ApplyLayout then
					row:ApplyLayout()
				end
			end
		end
	end
end

local function UpdateScrollChildWidth(dialog)
	local scroll = dialog and dialog.SettingsScroll
	local child = dialog and dialog.Settings
	if not (scroll and child) then
		return
	end
	UpdateScrollChildWidthFor(scroll, child)
end

local function ApplySettingsRowWidth(row, settings)
	if not (row and row.SetWidth and settings) then
		return
	end
	local width = settings._eqolLastWidth or settings:GetWidth() or 0
	if width > 0 then
		row:SetWidth(width)
	end
end

-- Blizzard frames we also toggle via the manager eye (if they exist)
Internal.managerExtraFrames = Internal.managerExtraFrames
	or {
		"PlayerFrame",
		"TargetFrame",
		"FocusFrame",
		"PartyFrame",
		"CompactRaidFrameContainer",
		"BossTargetFrameContainer",
		"ArenaEnemyFramesContainer",
		"MinimapCluster",
		"MainMenuBar",
		"ObjectiveTrackerFrame",
		-- Action bars / buttons
		"MainActionBar",
		"MultiBarBottomLeft",
		"MultiBarBottomRight",
		"MultiBarRight",
		"MultiBarLeft",
		"MultiBar5",
		"MultiBar6",
		"MultiBar7",
		"MultiBar8",
		"StanceBar",
		"StanceBarFrame",
		"PetActionBar",
		"PossessActionBar",
		"ExtraAbilityContainer",
		"MainMenuBarVehicleLeaveButton",
		"EncounterBar",
		"UtilityCooldownViewer",
		"EssentialCooldownViewer",
		"BuffIconCooldownViewer",
		"BuffBarCooldownViewer",
		-- Bags / micromenu
		"BagsBar",
		"MicroMenuContainer",
		-- Tooltips / chat / loot
		"GameTooltipDefaultContainer",
		"ChatFrame1",
		"LootFrame",
		-- Unit frames
		"PetFrame",
		"CompactArenaFrame",
		"DurabilityFrame",
		"DebuffFrame",
		"BuffFrame",
		"TalkingHeadFrame",
		"MainStatusTrackingBarContainer",
		"SecondaryStatusTrackingBarContainer",
		"PlayerCastingBarFrame",
		-- Midnight only now
		"PersonalResourceDisplayFrame",
		"EncounterTimeline",
		"DamageMeter",
		"CriticalEncounterWarnings",
		"MediumEncounterWarnings",
		"MinorEncounterWarnings",
		"MirrorTimerContainer",
		"ArcheologyDigsideProgressBar",
		"VehicleSeatIndicator",
		"ExternalDefensivesFrame",
	}
Internal.managerHiddenFrames = Internal.managerHiddenFrames or {}
Internal.managerToggleMaxHeight = Internal.managerToggleMaxHeight or DEFAULT_MANAGER_TOGGLE_MAX_HEIGHT
Internal.managerToggleExpanded = Internal.managerToggleExpanded ~= false
Internal.managerEyeLocales = Internal.managerEyeLocales
	or {
		enUS = {
			show = "Show all windows",
			hide = "Hide all windows",
			body = "Toggles every edit mode window, including Blizzard frames.",
		},
		enGB = {
			show = "Show all windows",
			hide = "Hide all windows",
			body = "Toggles every edit mode window, including Blizzard frames.",
		},
		deDE = {
			show = "Alle Fenster einblenden",
			hide = "Alle Fenster ausblenden",
			body = "Schaltet alle Edit-Mode-Fenster inklusive Blizzard-Frames um.",
		},
		frFR = {
			show = "Afficher toutes les fenêtres",
			hide = "Masquer toutes les fenêtres",
			body = "Bascule toutes les fenêtres du mode édition, y compris celles de Blizzard.",
		},
		esES = {
			show = "Mostrar todas las ventanas",
			hide = "Ocultar todas las ventanas",
			body = "Alterna todas las ventanas del modo de edición, incluidas las de Blizzard.",
		},
		esMX = {
			show = "Mostrar todas las ventanas",
			hide = "Ocultar todas las ventanas",
			body = "Alterna todas las ventanas del modo de edición, incluidas las de Blizzard.",
		},
		itIT = {
			show = "Mostra tutte le finestre",
			hide = "Nascondi tutte le finestre",
			body = "Attiva o disattiva tutte le finestre della modalità di modifica, incluse quelle Blizzard.",
		},
		ptBR = {
			show = "Mostrar todas as janelas",
			hide = "Ocultar todas as janelas",
			body = "Alterna todas as janelas do modo de edição, incluindo as da Blizzard.",
		},
		ruRU = {
			show = "Показать все окна",
			hide = "Скрыть все окна",
			body = "Переключает все окна режима редактирования, включая окна Blizzard.",
		},
		koKR = {
			show = "모든 창 보이기",
			hide = "모든 창 숨기기",
			body = "블리자드 창을 포함한 모든 편집 모드 창을 전환합니다.",
		},
		zhCN = {
			show = "显示所有窗口",
			hide = "隐藏所有窗口",
			body = "切换所有编辑模式窗口（含暴雪框体）。",
		},
		zhTW = {
			show = "顯示所有視窗",
			hide = "隱藏所有視窗",
			body = "切換所有編輯模式視窗（包含暴雪框體）。",
		},
	}
setmetatable(Internal.managerEyeLocales, {
	__index = function(t)
		return t.enUS
	end,
})

-- frequently used globals ----------------------------------------------------------
local CreateFrame = _G.CreateFrame
local CopyTable = _G.CopyTable
local Mixin = _G.Mixin
local InCombatLockdown = _G.InCombatLockdown
local IsShiftKeyDown = _G.IsShiftKeyDown
local GetLocale = _G.GetLocale
local CreateUnsecuredObjectPool = _G.CreateUnsecuredObjectPool
local hooksecurefunc = _G.hooksecurefunc
local securecallfunction = _G.securecallfunction
local UIParent = _G.UIParent
local EventRegistry = _G.EventRegistry
local GameTooltip = _G.GameTooltip
local GameTooltip_Hide = _G.GameTooltip_Hide
local ColorPickerFrame = _G.ColorPickerFrame
local SOUNDKIT = _G.SOUNDKIT
local GetCursorPosition = _G.GetCursorPosition
local GetMouseFoci = _G.GetMouseFoci or _G.GetMouseFocus
local Enum = _G.Enum
local EditModeManagerFrame = _G.EditModeManagerFrame
local GenerateClosure = _G.GenerateClosure
local MinimalSliderWithSteppersMixin = _G.MinimalSliderWithSteppersMixin
local CreateMinimalSliderFormatter = _G.CreateMinimalSliderFormatter
local GetBuildInfo = _G.GetBuildInfo
local PlaySound = _G.PlaySound
local math = _G.math
local EditModeMagnetismManager = _G.EditModeMagnetismManager
local tostring = _G.tostring
local type = _G.type
local pairs = _G.pairs
local ipairs = _G.ipairs
local select = _G.select
local next = _G.next
local table = _G.table
local UIErrorsFrame = _G.UIErrorsFrame
local HUD_EDIT_MODE_COLLAPSE_OPTIONS = _G.HUD_EDIT_MODE_COLLAPSE_OPTIONS
local HUD_EDIT_MODE_EXPAND_OPTIONS = _G.HUD_EDIT_MODE_EXPAND_OPTIONS

local C_EditMode = _G.C_EditMode
local C_EditMode_GetLayouts = C_EditMode and C_EditMode.GetLayouts
local C_EditMode_ConvertLayoutInfoToString = C_EditMode and C_EditMode.ConvertLayoutInfoToString
local C_SpecializationInfo = _G.C_SpecializationInfo
local GetSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization

-- layout names are lazily resolved and cached to avoid repeated C_EditMode.GetLayouts calls.
local layoutNames = lib.layoutNames
	or setmetatable({ _G.LAYOUT_STYLE_MODERN or "Modern", _G.LAYOUT_STYLE_CLASSIC or "Classic" }, {
		__index = function(t, key)
			if type(key) ~= "number" or key <= 2 then
				return rawget(t, key)
			end
			local idx = key - 2
			local snapshot = State.layoutSnapshot or Internal.layoutNameSnapshot
			local cached = snapshot and snapshot[idx]
			if cached and cached ~= "" then
				rawset(t, key, cached)
				return cached
			end
			local layouts = C_EditMode_GetLayouts and C_EditMode_GetLayouts()
			layouts = layouts and layouts.layouts
			if not layouts then
				return nil
			end
			local name = layouts[idx] and layouts[idx].layoutName
			if name and name ~= "" then
				rawset(t, key, name)
			end
			return name
		end,
	})
lib.layoutNames = layoutNames

local function syncLayoutNameCache(snapshot)
	snapshot = snapshot or {}
	for key in pairs(layoutNames) do
		if type(key) == "number" and key > 2 then
			local idx = key - 2
			local name = snapshot[idx]
			if name and name ~= "" then
				rawset(layoutNames, key, name)
			else
				rawset(layoutNames, key, nil)
			end
		end
	end
	for idx, name in ipairs(snapshot) do
		local uiIndex = idx + 2
		if name and name ~= "" then
			rawset(layoutNames, uiIndex, name)
		else
			rawset(layoutNames, uiIndex, nil)
		end
	end
end

-- Setting types: we keep Blizzard enums but extend for custom widgets
lib.SettingType = lib.SettingType or CopyTable(Enum.EditModeSettingDisplayType)
lib.SettingType.Color = "Color"
lib.SettingType.CheckboxColor = "CheckboxColor"
lib.SettingType.DropdownColor = "DropdownColor"
lib.SettingType.MultiDropdown = "MultiDropdown"
lib.SettingType.Divider = "Divider"
lib.SettingType.Collapsible = "Collapsible"
lib.SettingType.Input = "Input"

-- Debug toggle lives on internal; defaults to false
Internal.debugEnabled = Internal.debugEnabled or false

-- Utilities -----------------------------------------------------------------------
local Util = {}

function Util:DebugTraceDialogChildren(label)
	if not Internal.debugEnabled then
		return
	end
	local dlg = Internal.dialog
	if not dlg or not dlg.Settings then
		print("[LibEQOL] Debug", label or "", "dialog/settings missing")
		return
	end
	local shown, total = 0, 0
	for _, child in ipairs({ dlg.Settings:GetChildren() }) do
		total = total + 1
		if child:IsShown() then
			shown = shown + 1
		end
	end
	print(string.format("[LibEQOL] Debug %s: %d shown / %d total children", label or "", shown, total))
end
Internal.DebugTraceDialogChildren = Util.DebugTraceDialogChildren

function Util:SortMixedKeys(keys)
	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		if ta == tb then
			if ta == "number" or ta == "string" then
				return a < b
			end
			return tostring(a) < tostring(b)
		end
		if ta == "number" then
			return true
		end
		if tb == "number" then
			return false
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function cloneOption(option, fallback)
	local cloned = {}
	if type(option) == "table" then
		for k, v in pairs(option) do
			cloned[k] = v
		end
	else
		cloned.value = option
	end
	if cloned.value == nil and fallback ~= nil then
		cloned.value = fallback
	end
	local defaultLabel = cloned.text or cloned.label or tostring(cloned.value or "")
	cloned.label = cloned.label or defaultLabel
	cloned.text = cloned.text or defaultLabel
	if cloned.value == nil then
		cloned.value = cloned.text
	end
	return cloned
end

function Util:NormalizeOptions(list)
	if type(list) ~= "table" then
		return {}
	end
	local normalized = {}
	if #list > 0 then
		for _, option in ipairs(list) do
			table.insert(normalized, cloneOption(option))
		end
	else
		local keys = {}
		for key in pairs(list) do
			table.insert(keys, key)
		end
		self:SortMixedKeys(keys)
		for _, key in ipairs(keys) do
			table.insert(normalized, cloneOption(list[key], key))
		end
	end
	return normalized
end

function Util:NormalizeSelection(value)
	local map = {}
	if type(value) == "table" then
		if #value > 0 then
			for _, entry in ipairs(value) do
				map[entry] = true
			end
		else
			for key, state in pairs(value) do
				if state then
					map[key] = true
				end
			end
		end
	elseif value ~= nil then
		map[value] = true
	end
	return map
end

function Util:CopySelectionMap(map)
	local copy = {}
	if type(map) ~= "table" then
		return copy
	end
	for key, state in pairs(map) do
		if state then
			copy[key] = true
		end
	end
	return copy
end

function Util:ApplyTooltip(widget, target, tooltip)
	target = target or widget
	if not (target and target.SetScript) then
		return
	end
	target:SetScript("OnEnter", nil)
	target:SetScript("OnLeave", nil)
	if not tooltip or tooltip == "" then
		return
	end
	target:EnableMouse(true)
	target:SetScript("OnEnter", function()
		GameTooltip:SetOwner(target, "ANCHOR_RIGHT")
		GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	target:SetScript("OnLeave", GameTooltip_Hide)
end

local function resolveOptions(data, layoutName)
	if not data then
		return {}
	end
	if data.optionfunc then
		local ok, result = pcall(data.optionfunc, layoutName)
		if ok and type(result) == "table" then
			return Util:NormalizeOptions(result)
		end
	end
	if type(data.options) == "table" then
		return Util:NormalizeOptions(data.options)
	end
	if type(data.values) == "table" then
		return Util:NormalizeOptions(data.values)
	end
	return {}
end

local function evaluateVisibility(data, layoutName, layoutIndex)
	if not data then
		return true
	end
	if layoutName == nil then
		layoutName = lib.activeLayoutName
	end
	if layoutIndex == nil then
		layoutIndex = lib:GetActiveLayoutIndex()
	end
	if data.isShown then
		local ok, result = pcall(data.isShown, layoutName, layoutIndex)
		if ok and result == false then
			return false
		end
	elseif data.hidden then
		local ok, result = pcall(data.hidden, layoutName, layoutIndex)
		if ok and result == true then
			return false
		end
	end
	return true
end

local function evaluateVisibilityFast(data, layoutName, layoutIndex)
	return evaluateVisibility(data, layoutName, layoutIndex)
end

local function updateLabelVisibility(selection, hidden)
	if not selection then
		return
	end
	selection.labelHidden = not not hidden
	if selection.Label then
		selection.Label:SetAlpha(hidden and 0 or 1)
	end
	if selection.Text then
		selection.Text:SetAlpha(hidden and 0 or 1)
	end
end

local function updateOverlayVisibility(selection, hidden)
	if not selection then
		return
	end
	selection.overlayHidden = not not hidden
	selection.overlayAlphas = selection.overlayAlphas or {}
	local numRegions = selection.GetNumRegions and selection:GetNumRegions() or 0
	for i = 1, numRegions do
		local region = select(i, selection:GetRegions())
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then
			if hidden then
				if selection.overlayAlphas[region] == nil then
					selection.overlayAlphas[region] = region:GetAlpha() or 1
				end
				region:SetAlpha(0)
			else
				local alpha = selection.overlayAlphas[region]
				region:SetAlpha(alpha ~= nil and alpha or 1)
			end
		end
	end
end

local function updateSelectionVisuals(selection, hidden)
	if hidden == nil and selection then
		hidden = selection.overlayHidden
	end
	updateLabelVisibility(selection, hidden)
	updateOverlayVisibility(selection, hidden)
end

local function isDragAllowed(frame)
	local predicate = State.dragPredicates[frame]
	if predicate == nil then
		return true
	end
	if type(predicate) == "function" then
		local ok, result = pcall(predicate, lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if ok then
			return result ~= false
		end
		return true
	end
	return predicate ~= false
end

local function isInCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function roundOffset(val)
	local n = tonumber(val) or 0
	if math.abs(n) < 0.001 then
		return 0
	end
	if n >= 0 then
		return math.floor(n + 0.5)
	else
		return math.ceil(n - 0.5)
	end
end

-- Magnetism helpers ---------------------------------------------------------------
local function isFrameAnchoredTo(frame, target, visited)
	if not (frame and target and frame.GetNumPoints) then
		return false
	end
	visited = visited or {}
	if visited[frame] then
		return false
	end
	visited[frame] = true
	for i = 1, frame:GetNumPoints() do
		local _, relativeTo = frame:GetPoint(i)
		if relativeTo then
			if relativeTo == target or isFrameAnchoredTo(relativeTo, target, visited) then
				return true
			end
		end
	end
	return false
end

local function ensureMagnetismAPI(frame, selection)
	if frame._eqolHasMagnetismAPI or not EditModeMagnetismManager then
		return
	end
	frame._eqolHasMagnetismAPI = true
	frame.Selection = frame.Selection or selection

	local SELECTION_PADDING = 2

	if not frame.GetScaledSelectionCenter then
		function frame:GetScaledSelectionCenter()
			local cx, cy = 0, 0
			if self.Selection and self.Selection.GetCenter then
				cx, cy = self.Selection:GetCenter()
			end
			if not (cx and cy) and self.GetCenter then
				cx, cy = self:GetCenter()
			end
			if not (cx and cy) then
				cx, cy = 0, 0
			end
			local scale = self:GetScale() or 1
			return cx * scale, cy * scale
		end
	end

	if not frame.GetScaledCenter then
		function frame:GetScaledCenter()
			local cx, cy = self:GetCenter()
			local scale = self:GetScale() or 1
			return cx * scale, cy * scale
		end
	end

	if not frame.GetScaledSelectionSides then
		function frame:GetScaledSelectionSides()
			local scale = self:GetScale() or 1
			if self.Selection and self.Selection.GetRect then
				local left, bottom, width, height = self.Selection:GetRect()
				if left then
					return left * scale, (left + width) * scale, bottom * scale, (bottom + height) * scale
				end
			end
			local left, bottom, width, height = self:GetRect()
			return (left or 0) * scale,
				((left or 0) + (width or 0)) * scale,
				(bottom or 0) * scale,
				((bottom or 0) + (height or 0)) * scale
		end
	end

	if not frame.GetLeftOffset then
		function frame:GetLeftOffset()
			if self.Selection and self.Selection.GetPoint then
				return select(4, self.Selection:GetPoint(1)) - SELECTION_PADDING
			end
			return 0
		end
	end

	if not frame.GetRightOffset then
		function frame:GetRightOffset()
			if self.Selection and self.Selection.GetPoint then
				return select(4, self.Selection:GetPoint(2)) + SELECTION_PADDING
			end
			return 0
		end
	end

	if not frame.GetTopOffset then
		function frame:GetTopOffset()
			if self.Selection and self.Selection.GetPoint then
				return select(5, self.Selection:GetPoint(1)) + SELECTION_PADDING
			end
			return 0
		end
	end

	if not frame.GetBottomOffset then
		function frame:GetBottomOffset()
			if self.Selection and self.Selection.GetPoint then
				return select(5, self.Selection:GetPoint(2)) - SELECTION_PADDING
			end
			return 0
		end
	end

	if not frame.GetSelectionOffset then
		function frame:GetSelectionOffset(point, forYOffset)
			local offset
			if point == "LEFT" then
				offset = self:GetLeftOffset()
			elseif point == "RIGHT" then
				offset = self:GetRightOffset()
			elseif point == "TOP" then
				offset = self:GetTopOffset()
			elseif point == "BOTTOM" then
				offset = self:GetBottomOffset()
			elseif point == "TOPLEFT" then
				offset = forYOffset and self:GetTopOffset() or self:GetLeftOffset()
			elseif point == "TOPRIGHT" then
				offset = forYOffset and self:GetTopOffset() or self:GetRightOffset()
			elseif point == "BOTTOMLEFT" then
				offset = forYOffset and self:GetBottomOffset() or self:GetLeftOffset()
			elseif point == "BOTTOMRIGHT" then
				offset = forYOffset and self:GetBottomOffset() or self:GetRightOffset()
			else
				local selectionCenterX, selectionCenterY = 0, 0
				if self.Selection and self.Selection.GetCenter then
					selectionCenterX, selectionCenterY = self.Selection:GetCenter()
				end
				if not (selectionCenterX and selectionCenterY) and self.GetCenter then
					selectionCenterX, selectionCenterY = self:GetCenter()
				end
				if not (selectionCenterX and selectionCenterY) then
					selectionCenterX, selectionCenterY = 0, 0
				end
				local centerX, centerY = 0, 0
				if self.GetCenter then
					centerX, centerY = self:GetCenter()
				end
				if not (centerX and centerY) then
					centerX, centerY = 0, 0
				end
				if forYOffset then
					offset = selectionCenterY - centerY
				else
					offset = selectionCenterX - centerX
				end
			end
			return offset * (self:GetScale() or 1)
		end
	end

	if not frame.GetCombinedSelectionOffset then
		function frame:GetCombinedSelectionOffset(frameInfo, forYOffset)
			local offset
			if frameInfo.frame.Selection then
				offset = -self:GetSelectionOffset(frameInfo.point, forYOffset)
					+ frameInfo.frame:GetSelectionOffset(frameInfo.relativePoint, forYOffset)
					+ frameInfo.offset
			else
				offset = -self:GetSelectionOffset(frameInfo.point, forYOffset) + frameInfo.offset
			end
			return offset / (self:GetScale() or 1)
		end
	end

	if not frame.GetCombinedCenterOffset then
		function frame:GetCombinedCenterOffset(otherFrame)
			local centerX, centerY = self:GetScaledCenter()
			local frameCenterX, frameCenterY
			if otherFrame.GetScaledCenter then
				frameCenterX, frameCenterY = otherFrame:GetScaledCenter()
			else
				frameCenterX, frameCenterY = otherFrame:GetCenter()
			end
			local scale = self:GetScale() or 1
			return (centerX - frameCenterX) / scale, (centerY - frameCenterY) / scale
		end
	end

	if not frame.GetSnapOffsets then
		function frame:GetSnapOffsets(frameInfo)
			local offsetX, offsetY
			if frameInfo.isCornerSnap then
				offsetX = self:GetCombinedSelectionOffset(frameInfo, false)
				offsetY = self:GetCombinedSelectionOffset(frameInfo, true)
			else
				offsetX, offsetY = self:GetCombinedCenterOffset(frameInfo.frame)
				if frameInfo.isHorizontal then
					offsetX = self:GetCombinedSelectionOffset(frameInfo, false)
				else
					offsetY = self:GetCombinedSelectionOffset(frameInfo, true)
				end
			end
			return offsetX, offsetY
		end
	end

	if not frame.SnapToFrame then
		function frame:SnapToFrame(frameInfo)
			local offsetX, offsetY = self:GetSnapOffsets(frameInfo)
			self:ClearAllPoints()
			self:SetPoint(frameInfo.point, frameInfo.frame, frameInfo.relativePoint, offsetX, offsetY)
		end
	end

	if not frame.IsFrameAnchoredToMe then
		function frame:IsFrameAnchoredToMe(other)
			return isFrameAnchoredTo(other, self)
		end
	end

	if not frame.IsToTheLeftOfFrame then
		function frame:IsToTheLeftOfFrame(other)
			local _, myRight = self:GetScaledSelectionSides()
			local otherLeft = select(1, other:GetScaledSelectionSides())
			return myRight < otherLeft
		end
	end

	if not frame.IsToTheRightOfFrame then
		function frame:IsToTheRightOfFrame(other)
			local myLeft = select(1, self:GetScaledSelectionSides())
			local otherRight = select(2, other:GetScaledSelectionSides())
			return myLeft > otherRight
		end
	end

	if not frame.IsAboveFrame then
		function frame:IsAboveFrame(other)
			local _, _, myBottom, myTop = self:GetScaledSelectionSides()
			local _, _, otherBottom, otherTop = other:GetScaledSelectionSides()
			return myBottom > otherTop
		end
	end

	if not frame.IsBelowFrame then
		function frame:IsBelowFrame(other)
			local _, _, myBottom, myTop = self:GetScaledSelectionSides()
			local _, _, otherBottom, otherTop = other:GetScaledSelectionSides()
			return myTop < otherBottom
		end
	end

	if not frame.IsVerticallyAlignedWithFrame then
		function frame:IsVerticallyAlignedWithFrame(other)
			local _, _, myBottom, myTop = self:GetScaledSelectionSides()
			local _, _, otherBottom, otherTop = other:GetScaledSelectionSides()
			return (myTop >= otherBottom) and (myBottom <= otherTop)
		end
	end

	if not frame.IsHorizontallyAlignedWithFrame then
		function frame:IsHorizontallyAlignedWithFrame(other)
			local myLeft, myRight = self:GetScaledSelectionSides()
			local otherLeft, otherRight = other:GetScaledSelectionSides()
			return (myRight >= otherLeft) and (myLeft <= otherRight)
		end
	end

	if not frame.GetFrameMagneticEligibility then
		function frame:GetFrameMagneticEligibility(systemFrame)
			if systemFrame == self then
				return nil
			end
			if self:IsFrameAnchoredToMe(systemFrame) then
				return nil
			end
			local myLeft, myRight, myBottom, myTop = self:GetScaledSelectionSides()
			local otherLeft, otherRight, otherBottom, otherTop = systemFrame:GetScaledSelectionSides()
			local horizontalEligible = (myTop >= otherBottom)
				and (myBottom <= otherTop)
				and (myRight < otherLeft or myLeft > otherRight)
			local verticalEligible = (myRight >= otherLeft)
				and (myLeft <= otherRight)
				and (myBottom > otherTop or myTop < otherBottom)
			return horizontalEligible, verticalEligible
		end
	end
end

-- Layout helpers ------------------------------------------------------------------
local Layout = {}
local LFG_EYE_TEXTURE = [[Interface\LFGFrame\LFG-Eye]]
local LFG_EYE_FRAME_OPEN = 0
local LFG_EYE_FRAME_CLOSED = 4
local LFG_EYE_FRAME_WIDTH = 64
local LFG_EYE_FRAME_HEIGHT = 64
local LFG_EYE_TEXTURE_WIDTH = 512
local LFG_EYE_TEXTURE_HEIGHT = 256

local function setEyeFrame(tex, frameIndex)
	if not tex or not frameIndex then
		return
	end
	local cols = LFG_EYE_TEXTURE_WIDTH / LFG_EYE_FRAME_WIDTH
	local col = frameIndex % cols
	local row = math.floor(frameIndex / cols)

	local left = (col * LFG_EYE_FRAME_WIDTH) / LFG_EYE_TEXTURE_WIDTH
	local right = ((col + 1) * LFG_EYE_FRAME_WIDTH) / LFG_EYE_TEXTURE_WIDTH
	local top = (row * LFG_EYE_FRAME_HEIGHT) / LFG_EYE_TEXTURE_HEIGHT
	local bottom = ((row + 1) * LFG_EYE_FRAME_HEIGHT) / LFG_EYE_TEXTURE_HEIGHT

	tex:SetTexCoord(left, right, top, bottom)
end

local function updateEyeButton(eyeButton, hidden)
	if not eyeButton then
		return
	end
	local tex = eyeButton:GetNormalTexture()
	if tex then
		tex:SetTexture(LFG_EYE_TEXTURE)
		setEyeFrame(tex, hidden and LFG_EYE_FRAME_CLOSED or LFG_EYE_FRAME_OPEN)
		tex:SetDesaturated(false)
	end
end

-- Overlay toggle helpers ------------------------------------------------------
local function resolveFrame(entry)
	if type(entry) == "string" then
		return _G[entry]
	end
	return entry
end

local function getManagerEyeTooltip(allHidden)
	local locale = GetLocale and GetLocale() or "enUS"
	local strings = Internal.managerEyeLocales[locale] or Internal.managerEyeLocales.enUS
	local header = allHidden and strings.show or strings.hide
	return header, strings.body
end

local function areAllOverlayTogglesHidden()
	local anySelection = false
	for _, selection in next, State.selectionRegistry do
		anySelection = true
		if not selection.overlayHidden then
			return false, anySelection
		end
	end
	for _, entry in ipairs(Internal.managerExtraFrames) do
		local frame = resolveFrame(entry)
		if frame and frame.Selection then
			local element = frame.Selection
			anySelection = true
			if Internal.managerHiddenFrames[element] == nil then
				return false, anySelection
			end
		end
	end
	return anySelection and true or false, anySelection
end

local function setAllOverlayHidden(hidden)
	local touched = false
	for _, selection in next, State.selectionRegistry do
		touched = true
		updateSelectionVisuals(selection, hidden)
	end
	for _, entry in ipairs(Internal.managerExtraFrames) do
		local frame = resolveFrame(entry)
		local element = frame and frame.Selection
		if element and element.IsShown and element.Hide then
			touched = true
			if hidden then
				if Internal.managerHiddenFrames[element] == nil then
					Internal.managerHiddenFrames[element] = {
						shown = element:IsShown() and true or false,
						alpha = element.GetAlpha and element:GetAlpha() or nil,
					}
				end
				if element.SetAlpha then
					element:SetAlpha(0)
				else
					element:Hide()
				end
			else
				local wasShown = Internal.managerHiddenFrames[element]
				if wasShown ~= nil then
					if element.SetAlpha and wasShown.alpha ~= nil then
						element:SetAlpha(wasShown.alpha)
					elseif element.SetAlpha then
						element:SetAlpha(1)
					end
					if wasShown.shown and element.Show then
						element:Show()
					end
					Internal.managerHiddenFrames[element] = nil
				end
			end
		end
	end
	return touched
end

local function restoreManagerExtraFrames(setAlphaToOne)
	for element, state in next, Internal.managerHiddenFrames do
		if element then
			local targetAlpha
			if setAlphaToOne then
				targetAlpha = 1
			elseif state and state.alpha ~= nil then
				targetAlpha = state.alpha
			end
			if targetAlpha and element.SetAlpha then
				element:SetAlpha(targetAlpha)
			end
			if state and state.shown and element.Show then
				element:Show()
			end
		end
		Internal.managerHiddenFrames[element] = nil
	end
end

local function updateManagerEyeButton()
	local button = Internal.managerEyeButton
	if not button then
		return
	end
	if not lib.isEditing then
		button:Hide()
		return
	end
	local allHidden, hasSelections = areAllOverlayTogglesHidden()
	button:SetShown(hasSelections)
	if not hasSelections then
		return
	end
	updateEyeButton(button, allHidden)
	button.allHidden = allHidden
end

local function ensureManagerEyeButton()
	if Internal.managerEyeButton or not EditModeManagerFrame then
		return
	end
	local close = EditModeManagerFrame.CloseButton
	local button = CreateFrame("Button", nil, EditModeManagerFrame)
	button:SetSize(32, 32)
	if close then
		button:SetPoint("RIGHT", close, "LEFT", -4, 0)
	else
		button:SetPoint("TOPRIGHT", EditModeManagerFrame, "TOPRIGHT", -42, -6)
	end
	button:SetNormalTexture(LFG_EYE_TEXTURE)
	local tex = button:GetNormalTexture()
	if tex then
		setEyeFrame(tex, LFG_EYE_FRAME_OPEN)
	end
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetAlpha(0)
	end
	button:SetScript("OnClick", function(self)
		local allHidden, hasToggleable = areAllOverlayTogglesHidden()
		if not hasToggleable then
			return
		end
		setAllOverlayHidden(not allHidden)
		updateManagerEyeButton()
		if
			Internal.dialog
			and Internal.dialog.mode ~= "standalone"
			and Internal.dialog.selection
			and Internal.dialog.HideLabelButton
		then
			updateEyeButton(Internal.dialog.HideLabelButton, Internal.dialog.selection.overlayHidden)
			Internal.dialog:Layout()
		end
	end)
	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local state = areAllOverlayTogglesHidden()
		local header, body = getManagerEyeTooltip(state)
		GameTooltip:SetText(header or "Toggle")
		if body then
			GameTooltip:AddLine(body, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	Internal.managerEyeButton = button
	updateManagerEyeButton()
end

-- Manager toggle panel -----------------------------------------------------------
local function ensureManagerCategory(id, label, sort)
	if not label or label == "" then
		label = id
	end
	if not label or label == "" then
		label = DEFAULT_MANAGER_TOGGLE_CATEGORY_LABEL
	end
	id = normalizeManagerCategoryId(id, label)
	local spec = State.managerCategorySpecs[id]
	if not spec then
		spec = {
			id = id,
			label = label,
		}
		State.managerCategorySpecs[id] = spec
		table.insert(State.managerCategoryOrder, id)
	end
	spec.label = label
	if sort ~= nil then
		spec.sort = sort
	end
	return id, spec
end

local function getManagerCategoryById(id)
	if id and id ~= "" then
		local spec = State.managerCategorySpecs[id]
		if spec then
			return id, spec
		end
	end
	return nil
end

local function resolveManagerToggleCategory(data)
	if not data then
		return ensureManagerCategory(DEFAULT_MANAGER_TOGGLE_CATEGORY_ID, DEFAULT_MANAGER_TOGGLE_CATEGORY_LABEL)
	end
	local category = data.category or data.categoryId or data.categoryName
	if type(category) == "table" then
		local label = category.label or category.name or category.id
		local id = category.id or category.name or category.label
		local sort = category.sort
		if id and (not label or label == "") then
			local existingId, existingSpec = getManagerCategoryById(id)
			if existingSpec then
				return existingId, existingSpec
			end
		end
		return ensureManagerCategory(id, label, sort)
	end
	if type(category) == "string" then
		local existingId, existingSpec = getManagerCategoryById(category)
		if existingSpec then
			return existingId, existingSpec
		end
		return ensureManagerCategory(nil, category)
	end
	return ensureManagerCategory(DEFAULT_MANAGER_TOGGLE_CATEGORY_ID, DEFAULT_MANAGER_TOGGLE_CATEGORY_LABEL)
end

local function getManagerToggleSort(categorySpec)
	if not categorySpec then
		return nil
	end
	local sort = categorySpec.sort
	if type(sort) == "string" then
		local key = sort:lower()
		if key == "label" then
			return function(a, b)
				local al = (a.label or ""):lower()
				local bl = (b.label or ""):lower()
				if al == bl then
					return (a.order or 0) < (b.order or 0)
				end
				return al < bl
			end
		end
	elseif type(sort) == "function" then
		return function(a, b)
			local ok, result = pcall(sort, a, b)
			if ok and result ~= nil then
				return result and true or false
			end
			return (a.order or 0) < (b.order or 0)
		end
	end
	return nil
end

local function resolveManagerToggleFrames(data)
	if not data then
		return nil
	end
	local frames = data.frames or data.frame
	if type(frames) == "function" then
		local ok, result = pcall(frames)
		if ok then
			frames = result
		else
			frames = nil
		end
	end
	if frames == nil then
		return nil
	end
	if type(frames) == "string" or (type(frames) == "table" and (frames.GetObjectType or frames.IsObjectType)) then
		frames = { frames }
	end
	if type(frames) ~= "table" then
		return nil
	end

	local resolved = {}
	for _, entry in ipairs(frames) do
		local frame = resolveFrame(entry)
		if frame then
			resolved[#resolved + 1] = frame
		end
	end
	if #resolved == 0 then
		for _, entry in pairs(frames) do
			local frame = resolveFrame(entry)
			if frame then
				resolved[#resolved + 1] = frame
			end
		end
	end
	if #resolved == 0 then
		return nil
	end
	return resolved
end

local function getManagerToggleValue(data)
	if not data then
		return true
	end
	if data.get then
		local ok, value = pcall(data.get, lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if ok and value ~= nil then
			return not not value
		end
	end
	local stored = State.managerToggleState[data.id]
	if stored ~= nil then
		return stored
	end
	local frames = resolveManagerToggleFrames(data)
	if frames and frames[1] and frames[1].IsShown then
		return frames[1]:IsShown() and true or false
	end
	if data.default ~= nil then
		return not not data.default
	end
	return true
end

local function applyManagerToggleValue(data, value)
	if not data then
		return false
	end
	if isInCombat() and not data.allowInCombat then
		return false
	end
	local layoutName = lib.activeLayoutName
	local layoutIndex = lib:GetActiveLayoutIndex()
	if data.set then
		local ok, result = pcall(data.set, layoutName, value, layoutIndex)
		if not ok or result == false then
			return false
		end
	else
		local frames = resolveManagerToggleFrames(data)
		if frames then
			for _, frame in ipairs(frames) do
				if frame then
					if frame.SetShown then
						frame:SetShown(value)
					elseif value and frame.Show then
						frame:Show()
					elseif (not value) and frame.Hide then
						frame:Hide()
					end
				end
			end
		end
	end
	State.managerToggleState[data.id] = not not value
	return true
end

local function createManagerToggleButton(parent)
	local button = CreateFrame("Frame", nil, parent, "EditModeManagerSettingCheckButtonTemplate")
	button.fixedHeight = DEFAULT_MANAGER_TOGGLE_ROW_HEIGHT
	button:SetHeight(DEFAULT_MANAGER_TOGGLE_ROW_HEIGHT)
	function button:ApplyLayout()
		if self.EditModeManagerSettingCheckButton_OnLoad then
			self:EditModeManagerSettingCheckButton_OnLoad()
			return
		end
		local width = self:GetWidth() or 0
		if width < 1 or not self.Label then
			return
		end
		local offset = select(4, self.Label:GetPoint(1)) or 0
		local labelWidth = width - (self.Button:GetWidth() or 0) - offset
		if labelWidth < 1 then
			labelWidth = 1
		end
		self.Label:SetWidth(labelWidth)
	end
	function button:OnCheckButtonClick()
		if not self.data then
			return
		end
		local value = self.Button:GetChecked() and true or false
		if not applyManagerToggleValue(self.data, value) then
			self.Button:SetChecked(getManagerToggleValue(self.data))
			return
		end
		if Internal.RefreshManagerTogglePanel then
			Internal:RefreshManagerTogglePanel()
		end
	end
	function button:ShouldEnable()
		if not self.data then
			return true
		end
		if isInCombat() and not self.data.allowInCombat then
			return false
		end
		local layoutName = lib.activeLayoutName
		local layoutIndex = lib:GetActiveLayoutIndex()
		if self.data.isEnabled then
			local ok, result = pcall(self.data.isEnabled, layoutName, layoutIndex)
			if ok then
				return result ~= false
			end
		elseif self.data.disabled then
			local ok, result = pcall(self.data.disabled, layoutName, layoutIndex)
			if ok then
				return result ~= true
			end
		end
		return true
	end
	return button
end

local function getManagerToggleExpanderLabel(expanded)
	if expanded then
		return HUD_EDIT_MODE_COLLAPSE_OPTIONS or "Collapse options"
	end
	return HUD_EDIT_MODE_EXPAND_OPTIONS or "Expand options"
end

local function ensureManagerTogglePanel()
	if Internal.managerTogglePanel or not EditModeManagerFrame then
		return Internal.managerTogglePanel
	end

	local panel = CreateFrame("Frame", nil, EditModeManagerFrame)
	panel.ignoreInLayout = true
	panel:SetPoint("TOPLEFT", EditModeManagerFrame, "BOTTOMLEFT", 0, -6)
	panel:SetPoint("TOPRIGHT", EditModeManagerFrame, "BOTTOMRIGHT", 0, -6)
	panel:SetHeight(1)
	panel:SetFrameStrata(EditModeManagerFrame:GetFrameStrata())
	panel:SetFrameLevel(EditModeManagerFrame:GetFrameLevel())
	panel:Hide()

	local border = CreateFrame("Frame", nil, panel, "DialogBorderTranslucentTemplate")
	border.ignoreInLayout = true

	local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", MANAGER_TOGGLE_PANEL_PADDING, -MANAGER_TOGGLE_PANEL_PADDING)
	scroll:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -(MANAGER_TOGGLE_PANEL_PADDING + 6), -MANAGER_TOGGLE_PANEL_PADDING)
	scroll:SetHeight(1)
	scroll:EnableMouseWheel(true)
	if scroll.ScrollBar and scroll.ScrollBar.SetHideIfUnscrollable then
		scroll.ScrollBar:SetHideIfUnscrollable(true)
	end
	FixScrollBarInside(scroll)

	local list = CreateFrame("Frame", nil, scroll, "VerticalLayoutFrame")
	list:SetWidth(1)
	list.spacing = MANAGER_TOGGLE_CATEGORY_SPACING
	scroll:SetScrollChild(list)

	local expander = CreateFrame("Frame", nil, panel, "ResizeLayoutFrame")
	expander.ignoreInLayout = true
	expander:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", MANAGER_TOGGLE_PANEL_PADDING, MANAGER_TOGGLE_PANEL_PADDING)
	expander:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -MANAGER_TOGGLE_PANEL_PADDING, MANAGER_TOGGLE_PANEL_PADDING)
	expander:SetHeight(MANAGER_TOGGLE_EXPANDER_HEIGHT)
	expander:EnableMouse(true)

	local divider = expander:CreateTexture(nil, "ARTWORK")
	divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
	divider:SetPoint("TOPLEFT", expander, "TOPLEFT", 0, 0)
	divider:SetPoint("TOPRIGHT", expander, "TOPRIGHT", 0, 0)
	divider:SetHeight(16)
	expander.Divider = divider

	local label = expander:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
	label:SetPoint("TOP", divider, "BOTTOM", 0, 4)
	expander.Label = label

	expander:SetScript("OnMouseUp", function()
		panel:ToggleExpandedState()
	end)

	panel.Scroll = scroll
	panel.List = list
	panel.Expander = expander
	panel.padding = MANAGER_TOGGLE_PANEL_PADDING
	panel.maxHeight = Internal.managerToggleMaxHeight or DEFAULT_MANAGER_TOGGLE_MAX_HEIGHT
	panel.expanderHeight = MANAGER_TOGGLE_EXPANDER_HEIGHT
	panel.expanderSpacing = MANAGER_TOGGLE_EXPANDER_SPACING
	panel.expanded = Internal.managerToggleExpanded ~= false

	function panel:ApplyScrollLimit()
		local isExpanded = self.expanded ~= false
		scroll:SetShown(isExpanded)
		local targetHeight = 0
		local needsScroll = false

		if isExpanded then
			if scroll.UpdateScrollChildRect then
				scroll:UpdateScrollChildRect()
			end
			if list.Layout then
				list:Layout()
			end

			local contentHeight = list:GetHeight() or 1
			targetHeight = contentHeight
			local maxHeight = self.maxHeight
			if maxHeight and contentHeight > maxHeight then
				targetHeight = maxHeight
				needsScroll = true
			end
			if targetHeight < 1 then
				targetHeight = 1
			end
		end

		if scroll._eqolLastHeight ~= targetHeight then
			scroll._eqolLastHeight = targetHeight
			scroll:SetHeight(targetHeight)
			scroll.fixedHeight = targetHeight
		end

		local panelHeight = self.expanderHeight + (self.padding * 2)
		if isExpanded then
			panelHeight = panelHeight + targetHeight + self.expanderSpacing
		end
		if panel._eqolLastHeight ~= panelHeight then
			panel._eqolLastHeight = panelHeight
			panel:SetHeight(panelHeight)
		end

		if scroll.ScrollBar and scroll.ScrollBar.SetShown then
			scroll.ScrollBar:SetShown(isExpanded and needsScroll)
		end

		if isExpanded and scroll.UpdateScrollChildRect then
			scroll:UpdateScrollChildRect()
		end

		if isExpanded then
			UpdateScrollChildWidthFor(scroll, list)
			if Internal.UpdateManagerToggleLayout then
				Internal:UpdateManagerToggleLayout()
			end
		end

		if (not isExpanded) or not needsScroll then
			scroll:SetVerticalScroll(0)
		else
			local maxScroll = scroll:GetVerticalScrollRange()
			scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), maxScroll))
		end
	end

	function panel:SetExpandedState(expanded)
		local wasExpanded = self.expanded ~= false
		self.expanded = not not expanded
		Internal.managerToggleExpanded = self.expanded
		self.Expander.Label:SetText(getManagerToggleExpanderLabel(self.expanded))
		self:ApplyScrollLimit()
		if self.expanded and not wasExpanded and C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if self and self.expanded and self.ApplyScrollLimit and self:IsShown() then
					self:ApplyScrollLimit()
				end
			end)
		end
	end

	function panel:ToggleExpandedState()
		self:SetExpandedState(not self.expanded)
	end

	panel:SetExpandedState(panel.expanded)

	Internal.managerTogglePanel = panel
	return panel
end

local function createManagerToggleCategoryBlock(parent)
	local block = CreateFrame("Frame", nil, parent, "VerticalLayoutFrame")
	block.spacing = MANAGER_TOGGLE_SECTION_SPACING

	local title = CreateFrame("Frame", nil, block)
	title:SetHeight(24)
	title.layoutIndex = 1
	title.Text = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title.Text:SetPoint("LEFT", 4, 0)
	title.Text:SetPoint("RIGHT", -4, 0)
	title.Text:SetJustifyH("LEFT")
	block.Title = title

	local container = CreateFrame("Frame", nil, block, "GridLayoutFrame")
	container.layoutIndex = 2
	container.childXPadding = MANAGER_TOGGLE_COLUMN_SPACING
	container.childYPadding = DEFAULT_SETTINGS_SPACING
	container.isHorizontal = true
	container.stride = 2
	container.layoutFramesGoingRight = true
	container.layoutFramesGoingUp = false
	container.alwaysUpdateLayout = true
	block.Container = container

	return block
end

function Internal:UpdateManagerToggleLayout()
	local panel = self.managerTogglePanel
	if not panel then
		return
	end
	local list = panel.List
	local width = list and list._eqolLastWidth or nil
	if not width or width < 1 then
		return
	end
	local columnWidth = math.floor((width - MANAGER_TOGGLE_COLUMN_SPACING) / 2)
	if columnWidth < 1 then
		columnWidth = width
	end
	local blocks = self.managerToggleCategoryBlocks
	if not blocks then
		return
	end
	for _, block in pairs(blocks) do
		if block:IsShown() then
			block:SetWidth(width)
			if block.Title then
				block.Title:SetWidth(width)
			end
			local container = block.Container
			if container then
				container:SetWidth(width)
				container.childXPadding = MANAGER_TOGGLE_COLUMN_SPACING
				for _, row in ipairs({ container:GetChildren() }) do
					if row and row.SetWidth then
						row.fixedWidth = columnWidth
						row:SetWidth(columnWidth)
						if row.ApplyLayout then
							row:ApplyLayout()
						end
					end
				end
				if container.Layout then
					container:Layout()
				end
			end
			if block.Layout then
				block:Layout()
			end
		end
	end
end

function Internal:RefreshManagerTogglePanel()
	local panel = ensureManagerTogglePanel()
	if not panel then
		return
	end

	local list = panel.List
	local buttons = Internal.managerToggleButtons or {}
	local blocks = Internal.managerToggleCategoryBlocks or {}
	Internal.managerToggleButtons = buttons
	Internal.managerToggleCategoryBlocks = blocks

	local categories = {}
	local orderIndex = 0
	for _, id in ipairs(State.managerToggleOrder) do
		local data = State.managerToggleSpecs[id]
		if data then
			orderIndex = orderIndex + 1
			local categoryId, categorySpec = resolveManagerToggleCategory(data)
			local entryList = categories[categoryId]
			if not entryList then
				entryList = { id = categoryId, spec = categorySpec, entries = {} }
				categories[categoryId] = entryList
			end
			local label = data.label or data.name or data.id or id
			entryList.entries[#entryList.entries + 1] = {
				id = id,
				data = data,
				label = label,
				order = orderIndex,
			}
		end
	end

	local orderedCategories = {}
	local queued = {}
	for _, categoryId in ipairs(State.managerCategoryOrder) do
		local entryList = categories[categoryId]
		if entryList and #entryList.entries > 0 then
			orderedCategories[#orderedCategories + 1] = entryList
			queued[categoryId] = true
		end
	end
	for categoryId, entryList in pairs(categories) do
		if not queued[categoryId] and #entryList.entries > 0 then
			orderedCategories[#orderedCategories + 1] = entryList
		end
	end

	local usedButtons = {}
	local usedBlocks = {}
	local blockIndex = 0
	for _, category in ipairs(orderedCategories) do
		blockIndex = blockIndex + 1
		local block = blocks[category.id]
		if not block then
			block = createManagerToggleCategoryBlock(list)
			blocks[category.id] = block
		end
		block.layoutIndex = blockIndex
		block.ignoreInLayout = nil
		block:Show()

		local title = block.Title
		if title and title.Text then
			title.Text:SetText(category.spec and category.spec.label or category.id)
		end

		local container = block.Container
		if container then
			local sorter = getManagerToggleSort(category.spec)
			if sorter then
				table.sort(category.entries, sorter)
			end
			local rowIndex = 0
			for _, entry in ipairs(category.entries) do
				rowIndex = rowIndex + 1
				local row = buttons[entry.id]
				if not row then
					row = createManagerToggleButton(container)
					buttons[entry.id] = row
				elseif row:GetParent() ~= container then
					row:SetParent(container)
				end
				row.data = entry.data
				row.layoutIndex = rowIndex
				row.ignoreInLayout = nil
				row.Label:SetText(entry.label)
				row.Button:SetChecked(getManagerToggleValue(entry.data))
				row:Show()
				if row.EditModeCheckButton_OnShow then
					row:EditModeCheckButton_OnShow()
				end
				usedButtons[entry.id] = true
			end
			if container.Layout then
				container:Layout()
			end
		end
		if block.Layout then
			block:Layout()
		end
		usedBlocks[category.id] = true
	end

	for id, row in pairs(buttons) do
		if not usedButtons[id] then
			row:Hide()
			row.ignoreInLayout = true
			row.layoutIndex = nil
			row.data = nil
		end
	end

	for id, block in pairs(blocks) do
		if not usedBlocks[id] then
			block:Hide()
			block.ignoreInLayout = true
			block.layoutIndex = nil
		end
	end

	if list.Layout then
		list:Layout()
	end
	panel:ApplyScrollLimit()
	panel:SetShown(blockIndex > 0)
end

local function snapshotLayoutNames(layoutInfo)
	if not (layoutInfo and layoutInfo.layouts) then
		return {}
	end
	local snapshot = {}
	for index, info in ipairs(layoutInfo.layouts) do
		if info and info.layoutName then
			snapshot[index] = info.layoutName
		end
	end
	return snapshot
end

-- Track deleted layout names so we can still surface them once the delete event fires.
local function recordDeletedLayouts(oldSnapshot, newSnapshot)
	if not oldSnapshot or #newSnapshot >= #oldSnapshot then
		return
	end
	local deletedIndex
	for i = 1, #oldSnapshot do
		if oldSnapshot[i] ~= newSnapshot[i] then
			deletedIndex = i
			break
		end
	end
	deletedIndex = deletedIndex or #oldSnapshot
	local deletedName = oldSnapshot[deletedIndex]
	if not deletedName then
		return
	end
	local uiIndex = deletedIndex + 2
	if not State.pendingDeletedLayouts[uiIndex] then
		State.pendingDeletedLayouts[uiIndex] = deletedName
	end
end

-- Prefer cached names so we can resolve deleted layouts before reloading from the API.
local function getCachedLayoutName(layoutIndex)
	if not layoutIndex then
		return nil
	end
	if layoutIndex > 2 then
		local pending = State.pendingDeletedLayouts
		if pending and pending[layoutIndex] then
			return pending[layoutIndex]
		end
		local snapshot = State.layoutSnapshot or Internal.layoutNameSnapshot
		local cached = snapshot and snapshot[layoutIndex - 2]
		if cached then
			return cached
		end
	end
	return layoutNames[layoutIndex]
end

local function updateActiveLayoutFromAPI()
	if not C_EditMode or not C_EditMode.GetLayouts then
		return
	end
	local layouts = C_EditMode.GetLayouts()
	if layouts and layouts.activeLayout then
		lib.activeLayoutIndex = layouts.activeLayout
		lib.activeLayoutName = layoutNames[layouts.activeLayout]
	end
	State.layoutSnapshot = snapshotLayoutNames(layouts)
	Internal.layoutNameSnapshot = State.layoutSnapshot
	syncLayoutNameCache(State.layoutSnapshot)
end

if not lib.activeLayoutName and C_EditMode and C_EditMode.GetLayouts then
	local layouts = C_EditMode.GetLayouts()
	if layouts and layouts.activeLayout then
		lib.activeLayoutIndex = layouts.activeLayout
		lib.activeLayoutName = layoutNames[layouts.activeLayout]
	end
	State.layoutSnapshot = snapshotLayoutNames(layouts)
	Internal.layoutNameSnapshot = State.layoutSnapshot
	syncLayoutNameCache(State.layoutSnapshot)
end

function Layout:HandleLayoutsChanged(_, layoutInfo)
	-- if not lib.isEditing then return end
	local layoutIndex = layoutInfo and layoutInfo.activeLayout
	if not layoutIndex then
		updateActiveLayoutFromAPI()
	end
	layoutIndex = layoutIndex or lib.activeLayoutIndex
	local layoutName = layoutIndex and layoutNames[layoutIndex] or layoutNames[lib.activeLayoutIndex]

	local newSnapshot = snapshotLayoutNames(layoutInfo)
	local oldSnapshot = State.layoutSnapshot or {}
	local didLayoutCountShrink = #newSnapshot < #oldSnapshot
	-- Blizzard shifts custom layout indices on delete, which makes unchanged names
	-- look like rename diffs across the remaining entries.
	if not didLayoutCountShrink then
		for index, newName in ipairs(newSnapshot) do
			local oldName = oldSnapshot[index]
			if oldName and newName and oldName ~= newName then
				local uiIndex = index + 2
				for _, callback in next, lib.eventHandlersLayoutRenamed do
					securecallfunction(callback, oldName, newName, uiIndex)
				end
			end
		end
	end
	if layoutInfo and layoutInfo.layouts then
		recordDeletedLayouts(oldSnapshot, newSnapshot)
	end
	State.layoutSnapshot = newSnapshot
	Internal.layoutNameSnapshot = State.layoutSnapshot
	syncLayoutNameCache(State.layoutSnapshot)

	if layoutName and layoutIndex and (layoutName ~= lib.activeLayoutName or layoutIndex ~= lib.activeLayoutIndex) then
		lib.activeLayoutName = layoutName
		lib.activeLayoutIndex = layoutIndex
		for _, callback in next, lib.eventHandlersLayout do
			securecallfunction(callback, layoutName, layoutIndex)
		end
	end
end

function Layout:HandleSpecChanged()
	-- if not lib.isEditing then return end
	if C_EditMode and C_EditMode.GetLayouts then
		local layouts = C_EditMode.GetLayouts()
		self:HandleLayoutsChanged(nil, layouts)
	end
	for _, callback in next, lib.eventHandlersSpec do
		local specID = GetSpecialization and GetSpecialization()
		securecallfunction(callback, specID)
	end
end

function Layout:HandleLayoutDeleted(deletedLayoutIndex)
	local deletedName = getCachedLayoutName(deletedLayoutIndex)
	for _, callback in next, lib.eventHandlersLayoutDeleted do
		securecallfunction(callback, deletedLayoutIndex, deletedName)
	end
	State.pendingDeletedLayouts[deletedLayoutIndex] = nil
end

function Layout:HandleLayoutAdded(addedLayoutIndex, activateNewLayout, isLayoutImported)
	local layoutType
	local layoutName
	if C_EditMode_GetLayouts then
		local info = C_EditMode_GetLayouts()
		local entry = info and info.layouts and info.layouts[addedLayoutIndex - 2]
		if entry and entry.layoutType then
			layoutType = entry.layoutType
		end
		layoutName = entry and entry.layoutName
	end
	layoutName = layoutName or layoutNames[addedLayoutIndex]
	for _, callback in next, lib.eventHandlersLayoutAdded do
		securecallfunction(callback, addedLayoutIndex, activateNewLayout, isLayoutImported, layoutType, layoutName)
	end

	-- Detect duplicates by serializing and comparing layout info
	if C_EditMode_GetLayouts and C_EditMode_ConvertLayoutInfoToString then
		local layoutInfo = C_EditMode_GetLayouts()
		if layoutInfo and layoutInfo.layouts then
			local customIndex = addedLayoutIndex - 2
			local newLayout = layoutInfo.layouts[customIndex]
			if newLayout then
				local newString = C_EditMode_ConvertLayoutInfoToString(newLayout)
				local newName = newLayout.layoutName or layoutName
				if newString and newString ~= "" then
					local dupes = {}
					for idx, info in ipairs(layoutInfo.layouts) do
						if idx ~= customIndex then
							local str = C_EditMode_ConvertLayoutInfoToString(info)
							if str == newString or (newName and info.layoutName == newName) then
								table.insert(dupes, idx + 2) -- convert to UI indices
							end
						end
					end
					if #dupes > 0 then
						for _, callback in next, lib.eventHandlersLayoutDuplicate do
							securecallfunction(callback, addedLayoutIndex, dupes, isLayoutImported, layoutType, newName)
						end
					end
				end
			end
		end
	end
end

-- Pools ----------------------------------------------------------------------------
local Pools = {}

function Pools:Create(kind, creator, resetter)
	local pool = CreateUnsecuredObjectPool(creator, resetter)
	local acquire = pool.Acquire
	pool.Acquire = function(poolObj, parent)
		local obj, new = acquire(poolObj)
		if parent then
			obj:SetParent(parent)
		end
		return obj, new
	end
	State.widgetPools[kind] = pool
	return pool
end

function Pools:Get(kind)
	return State.widgetPools[kind]
end

function Pools:ReleaseAll()
	for _, pool in next, State.widgetPools do
		pool:ReleaseAll()
	end
	if Internal.dialog and Internal.dialog.Settings then
		for _, child in ipairs({ Internal.dialog.Settings:GetChildren() }) do
			if child ~= Internal.dialog.Settings.ResetButton and child ~= Internal.dialog.Settings.Divider then
				child.ignoreInLayout = true
				if child.Hide then
					child:Hide()
				end
				if child.SetParent then
					child:SetParent(nil)
				end
			end
		end
	end
	Util:DebugTraceDialogChildren("ReleaseAllPools")
end

-- compatibility shims for callers that expect lib.internal pool helpers
function Internal:CreatePool(kind, creator, resetter)
	return Pools:Create(kind, creator, resetter)
end
function Internal:GetPool(kind)
	return Pools:Get(kind)
end
function Internal:ReleaseAllPools()
	return Pools:ReleaseAll()
end

-- Collapse state -------------------------------------------------------------------
local Collapse = {}

function Collapse:Get(frame, groupId)
	local layout = lib.activeLayoutName or "Default"
	local byFrame = State.collapseFlags[frame]
	local byLayout = byFrame and byFrame[layout]
	return byLayout and byLayout[groupId]
end

function Collapse:Set(frame, groupId, collapsed)
	local layout = lib.activeLayoutName or "Default"
	State.collapseFlags[frame] = State.collapseFlags[frame] or {}
	State.collapseFlags[frame][layout] = State.collapseFlags[frame][layout] or {}
	State.collapseFlags[frame][layout][groupId] = not not collapsed
end

-- compatibility helpers for legacy internal calls
function Internal:GetCollapseState(frame, groupId)
	return Collapse:Get(frame, groupId)
end
function Internal:SetCollapseState(frame, groupId, collapsed)
	return Collapse:Set(frame, groupId, collapsed)
end

-- Widget factory -------------------------------------------------------------------
local Widgets = {}
local SUMMARY_CHAR_LIMIT = 80

local function buildCheckbox()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		applyRowHeightOverride(self, selection and selection.parent, "checkbox")
		local value = data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if value == nil then
			value = data.default
		end
		self.checked = value
		self.Button:SetChecked(not not value)
		Util:ApplyTooltip(self, self, data.tooltip)
	end

	function mixin:OnCheckButtonClick()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.checked = not self.checked
		self.setting.set(lib.activeLayoutName, not not self.checked, lib:GetActiveLayoutIndex())
		Internal:RequestRefreshSettings()
	end

	function mixin:SetEnabled(enabled)
		self.Button:SetEnabled(enabled)
		self.Label:SetFontObject(enabled and "GameFontHighlightMedium" or "GameFontDisable")
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "EditModeSettingCheckboxTemplate")
		return Mixin(frame, mixin)
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function dropdownGet(data)
	local val = data.value ~= nil and data.value or data.text
	return data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex()) == val
end

local function dropdownSet(data)
	local val = data.value ~= nil and data.value or data.text
	data.set(lib.activeLayoutName, val, lib:GetActiveLayoutIndex())
	Internal:RequestRefreshSettings()
end

local function buildDropdown()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		self.ignoreInLayout = nil
		applyRowHeightOverride(self, selection and selection.parent, "dropdown")

		if data.useOldStyle and self.OldDropdown then
			self.Control:Hide()
			self.OldDropdown:Show()
			self.Dropdown = self.OldDropdown
		else
			if self.OldDropdown then
				self.OldDropdown:Hide()
			end
			self.Control:Show()
			self.Dropdown = self.Control.Dropdown
		end

		if data.generator then
			self.Dropdown:SetupMenu(function(owner, rootDescription)
				if data.height then
					rootDescription:SetScrollMode(data.height)
				end
				pcall(data.generator, owner, rootDescription, data)
			end)
		elseif data.values then
			self.Dropdown:SetupMenu(function(_, rootDescription)
				if data.height then
					rootDescription:SetScrollMode(data.height)
				end
				for _, value in next, data.values do
					rootDescription:CreateRadio(value.text, dropdownGet, dropdownSet, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
					})
				end
			end)
		end

		Util:ApplyTooltip(self, self.Dropdown, data.tooltip)
	end

	function mixin:SetEnabled(enabled)
		self.Dropdown:SetEnabled(enabled)
		self.Label:SetFontObject(enabled and "GameFontHighlightMedium" or "GameFontDisable")
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = 32
		Mixin(frame, mixin)

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT")
		label:SetWidth(100)
		label:SetJustifyH("LEFT")
		frame.Label = label

		local control = CreateFrame("Frame", nil, frame, "SettingsDropdownWithButtonsTemplate")
		control:SetPoint("LEFT", label, "RIGHT", 5, 0)
		frame.Control = control

		if control.DecrementButton then
			control.DecrementButton:Hide()
		end
		if control.IncrementButton then
			control.IncrementButton:Hide()
		end

		local dropdown = control.Dropdown
		dropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		dropdown:SetSize(200, 30)
		frame.Dropdown = dropdown

		local oldDropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
		oldDropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		oldDropdown:SetSize(200, 30)
		oldDropdown:Hide()
		frame.OldDropdown = oldDropdown

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function buildMultiDropdown()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.ignoreInLayout = nil
		self.summaryAnchored = nil
		self.summaryMeasure = nil
		self.hideSummary = data.hideSummary or data.noSummary or data.summary == false
		local selectionParent = selection and selection.parent

		local defaultText
		if data.customText ~= nil then
			defaultText = tostring(data.customText)
		elseif data.customDefaultText ~= nil then
			defaultText = tostring(data.customDefaultText)
		else
			defaultText = ""
		end

		self.Label:SetText(data.name)

		if data.useOldStyle and self.OldDropdown then
			self.Control:Hide()
			self.OldDropdown:Show()
			self.Dropdown = self.OldDropdown
		else
			if self.OldDropdown then
				self.OldDropdown:Hide()
			end
			self.Control:Show()
			self.Dropdown = self.Control.Dropdown
		end

		-- Keep both dropdown variants in sync so switching styles doesn't bring back "Custom"
		if self.Control and self.Control.Dropdown then
			self.Control.Dropdown:SetDefaultText(defaultText)
		end
		if self.OldDropdown then
			self.OldDropdown:SetDefaultText(defaultText)
		end
		self.Dropdown:SetDefaultText(defaultText)

		if self.Summary then
			self.Summary:ClearAllPoints()
			self.Summary:SetPoint("TOPLEFT", self.Dropdown, "BOTTOMLEFT", 0, -2)
			self.Summary:SetPoint("TOPRIGHT", self.Dropdown, "BOTTOMRIGHT", 0, -2)
		end

		local targetHeight = self.hideSummary and 32 or 48
		local override
		if self.hideSummary then
			override = getRowHeightOverride(selectionParent, "multiDropdown")
			if not override then
				override = getRowHeightOverride(selectionParent, "dropdown")
			end
		else
			override = getRowHeightOverride(selectionParent, "multiDropdownSummary")
			if not override then
				override = getRowHeightOverride(selectionParent, "multiDropdown")
			end
		end
		if override then
			targetHeight = override
		end
		self.fixedHeight = targetHeight
		self:SetHeight(targetHeight)
		if self.hideSummary and self.Summary then
			self.Summary:Hide()
		end

		self.Dropdown:SetupMenu(function(_, rootDescription)
			if data.height then
				rootDescription:SetScrollMode(data.height)
			end
			for _, option in ipairs(resolveOptions(data, lib.activeLayoutName)) do
				if option.value ~= nil then
					local label = option.label or option.text or tostring(option.value)
					rootDescription:CreateCheckbox(label, function()
						return self:IsSelected(option.value)
					end, function()
						self:ToggleOption(option.value)
					end, option)
				end
			end
		end)

		self:RefreshSummary()

		Util:ApplyTooltip(self, self.Dropdown, data.tooltip)
	end

	function mixin:GetSelectionMap()
		local selection = self.setting
			and self.setting.get
			and self.setting.get(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if selection == nil and self.setting then
			selection = self.setting.default
		end
		return Util:NormalizeSelection(selection)
	end

	function mixin:IsSelected(value)
		if value == nil then
			return false
		end
		if self.setting and self.setting.isSelected then
			return not not self.setting.isSelected(lib.activeLayoutName, value, lib:GetActiveLayoutIndex())
		end
		local map = self:GetSelectionMap()
		return map[value] == true
	end

	function mixin:SetSelected(value, shouldSelect)
		if not self.setting then
			return
		end
		if self.setting.setSelected then
			self.setting.setSelected(lib.activeLayoutName, value, shouldSelect, lib:GetActiveLayoutIndex())
		elseif self.setting.set then
			local map = self:GetSelectionMap()
			map[value] = shouldSelect and true or nil
			self.setting.set(lib.activeLayoutName, map, lib:GetActiveLayoutIndex())
		end
		if self.setting.refreshOnSelect ~= false then
			Internal:RequestRefreshSettings()
		end
	end

	function mixin:ToggleOption(value)
		self:SetSelected(value, not self:IsSelected(value))
		self:RefreshSummary()
	end

	function mixin:EnsureSummaryAnchors()
		if self.summaryAnchored or not (self.Summary and self.Dropdown) or self.hideSummary then
			return
		end
		self.summaryAnchored = true
		self.Summary:ClearAllPoints()
		self.Summary:SetPoint("TOPLEFT", self.Dropdown, "BOTTOMLEFT", 0, -2)
		self.Summary:SetPoint("TOPRIGHT", self.Dropdown, "BOTTOMRIGHT", 0, -2)
		self.Summary:SetWidth(self.Dropdown:GetWidth())
	end

	function mixin:GetSummaryWidthLimit()
		if self.Dropdown then
			return self.Dropdown:GetWidth()
		end
		if self.Summary then
			return self.Summary:GetWidth()
		end
	end

	function mixin:GetSummaryMeasureFontString()
		if self.summaryMeasure and self.summaryMeasure:IsObjectType("FontString") then
			return self.summaryMeasure
		end
		if not self.Summary then
			return nil
		end
		local fs = self.Summary:GetParent():CreateFontString(nil, "OVERLAY")
		if not fs then
			return nil
		end
		fs:SetFontObject(self.Summary:GetFontObject())
		fs:Hide()
		fs:SetWordWrap(false)
		fs:SetNonSpaceWrap(false)
		fs:SetSpacing(0)
		self.summaryMeasure = fs
		return fs
	end

	function mixin:WouldExceedSummaryWidth(text, widthLimit)
		if not text or text == "" then
			return false
		end
		if not widthLimit then
			return #text > SUMMARY_CHAR_LIMIT
		end
		local measure = self:GetSummaryMeasureFontString()
		if not measure then
			return #text > SUMMARY_CHAR_LIMIT
		end
		measure:SetFontObject(self.Summary:GetFontObject())
		measure:SetText(text)
		local getWidth = measure.GetUnboundedStringWidth or measure.GetStringWidth
		return getWidth(measure) > widthLimit
	end

	function mixin:FormatSummaryText(texts)
		if #texts == 0 then
			return "–"
		end
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
			if widthLimit and self:WouldExceedSummaryWidth(candidate, widthLimit) then
				candidate = summary .. " …"
			end
			summary = candidate
		end
		if not widthLimit and #summary > SUMMARY_CHAR_LIMIT then
			summary = summary:sub(1, SUMMARY_CHAR_LIMIT) .. " …"
		end
		return summary
	end

	function mixin:RefreshSummary()
		if self.hideSummary or not self.Summary then
			return
		end
		self:EnsureSummaryAnchors()
		local texts = {}
		for _, opt in ipairs(resolveOptions(self.setting, lib.activeLayoutName)) do
			if opt.value ~= nil and self:IsSelected(opt.value) then
				table.insert(texts, opt.text or tostring(opt.value))
			end
		end
		local summary = self:FormatSummaryText(texts)
		self.Summary:SetText(summary)
		local enabled = not self.Dropdown or self.Dropdown:IsEnabled()
		self.Summary:SetFontObject(enabled and "GameFontHighlightSmall" or "GameFontDisableSmall")
	end

	function mixin:SetEnabled(enabled)
		self.Dropdown:SetEnabled(enabled)
		self.Label:SetFontObject(enabled and "GameFontHighlightMedium" or "GameFontDisable")
		if self.Summary then
			self.Summary:SetFontObject(enabled and "GameFontHighlightSmall" or "GameFontDisableSmall")
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = 48
		frame:SetHeight(48)
		Mixin(frame, mixin)

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT")
		label:SetWidth(100)
		label:SetJustifyH("LEFT")
		frame.Label = label

		local control = CreateFrame("Frame", nil, frame, "SettingsDropdownWithButtonsTemplate")
		control:SetPoint("LEFT", label, "RIGHT", 5, 0)
		frame.Control = control

		if control.DecrementButton then
			control.DecrementButton:Hide()
		end
		if control.IncrementButton then
			control.IncrementButton:Hide()
		end

		local dropdown = control.Dropdown
		dropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		dropdown:SetSize(200, 30)
		frame.Dropdown = dropdown

		local oldDropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
		oldDropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		oldDropdown:SetSize(200, 30)
		oldDropdown:Hide()
		frame.OldDropdown = oldDropdown

		local summary = frame:CreateFontString(nil, nil, "GameFontHighlightSmall")
		summary:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
		summary:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
		summary:SetJustifyH("LEFT")
		summary:SetText("–")
		frame.Summary = summary

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
		frame.summaryAnchored = nil
		frame.summaryMeasure = nil
	end
end

local function normalizeColor(value)
	if type(value) == "table" then
		return value.r or value[1] or 1, value.g or value[2] or 1, value.b or value[3] or 1, value.a or value[4]
	elseif type(value) == "number" then
		return value, value, value
	end
	return 1, 1, 1
end

local function buildColor()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		self.ignoreInLayout = nil
		applyRowHeightOverride(self, selection and selection.parent, "color")
		local r, g, b, a = normalizeColor(data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex()) or data.default)
		self.hasOpacity = not not (data.hasOpacity or a)
		self:SetColor(r, g, b, a)
	end

	function mixin:SetColor(r, g, b, a)
		self.r, self.g, self.b, self.a = r, g, b, a
		self.Swatch:SetColorTexture(r, g, b, a or 1)
	end

	function mixin:OnClick()
		local prev = { r = self.r or 1, g = self.g or 1, b = self.b or 1, a = self.a }
		ColorPickerFrame:SetupColorPickerAndShow({
			r = prev.r,
			g = prev.g,
			b = prev.b,
			opacity = prev.a,
			hasOpacity = self.hasOpacity,
			swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = self.hasOpacity
					and (ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a)
				self:SetColor(r, g, b, a)
				self.setting.set(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			opacityFunc = function()
				if not self.hasOpacity then
					return
				end
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a
				self:SetColor(r, g, b, a)
				self.setting.set(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			cancelFunc = function()
				self:SetColor(prev.r, prev.g, prev.b, prev.a)
				self.setting.set(
					lib.activeLayoutName,
					{ r = prev.r, g = prev.g, b = prev.b, a = prev.a },
					lib:GetActiveLayoutIndex()
				)
				Internal:RequestRefreshSettings()
			end,
		})
	end

	function mixin:SetEnabled(enabled)
		if enabled then
			self.Button:Enable()
			self.Swatch:SetVertexColor(1, 1, 1, 1)
			self.Label:SetFontObject("GameFontHighlightMedium")
		else
			self.Button:Disable()
			self.Swatch:SetVertexColor(0.4, 0.4, 0.4, 1)
			self.Label:SetFontObject("GameFontDisable")
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = 32
		Mixin(frame, mixin)

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT")
		label:SetWidth(100)
		label:SetJustifyH("LEFT")
		frame.Label = label

		local button = CreateFrame("Button", nil, frame)
		button:SetSize(COLOR_BUTTON_WIDTH, 22)
		button:SetPoint("LEFT", label, "RIGHT", 8, 0)

		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetColorTexture(0.7, 0.7, 0.7, 1)
		border:SetAllPoints()

		local swatch = button:CreateTexture(nil, "ARTWORK")
		swatch:SetPoint("TOPLEFT", 2, -2)
		swatch:SetPoint("BOTTOMRIGHT", -2, 2)
		swatch:SetColorTexture(1, 1, 1, 1)
		frame.Swatch = swatch

		button:SetScript("OnClick", function()
			frame:OnClick()
		end)
		frame.Button = button

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function buildCheckboxColor()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		self.ignoreInLayout = nil
		local selectionParent = selection and selection.parent
		local override = getRowHeightOverride(selectionParent, "checkboxColor")
			or getRowHeightOverride(selectionParent, "color")
		if override then
			self.fixedHeight = override
			self:SetHeight(override)
		end

		local value = data.get and data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if value == nil then
			value = data.default
		end
		self.checked = not not value
		self.Check:SetChecked(self.checked)

		local colorVal
		if data.colorGet then
			colorVal = data.colorGet(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		end
		if not colorVal then
			colorVal = data.colorDefault or { 1, 1, 1, 1 }
		end
		local r, g, b, a = normalizeColor(colorVal)
		self.hasOpacity = not not (data.hasOpacity or a)
		self:SetColor(r, g, b, a)
		self:UpdateColorEnabled()

		Util:ApplyTooltip(self, self, data.tooltip)
	end

	function mixin:UpdateColorEnabled()
		local enabled = self.checked
		if enabled then
			self.Button:Enable()
			self.Swatch:SetVertexColor(1, 1, 1, 1)
		else
			self.Button:Disable()
			self.Swatch:SetVertexColor(0.4, 0.4, 0.4, 1)
		end
	end

	function mixin:SetColor(r, g, b, a)
		self.r, self.g, self.b, self.a = r, g, b, a
		self.Swatch:SetColorTexture(r, g, b, a or 1)
	end

	function mixin:OnCheckboxClick()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.checked = not self.checked
		if self.setting.set then
			self.setting.set(lib.activeLayoutName, self.checked, lib:GetActiveLayoutIndex())
		end
		self:UpdateColorEnabled()
		Internal:RequestRefreshSettings()
	end

	function mixin:OnColorClick()
		local prev = { r = self.r or 1, g = self.g or 1, b = self.b or 1, a = self.a }
		local apply = self.setting.colorSet or self.setting.setColor
		if not apply then
			return
		end
		ColorPickerFrame:SetupColorPickerAndShow({
			r = prev.r,
			g = prev.g,
			b = prev.b,
			opacity = prev.a,
			hasOpacity = self.hasOpacity,
			swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = self.hasOpacity
					and (ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a)
				self:SetColor(r, g, b, a)
				apply(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			opacityFunc = function()
				if not self.hasOpacity then
					return
				end
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a
				self:SetColor(r, g, b, a)
				apply(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			cancelFunc = function()
				self:SetColor(prev.r, prev.g, prev.b, prev.a)
				apply(
					lib.activeLayoutName,
					{ r = prev.r, g = prev.g, b = prev.b, a = prev.a },
					lib:GetActiveLayoutIndex()
				)
				Internal:RequestRefreshSettings()
			end,
		})
	end

	function mixin:SetEnabled(enabled)
		self.Check:SetEnabled(enabled)
		if not enabled then
			self.Button:Disable()
			self.Swatch:SetVertexColor(0.2, 0.2, 0.2, 1)
			self.Label:SetFontObject("GameFontDisable")
		else
			self:UpdateColorEnabled()
			self.Label:SetFontObject("GameFontHighlightMedium")
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = 32
		Mixin(frame, mixin)

		local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
		check:SetPoint("LEFT", -5, 0)
		check:SetScript("OnClick", function(btn)
			btn:GetParent():OnCheckboxClick()
		end)
		frame.Check = check

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT", check, "RIGHT", 2, 0)
		label:SetWidth(175)
		label:SetJustifyH("LEFT")
		frame.Label = label

		local button = CreateFrame("Button", nil, frame)
		button:SetSize(COLOR_BUTTON_WIDTH, 22)
		button:SetPoint("LEFT", label, "RIGHT", 4, 0)

		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetColorTexture(0.7, 0.7, 0.7, 1)
		border:SetAllPoints()

		local swatch = button:CreateTexture(nil, "ARTWORK")
		swatch:SetPoint("TOPLEFT", 2, -2)
		swatch:SetPoint("BOTTOMRIGHT", -2, 2)
		swatch:SetColorTexture(1, 1, 1, 1)
		frame.Swatch = swatch

		button:SetScript("OnClick", function()
			frame:OnColorClick()
		end)
		frame.Button = button

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function buildDropdownColor()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		self.ignoreInLayout = nil
		local selectionParent = selection and selection.parent
		local override = getRowHeightOverride(selectionParent, "dropdownColor")
			or getRowHeightOverride(selectionParent, "dropdown")
		if override then
			self.fixedHeight = override
			self:SetHeight(override)
		end

		if data.useOldStyle then
			if self.OldDropdown then
				self.Control:Hide()
				self.OldDropdown:Show()
				self.Dropdown = self.OldDropdown
			end
		else
			if self.OldDropdown then
				self.OldDropdown:Hide()
			end
			self.Control:Show()
			self.Dropdown = self.Control.Dropdown
		end

		local function createEntries(rootDescription)
			if data.height then
				rootDescription:SetScrollMode(data.height)
			end
			local function getCurrent()
				return data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex())
			end
			local function makeSetter(value)
				return function()
					data.set(lib.activeLayoutName, value, lib:GetActiveLayoutIndex())
					Internal:RequestRefreshSettings()
				end
			end
			if data.values then
				for _, value in next, data.values do
					rootDescription:CreateRadio(value.text, function()
						return getCurrent() == value.text
					end, makeSetter(value.value or value.text))
				end
			end
		end

		if data.generator then
			self.Dropdown:SetupMenu(function(owner, rootDescription)
				if data.height then
					rootDescription:SetScrollMode(data.height)
				end
				pcall(data.generator, owner, rootDescription, data)
			end)
		elseif data.values then
			self.Dropdown:SetupMenu(function(_, rootDescription)
				createEntries(rootDescription)
			end)
		end

		local colorVal
		if data.colorGet then
			colorVal = data.colorGet(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		end
		if not colorVal then
			colorVal = data.colorDefault or { 1, 1, 1, 1 }
		end
		local r, g, b, a = normalizeColor(colorVal)
		self.hasOpacity = not not (data.hasOpacity or a)
		self:SetColor(r, g, b, a)

		Util:ApplyTooltip(self, self, data.tooltip)
	end

	function mixin:SetColor(r, g, b, a)
		self.r, self.g, self.b, self.a = r, g, b, a
		self.Swatch:SetColorTexture(r, g, b, a or 1)
	end

	function mixin:OnColorClick()
		local prev = { r = self.r or 1, g = self.g or 1, b = self.b or 1, a = self.a }
		local apply = self.setting.colorSet or self.setting.setColor
		if not apply then
			return
		end
		ColorPickerFrame:SetupColorPickerAndShow({
			r = prev.r,
			g = prev.g,
			b = prev.b,
			opacity = prev.a,
			hasOpacity = self.hasOpacity,
			swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = self.hasOpacity
					and (ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a)
				self:SetColor(r, g, b, a)
				apply(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			opacityFunc = function()
				if not self.hasOpacity then
					return
				end
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or prev.a
				self:SetColor(r, g, b, a)
				apply(lib.activeLayoutName, { r = r, g = g, b = b, a = a }, lib:GetActiveLayoutIndex())
				Internal:RequestRefreshSettings()
			end,
			cancelFunc = function()
				self:SetColor(prev.r, prev.g, prev.b, prev.a)
				apply(
					lib.activeLayoutName,
					{ r = prev.r, g = prev.g, b = prev.b, a = prev.a },
					lib:GetActiveLayoutIndex()
				)
				Internal:RequestRefreshSettings()
			end,
		})
	end

	function mixin:SetEnabled(enabled)
		self.Dropdown:SetEnabled(enabled)
		if enabled then
			self.Button:Enable()
			self.Swatch:SetVertexColor(1, 1, 1, 1)
			self.Label:SetFontObject("GameFontHighlightMedium")
		else
			self.Button:Disable()
			self.Swatch:SetVertexColor(0.4, 0.4, 0.4, 1)
			self.Label:SetFontObject("GameFontDisable")
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = 32
		Mixin(frame, mixin)

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT")
		label:SetWidth(100)
		label:SetJustifyH("LEFT")
		frame.Label = label

		-- modern control
		local control = CreateFrame("Frame", nil, frame, "SettingsDropdownWithButtonsTemplate")
		control:SetPoint("LEFT", label, "RIGHT", 5, 0)
		frame.Control = control

		if control.DecrementButton then
			control.DecrementButton:Hide()
		end
		if control.IncrementButton then
			control.IncrementButton:Hide()
		end

		local dropdown = control.Dropdown
		dropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		dropdown:SetHeight(30)
		dropdown:SetWidth(175)
		frame.Dropdown = dropdown

		-- old style control (hidden by default)
		local oldDropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
		oldDropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
		oldDropdown:SetHeight(30)
		oldDropdown:SetWidth(175)
		oldDropdown:Hide()
		frame.OldDropdown = oldDropdown

		local button = CreateFrame("Button", nil, frame)
		button:SetSize(COLOR_BUTTON_WIDTH, 22)
		button:SetPoint("LEFT", frame.Dropdown, "RIGHT", 2, 0)

		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetColorTexture(0.7, 0.7, 0.7, 1)
		border:SetAllPoints()

		local swatch = button:CreateTexture(nil, "ARTWORK")
		swatch:SetPoint("TOPLEFT", 2, -2)
		swatch:SetPoint("BOTTOMRIGHT", -2, 2)
		swatch:SetColorTexture(1, 1, 1, 1)
		frame.Swatch = swatch

		button:SetScript("OnClick", function()
			frame:OnColorClick()
		end)
		frame.Button = button

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function formatInputValue(data, value)
	if data and data.formatter then
		local ok, formatted = pcall(data.formatter, value)
		if ok and formatted ~= nil then
			return tostring(formatted)
		end
	end
	if value == nil then
		return ""
	end
	return tostring(value)
end

local function buildInput()
	local mixin = {}

	function mixin:ApplyLayout()
		local data = self.setting or self.data
		local labelWidth = tonumber(data and data.labelWidth) or 100
		self.Label:SetWidth(labelWidth)
		local inputWidth = tonumber(data and data.inputWidth)
		self.Input:ClearAllPoints()
		self.Input:SetPoint("LEFT", self.Label, "RIGHT", 12, 0)
		local maxWidth = DEFAULT_INPUT_MAX_WIDTH
		local totalWidth = self:GetWidth() or 0
		if totalWidth > 0 then
			local available = totalWidth - labelWidth - 12 - 2
			if available < DEFAULT_INPUT_MIN_WIDTH then
				available = DEFAULT_INPUT_MIN_WIDTH
			end
			if available < maxWidth then
				maxWidth = available
			end
		end
		if inputWidth and inputWidth > 0 then
			if inputWidth > maxWidth then
				inputWidth = maxWidth
			end
			self.Input:SetWidth(inputWidth)
		else
			self.Input:SetWidth(maxWidth)
		end
	end

	function mixin:SetValue(value)
		self.currentValue = value
		self._suppressInput = true
		self.Input:SetText(formatInputValue(self.setting, value))
		self._suppressInput = nil
	end

	function mixin:CommitInput()
		if not self.setting or self.readOnly then
			self:SetValue(self.currentValue)
			return
		end
		local text = self.Input:GetText() or ""
		local value = text
		if self.numeric then
			local num = tonumber((text or ""):gsub(",", "."))
			if not num then
				self:SetValue(self.currentValue)
				return
			end
			value = num
		end
		if value ~= self.currentValue then
			self.setting.set(lib.activeLayoutName, value, lib:GetActiveLayoutIndex())
			self.currentValue = value
			Internal:RequestRefreshSettings()
		end
		self:SetValue(self.currentValue)
	end

	function mixin:Setup(data, selection)
		self.setting = data
		self.data = data
		self.Label:SetText(data.name or "")
		applyRowHeightOverride(self, selection and selection.parent, "input")

		self.numeric = not not data.numeric
		self.readOnly = not not data.readOnly
		self.selectAllOnFocus = data.selectAllOnFocus or self.readOnly

		if data.maxChars then
			self.Input:SetMaxLetters(data.maxChars)
		else
			self.Input:SetMaxLetters(0)
		end

		if data.justifyH then
			self.Input:SetJustifyH(data.justifyH)
		else
			self.Input:SetJustifyH("LEFT")
		end

		if data.inputHeight then
			self.Input:SetHeight(data.inputHeight)
		end

		local value = data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex())
		if value == nil then
			value = data.default
		end
		self:SetValue(value)
		self:ApplyLayout()
		Util:ApplyTooltip(self, self.Input, data.tooltip)
	end

	function mixin:SetEnabled(enabled)
		if enabled then
			self.Input:Enable()
			self.Label:SetFontObject("GameFontHighlightMedium")
		else
			self.Input:Disable()
			self.Label:SetFontObject("GameFontDisable")
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame")
		frame.fixedHeight = DEFAULT_SLIDER_HEIGHT
		frame:SetHeight(DEFAULT_SLIDER_HEIGHT)
		Mixin(frame, mixin)

		local label = frame:CreateFontString(nil, nil, "GameFontHighlightMedium")
		label:SetPoint("LEFT")
		label:SetWidth(100)
		label:SetJustifyH("LEFT")
		frame.Label = label

		local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		input:SetAutoFocus(false)
		input:SetHeight(20)
		input:SetJustifyH("LEFT")
		input:SetScript("OnEnterPressed", function(box)
			box:ClearFocus()
			frame:CommitInput()
		end)
		input:SetScript("OnEscapePressed", function(box)
			frame:SetValue(frame.currentValue)
			box:ClearFocus()
		end)
		input:SetScript("OnEditFocusLost", function()
			frame:CommitInput()
		end)
		input:SetScript("OnEditFocusGained", function()
			if frame.selectAllOnFocus then
				input:HighlightText()
			end
		end)
		input:SetScript("OnTextChanged", function(box, userInput)
			if frame._suppressInput then
				return
			end
			if frame.readOnly and userInput then
				frame._suppressInput = true
				box:SetText(formatInputValue(frame.setting, frame.currentValue))
				box:HighlightText()
				frame._suppressInput = nil
			end
		end)
		frame.Input = input

		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function buildSlider()
	local mixin = {}

	function mixin:Setup(data, selection)
		self.setting = data
		self.Label:SetText(data.name)
		self.ignoreInLayout = nil
		self.initInProgress = true
		self.formatters = {}
		local sliderHeight = getFrameSliderHeight(selection and selection.parent)
		if sliderHeight then
			self.fixedHeight = sliderHeight
			self:SetHeight(sliderHeight)
		end
		local formatter = data.formatter
		if not formatter then
			local stepHint = tonumber(data.valueStep)
			if stepHint and stepHint >= 1 and stepHint == math.floor(stepHint) then
				formatter = function(value)
					local n = tonumber(value) or 0
					if n >= 0 then
						n = math.floor(n + 0.5)
					else
						n = math.ceil(n - 0.5)
					end
					return tostring(n)
				end
			end
		end
		self.formatters[MinimalSliderWithSteppersMixin.Label.Right] =
			CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)

		local minV = tonumber(data.minValue) or 0
		local maxV = tonumber(data.maxValue) or 1
		if maxV < minV then
			minV, maxV = maxV, minV
		end

		local stepSize = tonumber(data.valueStep) or 1
		if stepSize <= 0 then
			local span = maxV - minV
			stepSize = span > 0 and (span / 100) or 1
		end
		local steps = (maxV - minV) / stepSize
		if steps < 1 then
			steps = 1
		end

		local current = tonumber(data.get(lib.activeLayoutName, lib:GetActiveLayoutIndex()))
			or tonumber(data.default)
			or minV
		if current < minV then
			current = minV
		end
		if current > maxV then
			current = maxV
		end
		self.currentValue = current
		self.Slider:Init(current, minV, maxV, steps, self.formatters)

		if self.Input then
			if data.allowInput then
				self.Input:Show()
				self.Input:SetNumeric(false)
				local fmt = self.formatters and self.formatters[MinimalSliderWithSteppersMixin.Label.Right]
				self.Input:SetText(fmt and fmt(current) or tostring(current or ""))
				if self.Slider.RightText then
					self.Slider.RightText:Hide()
				end
			else
				self.Input:Hide()
				if self.Slider.RightText then
					self.Slider.RightText:Show()
				end
			end
		end

		self.initInProgress = false
		Util:ApplyTooltip(self, self, data.tooltip)
	end

	function mixin:OnSliderValueChanged(value)
		if not self.initInProgress then
			-- Avoid redundant setter calls on identical values (helps rapid slider drags).
			if value ~= self.currentValue then
				self.setting.set(lib.activeLayoutName, value, lib:GetActiveLayoutIndex())
				self.currentValue = value
				Internal:RequestRefreshSettings()
			end
			if self.Input and self.Input:IsShown() then
				local fmt = self.formatters and self.formatters[MinimalSliderWithSteppersMixin.Label.Right]
				self.Input:SetText(fmt and fmt(value) or tostring(value))
				if self.Slider.RightText and self.Slider.RightText:IsShown() then
					self.Slider.RightText:Hide()
				end
			end
		end
	end

	function mixin:SetEnabled(enabled)
		self.Slider:SetEnabled(enabled)
		self.Label:SetFontObject(enabled and "GameFontHighlight" or "GameFontDisable")
		if self.Input then
			if enabled then
				self.Input:Enable()
			else
				self.Input:Disable()
			end
		end
	end

	return function()
		local frame = CreateFrame("Frame", nil, UIParent, "EditModeSettingSliderTemplate")
		Mixin(frame, mixin)

		frame:SetHeight(DEFAULT_SLIDER_HEIGHT)
		frame.Slider:SetWidth(160)
		frame.Slider.MinText:Hide()
		frame.Slider.MaxText:Hide()
		frame.Label:SetPoint("LEFT")

		local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		input:SetAutoFocus(false)
		input:SetSize(34, 20)
		input:SetJustifyH("CENTER")
		input:SetPoint("LEFT", frame.Slider, "RIGHT", 5, 0)
		input:Hide()
		frame.Input = input

		local function commitInput(box)
			if not box:IsEnabled() then
				return
			end
			local owner = box:GetParent()
			local data = owner.setting
			if not data then
				return
			end
			local minV = tonumber(data.minValue) or 0
			local maxV = tonumber(data.maxValue) or 1
			if maxV < minV then
				minV, maxV = maxV, minV
			end
			local step = tonumber(data.valueStep) or 0
			if step <= 0 then
				step = 0
			end
			local inputText = (box:GetText() or ""):gsub(",", ".")
			local val = tonumber(inputText)
			if not val then
				local fmt = owner.formatters and owner.formatters[MinimalSliderWithSteppersMixin.Label.Right]
				box:SetText(
					fmt and owner.currentValue and fmt(owner.currentValue) or tostring(owner.currentValue or "")
				)
				return
			end
			if val < minV then
				val = minV
			end
			if val > maxV then
				val = maxV
			end
			if step and step > 0 then
				val = minV + math.floor((val - minV) / step + 0.5) * step
				if val < minV then
					val = minV
				end
				if val > maxV then
					val = maxV
				end
			end
			local fmt = owner.formatters and owner.formatters[MinimalSliderWithSteppersMixin.Label.Right]
			owner.Input:SetText(fmt and fmt(val) or tostring(val))
			owner.currentValue = val
			owner.Slider:SetValue(val)
			owner.setting.set(lib.activeLayoutName, val, lib:GetActiveLayoutIndex())
			Internal:RequestRefreshSettings()
			box:ClearFocus()
		end

		input:SetScript("OnEnterPressed", commitInput)
		input:SetScript("OnEscapePressed", function(box)
			local owner = box:GetParent()
			local currentValue = owner and owner.currentValue
			if currentValue ~= nil then
				local fmt = owner and owner.formatters and owner.formatters[MinimalSliderWithSteppersMixin.Label.Right]
				box:SetText(fmt and fmt(currentValue) or tostring(currentValue))
			end
			box:ClearFocus()
		end)
		input:SetScript("OnEditFocusLost", function(box)
			if box:HasFocus() then
				return
			end
			if box:GetText() ~= "" then
				commitInput(box)
			end
		end)

		frame:OnLoad()
		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
	end
end

local function buildDivider()
	return function()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame.fixedHeight = 16
		frame:SetSize(330, 16)
		local tex = frame:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints()
		tex:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
		frame.Divider = tex
		function frame:Setup(data, selection)
			self.setting = data
			local height = getRowHeightOverride(selection and selection.parent, "divider")
			if height then
				self.fixedHeight = height
				self:SetHeight(height)
				if self.Divider then
					self.Divider:SetHeight(height)
				end
			end
		end
		return frame
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
		frame.ignoreInLayout = nil
	end
end

local getDialogFrame

local function buildCollapsible()
	return function()
		local button = CreateFrame("Button", nil, UIParent, "UIMenuButtonStretchTemplate")
		button.fixedHeight = 24
		button:SetSize(330, 24)
		local hl = button:GetHighlightTexture()
		if hl then
			hl:SetAlpha(0)
		end

		local label = button:CreateFontString(nil, nil, "GameFontNormal")
		label:SetPoint("LEFT", 10, 0)
		label:SetJustifyH("LEFT")
		label:SetWidth(270)
		button.Label = label

		local collapseIcon = button:CreateTexture(nil, "ARTWORK")
		collapseIcon:SetSize(16, 16)
		collapseIcon:SetPoint("RIGHT", -6, 0)
		button.CollapseIcon = collapseIcon

		local function updateIcon(collapsed)
			if collapsed then
				button.CollapseIcon:SetTexture([[Interface\Buttons\UI-PlusButton-Up]])
			else
				button.CollapseIcon:SetTexture([[Interface\Buttons\UI-MinusButton-Up]])
			end
		end

		function button:Setup(data, selection)
			self.setting = data
			self.selection = selection
			self.Label:SetText(data.name or "")

			local selectionParent = selection and selection.parent
			applyRowHeightOverride(self, selectionParent, "collapsible")
			if not selectionParent and Internal.dialog then
				selectionParent = getDialogFrame(Internal.dialog)
			end

			local collapsed = not not data.defaultCollapsed
			local stored
			if selectionParent then
				stored = Collapse:Get(selectionParent, data.id or data.name)
			end
			if stored ~= nil then
				collapsed = not not stored
			end
			if data.getCollapsed then
				local ok, val = pcall(data.getCollapsed, lib.activeLayoutName, lib:GetActiveLayoutIndex())
				if ok and val ~= nil then
					collapsed = not not val
				end
			end
			if selectionParent and stored == nil and data.defaultCollapsed ~= nil then
				Collapse:Set(selectionParent, data.id or data.name, collapsed)
			end

			self.collapsed = collapsed
			updateIcon(collapsed)

			self:SetScript("OnClick", function()
				local newState = not self.collapsed
				self.collapsed = newState
				updateIcon(newState)
				local touched = { data }
				if data.setCollapsed then
					data.setCollapsed(lib.activeLayoutName, newState, lib:GetActiveLayoutIndex())
				elseif selectionParent then
					Collapse:Set(selectionParent, data.id or data.name, newState)
				end
				if State.collapseExclusiveFlags[selectionParent] and newState == false then
					local settings = Internal:GetFrameSettings(selectionParent)
					if settings then
						for _, other in ipairs(settings) do
							if other ~= data and other.kind == lib.SettingType.Collapsible then
								local otherId = other.id or other.name
								if other.setCollapsed then
									other.setCollapsed(lib.activeLayoutName, true, lib:GetActiveLayoutIndex())
								elseif selectionParent then
									Collapse:Set(selectionParent, otherId, true)
								end
								touched[#touched + 1] = other
							end
						end
					end
				end
				Internal:RefreshSettings()
				Internal:RefreshSettingValues(touched)
			end)
		end

		function button:SetEnabled(enabled)
			if enabled then
				self:Enable()
				self.Label:SetFontObject("GameFontNormal")
			else
				self:Disable()
				self.Label:SetFontObject("GameFontDisable")
			end
		end

		return button
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
		frame.ignoreInLayout = nil
		frame.selection = nil
		frame.setting = nil
		frame.collapsed = nil
		frame:SetScript("OnClick", nil)
	end
end

local function buildButton()
	return function()
		return CreateFrame("Button", nil, UIParent, "EditModeSystemSettingsDialogExtraButtonTemplate")
	end, function(_, frame)
		frame:Hide()
		frame.layoutIndex = nil
		frame.fixedWidth = nil
		frame.ignoreInLayout = nil
	end
end

-- Slider pool is used by checkbox+color / dropdown+color etc
local builders = {
	[lib.SettingType.Checkbox] = buildCheckbox,
	[lib.SettingType.Dropdown] = buildDropdown,
	[lib.SettingType.MultiDropdown] = buildMultiDropdown,
	[lib.SettingType.Slider] = buildSlider,
	[lib.SettingType.Input] = buildInput,
	[lib.SettingType.Color] = buildColor,
	[lib.SettingType.CheckboxColor] = buildCheckboxColor,
	[lib.SettingType.DropdownColor] = buildDropdownColor,
	[lib.SettingType.Divider] = buildDivider,
	[lib.SettingType.Collapsible] = buildCollapsible,
	button = buildButton,
}

for kind, maker in pairs(builders) do
	local creator, resetter = maker()
	Pools:Create(kind, creator, resetter)
end

-- Dialog ---------------------------------------------------------------------------
local Dialog = {}

local function saveDialogPosition(dialog)
	if not dialog then
		return
	end
	local point, _, relativePoint, x, y = dialog:GetPoint(1)
	if not point then
		return
	end
	Internal.dialogSavedPoint = {
		point = point,
		relativePoint = relativePoint or point,
		x = x or 0,
		y = y or 0,
	}
end

local function applyDialogPosition(dialog)
	if not dialog then
		return
	end
	dialog:ClearAllPoints()
	local pos = Internal.dialogSavedPoint
	if pos then
		dialog:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
	else
		dialog:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 250)
	end
end

local function setResetVisibility(buttonsFrame, visible)
	if not buttonsFrame then
		return
	end
	if visible then
		buttonsFrame.ignoreInLayout = nil
		buttonsFrame:Show()
	else
		buttonsFrame.ignoreInLayout = true
		buttonsFrame:Hide()
	end
end

function getDialogFrame(dialog)
	if not dialog then
		return nil
	end
	local context = dialog.context
	if type(context) == "table" and context.frame then
		return context.frame
	end
	return dialog.selection and dialog.selection.parent or nil
end

local function getDialogTitle(dialog)
	if not dialog then
		return ""
	end
	local context = dialog.context
	if type(context) == "table" and type(context.title) == "string" and context.title ~= "" then
		return context.title
	end
	local frame = getDialogFrame(dialog)
	if not frame then
		return ""
	end
	return frame.editModeName or (frame.GetName and frame:GetName()) or ""
end

local function getDialogSettings(dialog)
	if not dialog then
		return nil, 0
	end
	local context = dialog.context
	local settings = type(context) == "table" and context.settings or nil
	if type(settings) == "table" then
		return settings, #settings
	end
	local frame = getDialogFrame(dialog)
	if frame then
		return Internal:GetFrameSettings(frame)
	end
	return nil, 0
end

local function getDialogButtons(dialog)
	if not dialog then
		return nil, 0
	end
	local context = dialog.context
	local buttons = type(context) == "table" and context.buttons or nil
	if type(buttons) == "table" then
		return buttons, #buttons
	end
	local frame = getDialogFrame(dialog)
	if frame then
		return Internal:GetFrameButtons(frame)
	end
	return nil, 0
end

local function normalizeDialogButtonLayout(data)
	local layout = type(data) == "table" and tostring(data.layout or ""):lower() or ""
	if layout == "compact" or layout == "grid" or layout == "half" then
		return "compact"
	end
	return "full"
end

local function setDialogButtonContainerVisible(container, visible)
	if not container then
		return
	end
	if visible then
		container.ignoreInLayout = nil
		container:Show()
	else
		container.ignoreInLayout = true
		container:Hide()
	end
end

local function getDialogButtonAreaWidth(dialog)
	local width = dialog and dialog.Settings and dialog.Settings:GetWidth() or 0
	if not width or width < 1 then
		width = dialog and dialog.SettingsScroll and dialog.SettingsScroll:GetWidth() or 0
	end
	if not width or width < 1 then
		width = 330
	end
	return width
end

local function getDialogButtonsReservedHeight(dialog)
	local buttonsRoot = dialog and dialog.Buttons
	if not (buttonsRoot and buttonsRoot.IsShown and buttonsRoot:IsShown()) then
		return 0
	end

	if buttonsRoot.Layout then
		buttonsRoot:Layout()
	end

	local height = tonumber(buttonsRoot:GetHeight()) or 0
	if height <= 0 then
		return 0
	end

	local spacingFromSettings = 12
	return height + spacingFromSettings
end

local function applyDialogButtonWidths(dialog)
	if not (dialog and dialog.Buttons) then
		return
	end

	local width = getDialogButtonAreaWidth(dialog)
	local buttonsRoot = dialog.Buttons
	buttonsRoot:SetWidth(width)

	local primary = buttonsRoot.Primary or buttonsRoot
	local compact = buttonsRoot.Compact
	local reset = buttonsRoot.Reset

	if primary then
		primary:SetWidth(width)
		for _, child in ipairs({ primary:GetChildren() }) do
			if child and child.SetWidth then
				child.fixedWidth = width
				child:SetWidth(width)
			end
		end
		if primary.Layout then
			primary:Layout()
		end
	end

	if compact then
		compact:SetWidth(width)
		local columns = compact.stride or 2
		if columns < 1 then
			columns = 1
		end
		local spacing = tonumber(compact.childXPadding) or DEFAULT_SETTINGS_SPACING
		local totalSpacing = spacing * math.max(0, columns - 1)
		local columnWidth = math.floor((width - totalSpacing) / columns)
		if columnWidth < 1 then
			columnWidth = width
		end
		for _, child in ipairs({ compact:GetChildren() }) do
			if child and child.SetWidth then
				child.fixedWidth = columnWidth
				child:SetWidth(columnWidth)
			end
		end
		if compact.Layout then
			compact:Layout()
		end
	end

	if reset then
		reset:SetWidth(width)
		for _, child in ipairs({ reset:GetChildren() }) do
			if child and child.SetWidth then
				child.fixedWidth = width
				child:SetWidth(width)
			end
		end
		if reset.Layout then
			reset:Layout()
		end
	end

	if buttonsRoot.Layout then
		buttonsRoot:Layout()
	end
end

local function getDialogSettingsSpacing(dialog)
	local context = dialog and dialog.context
	if type(context) == "table" and context.settingsSpacing ~= nil then
		return normalizeSpacing(context.settingsSpacing, DEFAULT_SETTINGS_SPACING)
	end
	return getFrameSettingsSpacing(getDialogFrame(dialog))
end

local function getDialogSettingsMaxHeight(dialog)
	local context = dialog and dialog.context
	if type(context) == "table" then
		local override = context.settingsMaxHeight
		if override == nil then
			override = context.maxSettingsHeight
		end
		if override ~= nil then
			return normalizePositive(override, nil)
		end
	end
	return getFrameSettingsMaxHeight(getDialogFrame(dialog))
end

local function getDialogShowSettingsReset(dialog)
	local context = dialog and dialog.context
	if type(context) == "table" and context.showSettingsReset ~= nil then
		return context.showSettingsReset == true
	end
	local frame = getDialogFrame(dialog)
	local showSettingsReset = frame and State.settingsResetToggles[frame]
	if showSettingsReset == nil then
		showSettingsReset = true
	end
	return showSettingsReset == true
end

local function getDialogShowReset(dialog)
	local context = dialog and dialog.context
	if type(context) == "table" and context.showReset ~= nil then
		return context.showReset == true
	end
	local frame = getDialogFrame(dialog)
	if not frame then
		return false
	end
	if frame and State.resetToggles[frame] == false then
		return false
	end
	local defaultPosition = type(context) == "table" and context.defaultPosition or nil
	return defaultPosition ~= nil or lib:GetFrameDefaultPosition(frame) ~= nil
end

local function getDialogDefaultPosition(dialog)
	local context = dialog and dialog.context
	if type(context) == "table" and context.defaultPosition ~= nil then
		return context.defaultPosition
	end
	local frame = getDialogFrame(dialog)
	if not frame then
		return nil
	end
	return lib:GetFrameDefaultPosition(frame)
end

local function applyDialogPositionOverride(dialog)
	local context = dialog and dialog.context
	if type(context) ~= "table" then
		return false
	end
	local relativeTo = context.relativeTo or context.anchorTo
	local point = context.point or context.anchorPoint
	local relativePoint = context.relativePoint or context.anchorRelativePoint or point
	if not point then
		return false
	end
	dialog:ClearAllPoints()
	dialog:SetPoint(
		point,
		relativeTo or UIParent,
		relativePoint or point,
		context.x or context.offsetX or 0,
		context.y or context.offsetY or 0
	)
	return true
end

local function normalizeDialogContext(value)
	if not value then
		return nil
	end
	if value.parent then
		return {
			mode = "edit",
			frame = value.parent,
			selection = value,
		}
	end

	local context = {}
	for key, entry in pairs(value) do
		context[key] = entry
	end
	context.mode = context.mode or "standalone"
	context.frame = context.frame or (context.selection and context.selection.parent) or context.host
	if not context.frame then
		return nil
	end
	if not context.selection then
		context.selection = {
			parent = context.frame,
			standalone = context.mode ~= "edit",
			overlayHidden = false,
			labelHidden = false,
		}
	elseif not context.selection.parent then
		context.selection.parent = context.frame
	end
	if context.mode ~= "edit" then
		context.selection.standalone = true
	end
	return context
end

local function applyDialogDefaultPosition(frame, pos)
	if not (frame and pos) then
		return
	end
	local point = pos.point or "CENTER"
	local relativeTo = pos.relativeTo
	local relativePoint = pos.relativePoint or point
	local x = pos.x or 0
	local y = pos.y or 0
	frame:ClearAllPoints()
	if relativeTo ~= nil or pos.relativePoint ~= nil then
		frame:SetPoint(point, relativeTo or UIParent, relativePoint, x, y)
	else
		frame:SetPoint(point, x, y)
	end
end

function Dialog:ApplyLayoutOverrides()
	local selectionParent = getDialogFrame(self)
	if self.Settings then
		self.Settings.spacing = getDialogSettingsSpacing(self)
		if self.Settings.Divider then
			local height = getRowHeightOverride(selectionParent, "divider")
			if height then
				self.Settings.Divider:SetHeight(height)
			end
		end
	end
end

function Dialog:Update(selection)
	local context = normalizeDialogContext(selection)
	if not context then
		return
	end
	self.context = context
	self.mode = context.mode
	self.selection = context.selection
	local frame = getDialogFrame(self)
	self.Title:SetText(getDialogTitle(self))
	self:ApplyLayoutOverrides()
	local allowOverlayToggle = self.mode == "edit" and State.overlayToggleFlags[frame] == true
	if self.HideLabelButton then
		if allowOverlayToggle then
			self.HideLabelButton:Show()
			updateSelectionVisuals(self.selection, self.selection.overlayHidden)
			updateEyeButton(self.HideLabelButton, self.selection.overlayHidden)
		else
			self.HideLabelButton:Hide()
			if self.selection then
				self.selection.overlayHidden = false
			end
		end
	end
	self:UpdateSettings()
	self:UpdateButtons()
	FixScrollBarInside(self.SettingsScroll)
	UpdateScrollChildWidth(self)
	local appliedPositionOverride = applyDialogPositionOverride(self)
	if not self:IsShown() and not appliedPositionOverride then
		applyDialogPosition(self)
	end
	self:Show()
	self:Layout()
end

function Dialog:UpdateSettings()
	Pools:ReleaseAll()
	local settings, num = getDialogSettings(self)
	local layoutName = lib.activeLayoutName
	local layoutIndex = lib:GetActiveLayoutIndex()
	local collapsedById = {}
	if num > 0 then
		for _, data in next, settings do
			if data.kind == lib.SettingType.Collapsible then
				local selectionParent = getDialogFrame(self)
				local collapsed = Collapse:Get(selectionParent, data.id or data.name)
				if collapsed == nil and data.defaultCollapsed ~= nil then
					collapsed = not not data.defaultCollapsed
				end
				if data.getCollapsed then
					local ok, val = pcall(data.getCollapsed, layoutName, layoutIndex)
					if ok and val ~= nil then
						collapsed = not not val
					end
				end
				collapsedById[data.id or data.name] = not not collapsed
			end
		end

		for index, data in next, settings do
			local pool = Pools:Get(data.kind)
			if pool then
				local setting = pool:Acquire(self.Settings)
				setting.layoutIndex = index
				ApplySettingsRowWidth(setting, self.Settings)
				setting:Setup(data, self.selection)
				local visible = evaluateVisibility(data, layoutName, layoutIndex)
				if data.parentId and collapsedById[data.parentId] then
					visible = false
				end
				if setting.SetEnabled then
					local enabled = true
					if data.isEnabled then
						local ok, result = pcall(data.isEnabled, layoutName, layoutIndex)
						enabled = ok and result ~= false
					elseif data.disabled then
						local ok, result = pcall(data.disabled, layoutName, layoutIndex)
						enabled = not (ok and result == true)
					end
					setting:SetEnabled(enabled)
					setting._eqolEnabled = enabled
				end
				if visible then
					setting.ignoreInLayout = nil
					setting:Show()
				else
					setting.ignoreInLayout = true
					setting:Hide()
				end
			end
		end
	end

	self.Settings.ResetButton.layoutIndex = num + 1
	self.Settings.Divider.layoutIndex = num + 2
	local showSettingsReset = getDialogShowSettingsReset(self)
	self.Settings.ResetButton:SetEnabled(num > 0)
	self.Settings.ResetButton:SetShown(showSettingsReset == true)
	if self.Settings and self.Settings.Layout then
		self.Settings:Layout()
	end
end

function Dialog:UpdateButtons()
	local buttonPool = Pools:Get("button")
	if buttonPool then
		buttonPool:ReleaseAll()
	end
	local buttons, num = getDialogButtons(self)
	local buttonsRoot = self.Buttons
	local primaryContainer = buttonsRoot and (buttonsRoot.Primary or buttonsRoot) or nil
	local compactContainer = buttonsRoot and buttonsRoot.Compact or nil
	local resetContainer = buttonsRoot and buttonsRoot.Reset or primaryContainer
	local primaryIndex = 0
	local compactIndex = 0
	local resetVisible = false
	local anyVisible = false
	if num > 0 then
		for index, data in next, buttons do
			local layout = normalizeDialogButtonLayout(data)
			local targetContainer = primaryContainer
			if layout == "compact" and compactContainer then
				targetContainer = compactContainer
			end
			local button = buttonPool and targetContainer and buttonPool:Acquire(targetContainer)
			if not button then
				break
			end
			if targetContainer == compactContainer then
				compactIndex = compactIndex + 1
				button.layoutIndex = compactIndex
			else
				primaryIndex = primaryIndex + 1
				button.layoutIndex = primaryIndex
			end
			button:SetText(data.text)
			if button.SetOnClickHandler then
				button:SetOnClickHandler(data.click)
			else
				button:SetScript("OnClick", data.click)
			end
			button:Show()
			anyVisible = true
		end
	end

	local showReset = getDialogShowReset(self)
	if showReset and buttonPool and resetContainer then
		local resetPosition = buttonPool:Acquire(resetContainer)
		resetPosition.layoutIndex = 1
		resetPosition:SetText(HUD_EDIT_MODE_RESET_POSITION)
		resetPosition:SetOnClickHandler(GenerateClosure(self.ResetPosition, self))
		resetPosition:Show()
		resetVisible = true
		anyVisible = true
	end

	setDialogButtonContainerVisible(primaryContainer, primaryIndex > 0)
	setDialogButtonContainerVisible(compactContainer, compactIndex > 0)
	setDialogButtonContainerVisible(resetContainer, resetVisible)

	if anyVisible then
		setResetVisibility(self.Buttons, true)
		if self.Settings and self.Settings.Divider then
			self.Settings.Divider.ignoreInLayout = nil
			self.Settings.Divider:Show()
		end
	else
		setResetVisibility(self.Buttons, false)
		if self.Settings and self.Settings.Divider then
			self.Settings.Divider.ignoreInLayout = true
			self.Settings.Divider:Hide()
		end
	end

	applyDialogButtonWidths(self)
end

function Dialog:ResetSettings()
	local settings, num = getDialogSettings(self)
	if num > 0 then
		for _, data in next, settings do
			local handledDefault = false
			if data.kind == lib.SettingType.MultiDropdown and data.default ~= nil then
				local selection = Util:CopySelectionMap(Util:NormalizeSelection(data.default))
				if data.set then
					data.set(lib.activeLayoutName, selection, lib:GetActiveLayoutIndex())
				elseif data.setSelected then
					for _, option in ipairs(resolveOptions(data, lib.activeLayoutName)) do
						if option.value ~= nil then
							data.setSelected(
								lib.activeLayoutName,
								option.value,
								selection[option.value] and true or false,
								lib:GetActiveLayoutIndex()
							)
						end
					end
				end
				handledDefault = true
			end
			if not handledDefault and data.default ~= nil and data.set then
				data.set(lib.activeLayoutName, data.default, lib:GetActiveLayoutIndex())
			end
			if data.kind == lib.SettingType.CheckboxColor then
				local apply = data.colorSet or data.setColor
				if apply and data.colorDefault ~= nil then
					apply(lib.activeLayoutName, data.colorDefault or { 1, 1, 1, 1 }, lib:GetActiveLayoutIndex())
				end
			end
		end
		self:Update(self.selection)
	end
end

function Dialog:ResetPosition()
	local parent = getDialogFrame(self)
	if not parent then
		return
	end
	local pos = getDialogDefaultPosition(self) or { point = "CENTER", x = 0, y = 0 }
	applyDialogDefaultPosition(parent, pos)
	Internal:TriggerCallback(parent, pos.point or "CENTER", roundOffset(pos.x or 0), roundOffset(pos.y or 0))
end

function Internal.CreateDialog()
	local dialog = Mixin(CreateFrame("Frame", nil, UIParent, "ResizeLayoutFrame"), Dialog)
	dialog:SetSize(300, 350)
	dialog:SetFrameStrata("DIALOG")
	dialog:SetFrameLevel(200)
	dialog:Hide()
	dialog.widthPadding = 40
	dialog.heightPadding = 40

	dialog:EnableMouse(true)
	dialog:SetMovable(true)
	dialog:SetClampedToScreen(true)
	dialog:SetDontSavePosition(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", function()
		dialog:StartMoving()
	end)
	dialog:SetScript("OnDragStop", function()
		dialog:StopMovingOrSizing()
		saveDialogPosition(dialog)
	end)

	local dialogTitle = dialog:CreateFontString(nil, nil, "GameFontHighlightLarge")
	dialogTitle:SetPoint("TOP", 0, -15)
	dialog.Title = dialogTitle

	local dialogBorder = CreateFrame("Frame", nil, dialog, "DialogBorderTranslucentTemplate")
	dialogBorder.ignoreInLayout = true
	dialog.Border = dialogBorder

	local dialogClose = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
	dialogClose:SetPoint("TOPRIGHT")
	dialogClose.ignoreInLayout = true
	dialog.Close = dialogClose

	local hideLabelButton = CreateFrame("Button", nil, dialog)
	hideLabelButton:SetSize(32, 32)
	hideLabelButton:SetPoint("RIGHT", dialogClose, "LEFT", -4, 0)
	hideLabelButton:SetNormalTexture(LFG_EYE_TEXTURE)
	local dialogEyeTex = hideLabelButton:GetNormalTexture()
	if dialogEyeTex then
		setEyeFrame(dialogEyeTex, LFG_EYE_FRAME_OPEN)
	end
	hideLabelButton:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	if hideLabelButton:GetHighlightTexture() then
		hideLabelButton:GetHighlightTexture():SetAlpha(0)
	end
	hideLabelButton:SetScript("OnClick", function()
		local selection = dialog.selection
		if not selection then
			return
		end
		if State.overlayToggleFlags[selection.parent] == false then
			return
		end
		local hidden = not selection.overlayHidden
		updateSelectionVisuals(selection, hidden)
		updateEyeButton(hideLabelButton, hidden)
		updateManagerEyeButton()
		dialog:Layout()
	end)
	hideLabelButton:SetScript("OnEnter", function()
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(hideLabelButton, "ANCHOR_RIGHT")
		local state = dialog.selection and dialog.selection.overlayHidden and HUD_EDIT_MODE_SHOW or HUD_EDIT_MODE_HIDE
		GameTooltip:SetText((state or "Toggle") .. " highlight")
		GameTooltip:Show()
	end)
	hideLabelButton:SetScript("OnLeave", GameTooltip_Hide)
	dialog.HideLabelButton = hideLabelButton

	-- Settings Scroll Container
	local dialogSettingsScroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
	dialogSettingsScroll:SetPoint("TOP", dialogTitle, "BOTTOM", 0, -12)
	dialogSettingsScroll:SetWidth(330)
	dialogSettingsScroll:SetHeight(1)
	dialogSettingsScroll:EnableMouseWheel(true)
	dialogSettingsScroll:SetScript("OnMouseWheel", function(self, delta)
		local step = 30
		local cur = self:GetVerticalScroll()
		local max = self:GetVerticalScrollRange()
		if delta > 0 then
			self:SetVerticalScroll(math.max(cur - step, 0))
		else
			self:SetVerticalScroll(math.min(cur + step, max))
		end
	end)
	FixScrollBarInside(dialogSettingsScroll)

	local dialogSettings = CreateFrame("Frame", nil, dialogSettingsScroll, "VerticalLayoutFrame")
	dialogSettings:SetWidth(330)
	dialogSettings.spacing = DEFAULT_SETTINGS_SPACING
	dialogSettingsScroll:SetScrollChild(dialogSettings)

	dialog.SettingsScroll = dialogSettingsScroll
	dialog.Settings = dialogSettings

	function dialog:ApplySettingsScrollLimit()
		local scroll = self.SettingsScroll
		local settings = self.Settings
		if not (scroll and settings) then
			return
		end
		FixScrollBarInside(scroll)

		local maxHeight = getDialogSettingsMaxHeight(self)

		applyDialogButtonWidths(self)
		if settings.Layout then
			settings:Layout()
		end

		local contentHeight = settings:GetHeight() or 1
		local targetHeight = contentHeight
		local needsScroll = false
		local reservedBottomHeight = getDialogButtonsReservedHeight(self)

		if maxHeight then
			maxHeight = maxHeight - reservedBottomHeight
			if maxHeight < 1 then
				maxHeight = 1
			end
		end

		if maxHeight and contentHeight > maxHeight then
			targetHeight = maxHeight
			needsScroll = true
		end
		if targetHeight < 1 then
			targetHeight = 1
		end

		if scroll._eqolLastHeight ~= targetHeight then
			scroll._eqolLastHeight = targetHeight
			scroll:SetHeight(targetHeight)
			scroll.fixedHeight = targetHeight
		end

		if scroll.ScrollBar and scroll.ScrollBar.SetShown then
			scroll.ScrollBar:SetShown(needsScroll)
		end

		if scroll.UpdateScrollChildRect then
			scroll:UpdateScrollChildRect()
		end

		UpdateScrollChildWidth(self)

		if not needsScroll then
			scroll:SetVerticalScroll(0)
		else
			local maxScroll = scroll:GetVerticalScrollRange()
			scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), maxScroll))
		end
	end

	local resetSettingsButton = CreateFrame("Button", nil, dialogSettings, "EditModeSystemSettingsDialogButtonTemplate")
	resetSettingsButton:SetText(RESET_TO_DEFAULT)
	resetSettingsButton:SetOnClickHandler(GenerateClosure(dialog.ResetSettings, dialog))
	dialogSettings.ResetButton = resetSettingsButton

	local divider = dialogSettings:CreateTexture(nil, "ARTWORK")
	divider:SetSize(330, 16)
	divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
	dialogSettings.Divider = divider

	local dialogButtons = CreateFrame("Frame", nil, dialog, "VerticalLayoutFrame")
	dialogButtons:SetPoint("TOP", dialogSettingsScroll, "BOTTOM", 0, -12)
	dialogButtons:SetWidth(330)
	dialogButtons.spacing = DEFAULT_SETTINGS_SPACING

	local primaryButtons = CreateFrame("Frame", nil, dialogButtons, "VerticalLayoutFrame")
	primaryButtons.layoutIndex = 1
	primaryButtons.spacing = DEFAULT_SETTINGS_SPACING
	primaryButtons:SetWidth(330)
	primaryButtons.ignoreInLayout = true
	primaryButtons:Hide()
	dialogButtons.Primary = primaryButtons

	local compactButtons = CreateFrame("Frame", nil, dialogButtons, "GridLayoutFrame")
	compactButtons.layoutIndex = 2
	compactButtons:SetWidth(330)
	compactButtons.childXPadding = DEFAULT_SETTINGS_SPACING
	compactButtons.childYPadding = DEFAULT_SETTINGS_SPACING
	compactButtons.isHorizontal = true
	compactButtons.stride = 2
	compactButtons.layoutFramesGoingRight = true
	compactButtons.layoutFramesGoingUp = false
	compactButtons.alwaysUpdateLayout = true
	compactButtons.ignoreInLayout = true
	compactButtons:Hide()
	dialogButtons.Compact = compactButtons

	local resetButtons = CreateFrame("Frame", nil, dialogButtons, "VerticalLayoutFrame")
	resetButtons.layoutIndex = 3
	resetButtons.spacing = DEFAULT_SETTINGS_SPACING
	resetButtons:SetWidth(330)
	resetButtons.ignoreInLayout = true
	resetButtons:Hide()
	dialogButtons.Reset = resetButtons

	dialog.Buttons = dialogButtons

	if not dialog._eqolOriginalLayout then
		dialog._eqolOriginalLayout = dialog.Layout
		dialog.Layout = function(self, ...)
			self:ApplySettingsScrollLimit()
			applyDialogButtonWidths(self)
			return self:_eqolOriginalLayout(...)
		end
	end

	dialog:HookScript("OnHide", function(self)
		if self.mode == "standalone" then
			local context = self.context
			self.context = nil
			self.mode = nil
			self.selection = nil
			if context and type(context.onHide) == "function" then
				securecallfunction(context.onHide, self, context.frame)
			end
		end
	end)

	return dialog
end

-- Selection and movement -----------------------------------------------------------
local Selection = {}

local function setPropagateKeyboardInputSafe(frame, propagate)
	if not frame or not frame.SetPropagateKeyboardInput or isInCombat() or not lib.isEditing then
		return
	end
	frame:SetPropagateKeyboardInput(not not propagate)
end

local function updateSelectionKeyboard(selection)
	if not selection or not selection.EnableKeyboard then
		return
	end
	local allow = lib.isEditing and not isInCombat()
	selection:EnableKeyboard(allow)
	if allow then
		setPropagateKeyboardInputSafe(selection, true)
	end
end

local function deriveAnchorAndOffset(frame)
	-- Finds the nearest anchor on each axis (left/right/center, top/bottom/center) and
	-- returns a Blizzard anchor string plus offsets relative to the parent.
	local parent = frame:GetParent()
	if not parent then
		return
	end

	local scale = frame:GetScale()
	if not scale then
		return
	end

	local left = frame:GetLeft() * scale
	local right = frame:GetRight() * scale
	local top = frame:GetTop() * scale
	local bottom = frame:GetBottom() * scale
	local parentWidth, parentHeight = parent:GetSize()

	-- Distance helpers
	local cx = (left + right) * 0.5 - parentWidth * 0.5
	local cy = (bottom + top) * 0.5 - parentHeight * 0.5
	local dx = { label = "LEFT", dist = left, offset = left }
	local cxEntry = { label = "", dist = math.abs(cx), offset = cx }
	local rx = { label = "RIGHT", dist = parentWidth - right, offset = right - parentWidth }

	local dy = { label = "BOTTOM", dist = bottom, offset = bottom }
	local cyEntry = { label = "", dist = math.abs(cy), offset = cy }
	local ty = { label = "TOP", dist = parentHeight - top, offset = top - parentHeight }

	local function pickAxis(neg, center, pos)
		local candidate = neg
		if pos.dist < candidate.dist then
			candidate = pos
		end
		if center.dist <= candidate.dist then
			candidate = center
		end
		return candidate.label, candidate.offset
	end

	local xLabel, xOffset = pickAxis(dx, cxEntry, rx)
	local yLabel, yOffset = pickAxis(dy, cyEntry, ty)

	local point = (yLabel ~= "" and yLabel or "") .. (xLabel ~= "" and xLabel or "")
	if point == "" then
		point = "CENTER"
	end

	return point, xOffset / scale, yOffset / scale
end

local function adjustPosition(frame, dx, dy)
	local scale = frame:GetScale() or 1
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	if not point then
		point, relativePoint, x, y = "CENTER", "CENTER", 0, 0
	end
	x = (x or 0) + dx / scale
	y = (y or 0) + dy / scale
	frame:ClearAllPoints()
	frame:SetPoint(point, relativeTo or UIParent, relativePoint or point, x, y)
	Internal:TriggerCallback(frame, point, roundOffset(x), roundOffset(y))
end

local function resetSelectionIndicators(force)
	if not force and not lib.isEditing then
		return
	end
	if Internal.dialog then
		Internal.dialog:Hide()
	end
	for frame, selection in next, State.selectionRegistry do
		if selection.isSelected then
			frame:SetMovable(false)
		end
		local keepHidden = selection.overlayHidden
		if not lib.isEditing then
			keepHidden = false
		end
		updateSelectionVisuals(selection, keepHidden)
		if not lib.isEditing then
			selection:Hide()
			selection.isSelected = false
		else
			selection:ShowHighlighted()
		end
		updateSelectionKeyboard(selection)
	end
	if Internal.dialog and Internal.dialog.HideLabelButton then
		updateEyeButton(Internal.dialog.HideLabelButton, false)
	end
	updateManagerEyeButton()
end

local function hideOverlapMenu()
	if Internal.overlapMenu then
		Internal.overlapMenu:Hide()
	end
end

local function beginSelectionDrag(self)
	if isInCombat() then
		return
	end
	hideOverlapMenu()
	if not isDragAllowed(self.parent) then
		return
	end
	self.parent:StartMoving()
	if EditModeMagnetismManager and EditModeManagerFrame and EditModeManagerFrame.SetSnapPreviewFrame then
		EditModeManagerFrame:SetSnapPreviewFrame(self.parent)
	end
end

local function finishSelectionDrag(self)
	local parent = self.parent
	parent:StopMovingOrSizing()
	if EditModeManagerFrame and EditModeManagerFrame.ClearSnapPreviewFrame then
		EditModeManagerFrame:ClearSnapPreviewFrame()
	end
	if isInCombat() then
		return
	end
	if not isDragAllowed(parent) then
		return
	end
	if
		EditModeManagerFrame
		and EditModeManagerFrame.IsSnapEnabled
		and EditModeManagerFrame:IsSnapEnabled()
		and EditModeMagnetismManager
	then
		EditModeMagnetismManager:ApplyMagnetism(parent)
	end
	local point, x, y = deriveAnchorAndOffset(parent)
	if not point then
		return
	end
	parent:ClearAllPoints()
	parent:SetPoint(point, x, y)
	Internal:TriggerCallback(parent, point, roundOffset(x), roundOffset(y))
end

-- Overlap chooser ---------------------------------------------------------------
local function getCursorPositionUI()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale() or 1
	return x / scale, y / scale
end

local function getSelectionLabel(selection)
	if not selection then
		return "Frame"
	end
	if selection.systemBaseName and selection.systemBaseName ~= "" then
		return selection.systemBaseName
	end
	if selection.Label and selection.Label.GetText then
		local txt = selection.Label:GetText()
		if txt and txt ~= "" then
			return txt
		end
	end
	local parent = selection.parent
	if parent then
		return parent.editModeName or parent:GetName() or "Frame"
	end
	return "Frame"
end

local function selectionContainsCursor(selection, cx, cy)
	if not selection or not selection:IsVisible() then
		return false
	end
	local frame = selection.parent or selection
	if not (frame and frame:IsVisible()) then
		return false
	end
	local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	if not left or not right or not top or not bottom then
		return false
	end
	return cx >= left and cx <= right and cy >= bottom and cy <= top
end

local function collectOverlappingSelections(cx, cy)
	local hits = {}
	for _, selection in pairs(State.selectionRegistry) do
		if selectionContainsCursor(selection, cx, cy) then
			table.insert(hits, selection)
		end
	end
	return hits
end

local function ensureOverlapMenu()
	if Internal.overlapMenu then
		return Internal.overlapMenu
	end
	local menu = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
	menu:SetFrameStrata("TOOLTIP")
	menu:EnableMouse(true)
	menu:SetPropagateMouseClicks(true)
	menu.buttons = {}
	menu.buttonHeight = 22
	menu.buttonSpacing = 4
	menu:SetScript("OnHide", function(self)
		for _, btn in ipairs(self.buttons) do
			btn:Hide()
			btn.selection = nil
		end
	end)
	Internal.overlapMenu = menu
	return menu
end

local function selectSelection(selection)
	if isInCombat() or not selection then
		return
	end
	resetSelectionIndicators()
	if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem then
		EditModeManagerFrame:ClearSelectedSystem()
	end
	if not selection.isSelected then
		selection.parent:SetMovable(true)
		selection:ShowSelected(true)
		selection.isSelected = true
		if Internal.dialog then
			Internal.dialog:Update(selection)
		end
	end
end

local function showOverlapMenu(hits, cursorX, cursorY, primary)
	if #hits <= 1 then
		hideOverlapMenu()
		return
	end
	local menu = ensureOverlapMenu()
	local buttons = menu.buttons
	local maxWidth = 0
	local yOffset = -8
	table.sort(hits, function(a, b)
		if a == primary then
			return true
		end
		if b == primary then
			return false
		end
		return getSelectionLabel(a) < getSelectionLabel(b)
	end)
	for index, selection in ipairs(hits) do
		local btn = buttons[index]
		if not btn then
			btn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
			buttons[index] = btn
		end
		local label = getSelectionLabel(selection)
		btn.selection = selection
		btn:SetText(label)
		btn:SetWidth(math.max(140, btn:GetTextWidth() + 24))
		btn:SetHeight(menu.buttonHeight)
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", 8, yOffset)
		yOffset = yOffset - (menu.buttonHeight + menu.buttonSpacing)
		btn:SetScript("OnClick", function()
			hideOverlapMenu()
			selectSelection(selection)
		end)
		btn:Show()
		if btn:GetWidth() > maxWidth then
			maxWidth = btn:GetWidth()
		end
	end
	for i = #hits + 1, #buttons do
		buttons[i]:Hide()
		buttons[i].selection = nil
	end
	local totalHeight = 16 + #hits * menu.buttonHeight + (#hits - 1) * menu.buttonSpacing
	menu:SetSize(maxWidth + 16, totalHeight)
	menu:ClearAllPoints()
	menu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX, cursorY)
	menu:Show()
end

local function handleSelectionMouseDown(self)
	if isInCombat() then
		return
	end
	hideOverlapMenu()
	local cx, cy = getCursorPositionUI()
	local hits = collectOverlappingSelections(cx, cy)
	if #hits <= 1 and self.isSelected then
		return
	end
	if #hits > 1 then
		selectSelection(self)
		showOverlapMenu(hits, cx, cy, self)
		return
	end
	selectSelection(self)
end

-- hide overlap menu when clicking elsewhere (non-blocking)
local function overlapGlobalMouseDown()
	local menu = Internal.overlapMenu
	if not (lib.isEditing and menu and menu:IsShown()) then
		return
	end
	if MouseIsOver and MouseIsOver(menu, 4, 4, 4, 4) then
		return
	end
	local focus = GetMouseFoci and GetMouseFoci() or GetMouseFocus()
	if focus and (focus == menu or (focus.IsDescendantOf and focus:IsDescendantOf(menu))) then
		return
	end
	hideOverlapMenu()
end

local overlapGlobalFrame = CreateFrame("Frame")
overlapGlobalFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
overlapGlobalFrame:SetScript("OnEvent", overlapGlobalMouseDown)

local function onEditModeEnter()
	-- GetLayouts is allocation-heavy; only refresh when cache is missing.
	if not lib.activeLayoutIndex or not State.layoutSnapshot then
		updateActiveLayoutFromAPI()
	end
	restoreManagerExtraFrames(true)
	lib.isEditing = true
	resetSelectionIndicators()
	Internal:RefreshManagerTogglePanel()
	for _, callback in next, lib.eventHandlersEnter do
		securecallfunction(callback)
	end
end

local function onEditModeExit()
	lib.isEditing = false
	resetSelectionIndicators(true)
	hideOverlapMenu()
	updateManagerEyeButton()
	for _, callback in next, lib.eventHandlersExit do
		securecallfunction(callback)
	end
end

-- API callbacks --------------------------------------------------------------------
lib.eventHandlersEnter = lib.eventHandlersEnter or {}
lib.eventHandlersExit = lib.eventHandlersExit or {}
lib.eventHandlersLayout = lib.eventHandlersLayout or {}
lib.eventHandlersLayoutAdded = lib.eventHandlersLayoutAdded or {}
lib.eventHandlersLayoutDeleted = lib.eventHandlersLayoutDeleted or {}
lib.eventHandlersLayoutRenamed = lib.eventHandlersLayoutRenamed or {}
lib.eventHandlersSpec = lib.eventHandlersSpec or {}
lib.eventHandlersLayoutDuplicate = lib.eventHandlersLayoutDuplicate or {}

function Internal:EnsureDialog()
	if not self.dialog then
		self.dialog = self.CreateDialog()
		self.dialog:HookScript("OnHide", function()
			resetSelectionIndicators()
		end)
		applyDialogPosition(self.dialog)
	end

	if not self._dialogInfrastructureReady then
		self._dialogInfrastructureReady = true

		local combatWatcher = CreateFrame("Frame")
		combatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
		combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		combatWatcher:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		combatWatcher:SetScript("OnEvent", function(_, event)
			if event == "PLAYER_REGEN_DISABLED" then
				resetSelectionIndicators()
			elseif event == "PLAYER_REGEN_ENABLED" and lib.isEditing then
				resetSelectionIndicators()
			elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
				Layout:HandleSpecChanged()
			end
			if lib.isEditing then
				Internal:RefreshManagerTogglePanel()
			end
		end)
		self.combatWatcher = combatWatcher

		EventRegistry:RegisterFrameEventAndCallback("EDIT_MODE_LAYOUTS_UPDATED", function(_, layoutInfo)
			Layout:HandleLayoutsChanged(nil, layoutInfo)
		end)
		EventRegistry:RegisterCallback("EditMode.SavedLayouts", function()
			if C_EditMode and C_EditMode.GetLayouts then
				Layout:HandleLayoutsChanged(nil, C_EditMode.GetLayouts())
			end
		end)

		if EditModeManagerFrame then
			EditModeManagerFrame:HookScript("OnShow", onEditModeEnter)
			EditModeManagerFrame:HookScript("OnHide", onEditModeExit)
			ensureManagerEyeButton()
			hooksecurefunc(EditModeManagerFrame, "SelectSystem", function()
				resetSelectionIndicators()
			end)
		end

		if C_EditMode then
			if C_EditMode.OnLayoutDeleted then
				hooksecurefunc(C_EditMode, "OnLayoutDeleted", function(deletedLayoutIndex)
					Layout:HandleLayoutDeleted(deletedLayoutIndex)
				end)
			end
			if C_EditMode.OnLayoutAdded then
				hooksecurefunc(
					C_EditMode,
					"OnLayoutAdded",
					function(addedLayoutIndex, activateNewLayout, isLayoutImported)
						Layout:HandleLayoutAdded(addedLayoutIndex, activateNewLayout, isLayoutImported)
					end
				)
			end
		end
	end

	return self.dialog
end

-- API ------------------------------------------------------------------------------
function lib:AddFrame(frame, callback, default)
	local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
	selection:SetAllPoints()
	selection:SetScript("OnMouseDown", handleSelectionMouseDown)
	selection:SetScript("OnDragStart", beginSelectionDrag)
	selection:SetScript("OnDragStop", finishSelectionDrag)
	selection:SetScript("OnKeyDown", function(selectionFrame, key)
		if not selectionFrame.isSelected or isInCombat() then
			return
		end
		if not isDragAllowed(selectionFrame.parent) then
			return
		end
		local step = IsShiftKeyDown() and 10 or 1
		if key == "UP" then
			setPropagateKeyboardInputSafe(selectionFrame, false)
			adjustPosition(selectionFrame.parent, 0, step)
		elseif key == "DOWN" then
			setPropagateKeyboardInputSafe(selectionFrame, false)
			adjustPosition(selectionFrame.parent, 0, -step)
		elseif key == "LEFT" then
			setPropagateKeyboardInputSafe(selectionFrame, false)
			adjustPosition(selectionFrame.parent, -step, 0)
		elseif key == "RIGHT" then
			setPropagateKeyboardInputSafe(selectionFrame, false)
			adjustPosition(selectionFrame.parent, step, 0)
		else
			setPropagateKeyboardInputSafe(selectionFrame, true)
		end
	end)
	selection:SetScript("OnKeyUp", function(selectionFrame)
		setPropagateKeyboardInputSafe(selectionFrame, true)
	end)
	updateSelectionKeyboard(selection)
	selection:Hide()

	ensureMagnetismAPI(frame, selection)

	selection.labelHidden = false
	selection.overlayHidden = false
	if default then
		local toggle = default.enableOverlayToggle
			or default.overlayToggleEnabled
			or (default.enableOverlayToggle == false and false)
			or (default.overlayToggleEnabled == false and false)
		if toggle ~= nil then
			State.overlayToggleFlags[frame] = not not toggle
		end
		if default.allowDrag ~= nil or default.dragEnabled ~= nil then
			State.dragPredicates[frame] = (default.allowDrag ~= nil) and default.allowDrag or default.dragEnabled
		end
	end
	if select(4, GetBuildInfo()) >= 110200 then
		selection.systemBaseName = frame.editModeName or frame:GetName()
		selection.system = {}
		selection.system.GetSystemName = function()
			if selection.labelHidden then
				return ""
			end
			return selection.systemBaseName
		end
	else
		selection.Label:SetText(frame.editModeName or frame:GetName())
	end

	State.selectionRegistry[frame] = selection
	State.frameHandlers[frame] = callback
	State.defaultPositions[frame] = default
	if default then
		local toggle = default.enableOverlayToggle
			or default.overlayToggleEnabled
			or (default.enableOverlayToggle == false and false)
			or (default.overlayToggleEnabled == false and false)
		if toggle ~= nil then
			State.overlayToggleFlags[frame] = not not toggle
		end
		if default.allowDrag ~= nil or default.dragEnabled ~= nil then
			State.dragPredicates[frame] = (default.allowDrag ~= nil) and default.allowDrag or default.dragEnabled
		end
		if default.collapseExclusive ~= nil or default.exclusiveCollapse ~= nil then
			State.collapseExclusiveFlags[frame] = (default.collapseExclusive ~= nil) and default.collapseExclusive
				or default.exclusiveCollapse
		end
		if default.showReset ~= nil then
			State.resetToggles[frame] = not not default.showReset
		end
		if default.showSettingsReset ~= nil then
			State.settingsResetToggles[frame] = not not default.showSettingsReset
		end
		if default.settingsSpacing ~= nil then
			State.settingsSpacingOverrides[frame] = normalizeSpacing(default.settingsSpacing, DEFAULT_SETTINGS_SPACING)
		end
		if default.settingsMaxHeight ~= nil or default.maxSettingsHeight ~= nil then
			local v = default.settingsMaxHeight ~= nil and default.settingsMaxHeight or default.maxSettingsHeight
			State.settingsMaxHeightOverrides[frame] = normalizePositive(v, nil)
		end
		if default.sliderHeight ~= nil then
			State.sliderHeightOverrides[frame] = normalizePositive(default.sliderHeight, DEFAULT_SLIDER_HEIGHT)
			setRowHeightOverride(frame, "slider", default.sliderHeight)
		end
		if default.checkboxHeight ~= nil then
			setRowHeightOverride(frame, "checkbox", default.checkboxHeight)
		end
		if default.dropdownHeight ~= nil then
			setRowHeightOverride(frame, "dropdown", default.dropdownHeight)
		end
		if default.multiDropdownHeight ~= nil then
			setRowHeightOverride(frame, "multiDropdown", default.multiDropdownHeight)
		end
		if default.multiDropdownSummaryHeight ~= nil then
			setRowHeightOverride(frame, "multiDropdownSummary", default.multiDropdownSummaryHeight)
		end
		if default.colorHeight ~= nil then
			setRowHeightOverride(frame, "color", default.colorHeight)
		end
		if default.checkboxColorHeight ~= nil then
			setRowHeightOverride(frame, "checkboxColor", default.checkboxColorHeight)
		end
		if default.dropdownColorHeight ~= nil then
			setRowHeightOverride(frame, "dropdownColor", default.dropdownColorHeight)
		end
		if default.inputHeight ~= nil then
			setRowHeightOverride(frame, "input", default.inputHeight)
		end
		if default.dividerHeight ~= nil then
			setRowHeightOverride(frame, "divider", default.dividerHeight)
		end
		if default.collapsibleHeight ~= nil then
			setRowHeightOverride(frame, "collapsible", default.collapsibleHeight)
		end
	end

	Internal:EnsureDialog()
	updateManagerEyeButton()
end

function lib:AddFrameSettings(frame, settings)
	if not State.selectionRegistry[frame] then
		error("frame must be registered")
	end
	State.settingSheets[frame] = settings
end

function lib:AddFrameSettingsButton(frame, data)
	if not State.buttonSpecs[frame] then
		State.buttonSpecs[frame] = {}
	end
	table.insert(State.buttonSpecs[frame], data)
end

function lib:ShowStandaloneSettingsDialog(frame, options)
	assert(frame, "frame is required")
	assert(options == nil or type(options) == "table", "options must be a table")
	if lib.isEditing then
		return nil, "standalone settings are unavailable while edit mode is active"
	end

	options = options or {}
	local context = normalizeDialogContext({
		mode = "standalone",
		frame = frame,
		title = options.title,
		settings = options.settings,
		buttons = options.buttons,
		defaultPosition = options.defaultPosition,
		showReset = options.showReset,
		showSettingsReset = options.showSettingsReset,
		settingsSpacing = options.settingsSpacing,
		settingsMaxHeight = options.settingsMaxHeight or options.maxSettingsHeight,
		point = options.point or options.anchorPoint,
		relativePoint = options.relativePoint or options.anchorRelativePoint,
		relativeTo = options.relativeTo or options.anchorTo,
		x = options.x or options.offsetX,
		y = options.y or options.offsetY,
		onHide = options.onHide,
	})

	local hasSettings = (type(context.settings) == "table" and #context.settings > 0)
		or State.settingSheets[frame] ~= nil
	local hasButtons = (type(context.buttons) == "table" and #context.buttons > 0) or State.buttonSpecs[frame] ~= nil
	local hasReset = options.showReset == true
	if options.showReset ~= false and not hasReset then
		hasReset = options.defaultPosition ~= nil or lib:GetFrameDefaultPosition(frame) ~= nil
	end
	if not hasSettings and not hasButtons and not hasReset then
		return nil, "no settings, buttons, or reset position were provided for this frame"
	end

	local dialog = Internal:EnsureDialog()
	dialog:Update(context)
	return dialog
end

function lib:HideStandaloneSettingsDialog(frame)
	local dialog = Internal.dialog
	if not (dialog and dialog:IsShown() and dialog.mode == "standalone") then
		return false
	end
	if frame and getDialogFrame(dialog) ~= frame then
		return false
	end
	dialog:Hide()
	return true
end

function lib:IsStandaloneSettingsDialogShown(frame)
	local dialog = Internal.dialog
	if not (dialog and dialog:IsShown() and dialog.mode == "standalone") then
		return false
	end
	if frame and getDialogFrame(dialog) ~= frame then
		return false
	end
	return true
end

function lib:AddManagerToggle(data)
	assert(type(data) == "table", "data must be a table")
	local id = data.id or data.name or data.label
	assert(type(id) == "string" and id ~= "", "manager toggle requires id or label")
	data.id = id
	resolveManagerToggleCategory(data)
	if not State.managerToggleSpecs[id] then
		table.insert(State.managerToggleOrder, id)
	end
	State.managerToggleSpecs[id] = data

	if State.managerToggleState[id] == nil and data.default ~= nil then
		State.managerToggleState[id] = not not data.default
		if data.applyDefault ~= false then
			applyManagerToggleValue(data, State.managerToggleState[id])
		end
	end

	Internal:RefreshManagerTogglePanel()
end

function lib:AddManagerCheckbox(data)
	return lib:AddManagerToggle(data)
end

function lib:AddManagerCategory(data)
	assert(type(data) == "table", "data must be a table")
	local label = data.label or data.name
	assert(type(label) == "string" and label ~= "", "category requires label")
	local id = data.id or label
	ensureManagerCategory(id, label, data.sort)
	Internal:RefreshManagerTogglePanel()
end

function lib:RemoveManagerToggle(id)
	if not id then
		return
	end
	State.managerToggleSpecs[id] = nil
	State.managerToggleState[id] = nil
	for index, entry in ipairs(State.managerToggleOrder) do
		if entry == id then
			table.remove(State.managerToggleOrder, index)
			break
		end
	end
	Internal:RefreshManagerTogglePanel()
end

function lib:RefreshManagerToggles()
	Internal:RefreshManagerTogglePanel()
end

function lib:SetManagerTogglePanelMaxHeight(height)
	Internal.managerToggleMaxHeight = normalizePositive(height, DEFAULT_MANAGER_TOGGLE_MAX_HEIGHT)
	local panel = Internal.managerTogglePanel
	if panel then
		panel.maxHeight = Internal.managerToggleMaxHeight
		panel:ApplyScrollLimit()
	end
end

function lib:SetFrameResetVisible(frame, showReset)
	State.resetToggles[frame] = not not showReset
	if Internal.dialog and getDialogFrame(Internal.dialog) == frame then
		Internal.dialog:UpdateButtons()
	end
end

function lib:SetFrameSettingsResetVisible(frame, showReset)
	State.settingsResetToggles[frame] = not not showReset
	if Internal.dialog and getDialogFrame(Internal.dialog) == frame then
		Internal.dialog:UpdateSettings()
	end
end

function lib:SetFrameSettingsMaxHeight(frame, height)
	if height == nil then
		State.settingsMaxHeightOverrides[frame] = nil
	else
		State.settingsMaxHeightOverrides[frame] = normalizePositive(height, nil)
	end

	if Internal.dialog and getDialogFrame(Internal.dialog) == frame then
		Internal.dialog:Layout()
	end
end

function lib:SetFrameDragEnabled(frame, enabledOrPredicate)
	if enabledOrPredicate == nil then
		State.dragPredicates[frame] = nil
	else
		State.dragPredicates[frame] = enabledOrPredicate
	end
end

function lib:SetFrameCollapseExclusive(frame, enabled)
	if enabled == nil then
		State.collapseExclusiveFlags[frame] = nil
	else
		State.collapseExclusiveFlags[frame] = not not enabled
	end
end

function lib:SetFrameOverlayToggleEnabled(frame, enabled)
	State.overlayToggleFlags[frame] = not not enabled
	if enabled == false and State.selectionRegistry[frame] then
		local selection = State.selectionRegistry[frame]
		selection.overlayHidden = false
		updateSelectionVisuals(selection, false)
	end
	updateManagerEyeButton()
end

function lib:RegisterCallback(event, callback)
	assert(event and type(event) == "string", "event must be a string")
	assert(callback and type(callback) == "function", "callback must be a function")
	if event == "enter" then
		table.insert(lib.eventHandlersEnter, callback)
	elseif event == "exit" then
		table.insert(lib.eventHandlersExit, callback)
	elseif event == "layout" then
		table.insert(lib.eventHandlersLayout, callback)
	elseif event == "layoutadded" then
		table.insert(lib.eventHandlersLayoutAdded, callback)
	elseif event == "layoutdeleted" then
		table.insert(lib.eventHandlersLayoutDeleted, callback)
	elseif event == "layoutrenamed" then
		table.insert(lib.eventHandlersLayoutRenamed, callback)
	elseif event == "spec" then
		table.insert(lib.eventHandlersSpec, callback)
	elseif event == "layoutduplicate" then
		table.insert(lib.eventHandlersLayoutDuplicate, callback)
	else
		error('invalid callback event "' .. event .. '"')
	end
end

function lib:GetActiveLayoutName()
	return lib.activeLayoutName
end

function lib:GetActiveLayoutIndex()
	if not lib.activeLayoutIndex then
		updateActiveLayoutFromAPI()
	end
	return lib.activeLayoutIndex
end

function lib:IsInEditMode()
	return not not lib.isEditing
end

function lib:GetLayouts()
	if not State.layoutSnapshot then
		updateActiveLayoutFromAPI()
	end
	local layoutInfo = C_EditMode_GetLayouts and C_EditMode_GetLayouts()
	local customLayouts = layoutInfo and layoutInfo.layouts
	local modernType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Modern
	local classicType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Classic
	local activeLayout = layoutInfo and layoutInfo.activeLayout
	local results = {}
	results[1] = { index = 1, name = layoutNames[1], layoutType = modernType, isActive = activeLayout == 1 and 1 or 0 }
	results[2] = { index = 2, name = layoutNames[2], layoutType = classicType, isActive = activeLayout == 2 and 1 or 0 }
	for i, name in ipairs(State.layoutSnapshot or {}) do
		local uiIndex = i + 2
		local entry = customLayouts and customLayouts[i]
		results[#results + 1] = {
			index = uiIndex,
			name = name or layoutNames[uiIndex],
			layoutType = entry and entry.layoutType,
			isActive = activeLayout == uiIndex and 1 or 0,
		}
	end
	return results
end

function lib:GetFrameDefaultPosition(frame)
	return State.defaultPositions[frame]
end

-- internal entry points ------------------------------------------------------------
function Internal:TriggerCallback(frame, ...)
	if State.frameHandlers[frame] then
		securecallfunction(State.frameHandlers[frame], frame, lib.activeLayoutName, ...)
	end
end

function Internal:GetFrameSettings(frame)
	if State.settingSheets[frame] then
		return State.settingSheets[frame], #State.settingSheets[frame]
	else
		return nil, 0
	end
end

function Internal:GetFrameButtons(frame)
	if State.buttonSpecs[frame] then
		return State.buttonSpecs[frame], #State.buttonSpecs[frame]
	else
		return nil, 0
	end
end

local function hasOpenDropdownMenu()
	local menuSystem = _G.Menu
	local menuManager = menuSystem and menuSystem.GetManager and menuSystem.GetManager()
	if menuManager and menuManager.GetOpenMenu then
		local ok, openMenu = pcall(menuManager.GetOpenMenu, menuManager)
		if ok and openMenu then
			return true
		end
	end
	return _G.UIDROPDOWNMENU_OPEN_MENU ~= nil
end

local function mergeRefreshSettingValueTargets(existing, incoming)
	if incoming == nil then
		return nil, true
	end
	if type(incoming) ~= "table" then
		return existing, existing ~= nil
	end
	if existing == nil then
		existing = {}
	end
	for _, entry in ipairs(incoming) do
		if type(entry) == "table" then
			existing[entry] = true
		end
	end
	for key, value in pairs(incoming) do
		if type(key) == "table" and value then
			existing[key] = true
		elseif type(value) == "table" then
			existing[value] = true
		end
	end
	return existing, next(existing) ~= nil
end

function Internal:_scheduleSettingsRefresh(delay)
	if self._refreshRunnerScheduled then
		return
	end
	self._refreshRunnerScheduled = true
	local wait = tonumber(delay) or 0
	if wait < 0 then
		wait = 0
	end
	if not (C_Timer and C_Timer.After) then
		self._refreshRunnerScheduled = false
		self:_runDeferredSettingsRefresh()
		return
	end
	self._refreshRunner = self._refreshRunner
		or function()
			Internal._refreshRunnerScheduled = false
			Internal:_runDeferredSettingsRefresh()
		end
	C_Timer.After(wait, self._refreshRunner)
end

function Internal:_runDeferredSettingsRefresh()
	if hasOpenDropdownMenu() then
		self:_scheduleSettingsRefresh(0.05)
		return
	end

	local refreshLayout = self._refreshQueued == true
	local refreshValues = self._refreshValuesQueued == true
	local targets = self._refreshValueTargets

	self._refreshQueued = nil
	self._refreshValuesQueued = nil
	self._refreshValueTargets = nil

	if refreshLayout then
		self:RefreshSettings(true)
	end
	if refreshValues then
		self:RefreshSettingValues(targets, true)
	end
end

function Internal:RequestRefreshSettings()
	self._refreshQueued = true
	self:_scheduleSettingsRefresh(0)
end

function Internal:RequestRefreshSettingValues(targetSettings)
	self._refreshValuesQueued = true
	self._refreshValueTargets = mergeRefreshSettingValueTargets(self._refreshValueTargets, targetSettings)
	self:_scheduleSettingsRefresh(0)
end

function Internal:RefreshSettings(fromDeferred)
	if not fromDeferred and hasOpenDropdownMenu() then
		self:RequestRefreshSettings()
		return
	end
	if not (Internal.dialog and Internal.dialog:IsShown()) then
		return
	end
	local parent = Internal.dialog.Settings
	if not parent then
		return
	end
	local selectionParent = getDialogFrame(Internal.dialog)
	local layoutName = lib.activeLayoutName
	local layoutIndex = lib:GetActiveLayoutIndex()
	local layoutDirty = false
	for _, child in ipairs({ parent:GetChildren() }) do
		if child.setting then
			local data = child.setting
			if child.SetEnabled then
				local enabled = true
				if data.isEnabled then
					local ok, result = pcall(data.isEnabled, layoutName, layoutIndex)
					enabled = ok and result ~= false
				elseif data.disabled then
					local ok, result = pcall(data.disabled, layoutName, layoutIndex)
					enabled = not (ok and result == true)
				end
				if child._eqolEnabled ~= enabled then
					child._eqolEnabled = enabled
					child:SetEnabled(enabled)
				end
			end

			local collapsedParent = (data.kind ~= lib.SettingType.Collapsible)
				and data.parentId
				and Collapse:Get(selectionParent, data.parentId)
			local visible = evaluateVisibilityFast(data, layoutName, layoutIndex) and not collapsedParent
			local wantIgnore = not visible
			local haveIgnore = child.ignoreInLayout == true
			if wantIgnore ~= haveIgnore then
				child.ignoreInLayout = wantIgnore
				layoutDirty = true
			end
			if visible ~= child:IsShown() then
				if visible then
					child:Show()
				else
					child:Hide()
				end
				layoutDirty = true
			end
		end
	end
	if layoutDirty then
		if parent.Layout then
			parent:Layout()
		end
		if Internal.dialog then
			FixScrollBarInside(Internal.dialog.SettingsScroll)
			UpdateScrollChildWidth(Internal.dialog)
		end
		if Internal.dialog and Internal.dialog.Layout then
			Internal.dialog:Layout()
		end
	end
end

function Internal:RefreshSettingValues(targetSettings, fromDeferred)
	if not fromDeferred and hasOpenDropdownMenu() then
		self:RequestRefreshSettingValues(targetSettings)
		return
	end
	if not (Internal.dialog and Internal.dialog:IsShown()) then
		return
	end
	local parent = Internal.dialog.Settings
	if not parent then
		return
	end
	local selection = Internal.dialog.selection
	if not selection then
		return
	end
	local selectionParent = getDialogFrame(Internal.dialog)
	local layoutName = lib.activeLayoutName
	local layoutIndex = lib:GetActiveLayoutIndex()
	local settings, num = getDialogSettings(Internal.dialog)
	if not settings or num == 0 then
		return
	end
	local targets
	if type(targetSettings) == "table" then
		targets = {}
		for _, entry in ipairs(targetSettings) do
			if type(entry) == "table" then
				targets[entry] = true
			end
		end
		for key, value in pairs(targetSettings) do
			if type(key) == "table" and value then
				targets[key] = true
			elseif type(value) == "table" then
				targets[value] = true
			end
		end
		if next(targets) == nil then
			targets = nil
		end
	end
	for _, child in ipairs({ parent:GetChildren() }) do
		local data
		if child.layoutIndex and settings[child.layoutIndex] then
			data = settings[child.layoutIndex]
		elseif child.setting then
			data = child.setting
		end
		if data and child.Setup and (not targets or targets[data]) then
			ApplySettingsRowWidth(child, parent)
			child:Setup(data, selection)
			child.setting = data
			if child.SetEnabled then
				local enabled = true
				if data.isEnabled then
					local ok, result = pcall(data.isEnabled, layoutName, layoutIndex)
					enabled = ok and result ~= false
				elseif data.disabled then
					local ok, result = pcall(data.disabled, layoutName, layoutIndex)
					enabled = not (ok and result == true)
				end
				child:SetEnabled(enabled)
				child._eqolEnabled = enabled
			end
			local collapsed = (data.kind ~= lib.SettingType.Collapsible)
				and Collapse:Get(selectionParent, data.parentId)
			local visible = evaluateVisibility(data, layoutName, layoutIndex) and not collapsed
			if visible then
				child.ignoreInLayout = nil
				child:Show()
			else
				child.ignoreInLayout = true
				child:Hide()
			end
		end
	end
	if parent.Layout then
		parent:Layout()
	end
	if Internal.dialog then
		FixScrollBarInside(Internal.dialog.SettingsScroll)
		UpdateScrollChildWidth(Internal.dialog)
		if Internal.dialog.Layout then
			Internal.dialog:Layout()
		end
	end
end
