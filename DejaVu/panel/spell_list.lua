--[[
文件定位：
  DejaVu 技能选项设置项模块，负责在panelFrame上创建技能列表控件。


状态：
  draft
]]

local addonName, addonTable = ...
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local Panel = addonTable.Panel
local COLOR = Panel.COLOR
local UI = Panel.UI

local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellDescription = C_Spell.GetSpellDescription

local floor = math.floor
local insert = table.insert

local function ApplyDefaultValue(config, value)
    if not config or not config.key then
        return
    end
    if Panel.DefaultApplied[config.key] then
        return
    end
    config:set_default(value)
    Panel.DefaultApplied[config.key] = true
end

local function NormalizeSpellID(value)
    local numberValue = tonumber(value)
    if not numberValue then
        return nil
    end
    numberValue = floor(numberValue)
    if numberValue <= 0 then
        return nil
    end
    return numberValue
end

local function CopySpellList(source)
    local copy = {}
    if type(source) ~= "table" then
        return copy
    end
    for rawSpellID, enabled in pairs(source) do
        if enabled then
            local spellID = NormalizeSpellID(rawSpellID)
            if spellID then
                copy[spellID] = true
            end
        end
    end
    return copy
end

local function CollectSpellIDs(spellList)
    local spellIDs = {}
    if type(spellList) ~= "table" then
        return spellIDs
    end
    for rawSpellID, enabled in pairs(spellList) do
        if enabled then
            local spellID = NormalizeSpellID(rawSpellID)
            if spellID then
                insert(spellIDs, spellID)
            end
        end
    end
    return spellIDs
end

local function EnsureSpellListEditorFrame()
    if Panel.SpellListEditorFrame then
        return Panel.SpellListEditorFrame
    end
    if not Panel.Frame then
        return nil
    end

    local SIZE = Panel.SIZE
    local scale = 4
    local maxRows = 15
    local lineHeight = SIZE.SETTING_LINE.Height
    local panelWidth = GetUIScaleFactor(scale * 120)
    local panelHeight = GetUIScaleFactor(scale * 152) + lineHeight
    local spacing = SIZE.MainFrame.Spacing
    local border = SIZE.MainFrame.Border
    local iconFallback = 61304

    local frame = CreateFrame("Frame", addonName .. "spellListEditorFrame", UIParent)
    frame:SetPoint("TOPLEFT", Panel.Frame, "TOPRIGHT", 0, 0)
    frame:SetSize(panelWidth, panelHeight)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(905)
    frame:Hide()

    frame.bg, frame.art = UI.ApplyBorderAndFill(frame, COLOR.WindowBorder, COLOR.WindowBg, SIZE.MainFrame.Border)

    local contentWidth = panelWidth - spacing * 2
    local actionButtonWidth = GetUIScaleFactor(scale * 16)
    local actionGap = spacing
    local inputWidth = contentWidth - actionButtonWidth * 2 - actionGap * 2
    local addButtonX = spacing
    local deleteButtonX = addButtonX + actionButtonWidth + actionGap
    local inputX = deleteButtonX + actionButtonWidth + actionGap
    local inputRowY = -(spacing * 2 + lineHeight)
    local listTopY = -(spacing * 3 + lineHeight * 2)

    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", spacing, -spacing)
    frame.titleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -spacing, -spacing)
    frame.titleText:SetHeight(lineHeight)
    frame.titleText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    frame.titleText:SetJustifyH("CENTER")
    frame.titleText:SetJustifyV("MIDDLE")
    frame.titleText:SetTextColor(COLOR.Text:GetRGBA())
    frame.titleText:SetText("法术列表")

    frame.spellIDBox = CreateFrame("EditBox", addonName .. "spellListInputBox", frame)
    frame.spellIDBox:SetPoint("TOPLEFT", frame, "TOPLEFT", inputX, inputRowY)
    frame.spellIDBox:SetSize(inputWidth, lineHeight)
    frame.spellIDBox:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    frame.spellIDBox:SetJustifyH("LEFT")
    frame.spellIDBox:SetJustifyV("MIDDLE")
    frame.spellIDBox:SetTextColor(COLOR.Text:GetRGBA())
    frame.spellIDBox:SetAutoFocus(false)
    frame.spellIDBox:SetMultiLine(false)
    frame.spellIDBox:SetTextInsets(spacing, spacing, 0, 0)

    frame.spellIDBox.bg = frame.spellIDBox:CreateTexture(nil, "BACKGROUND")
    frame.spellIDBox.bg:SetAllPoints(frame.spellIDBox)
    frame.spellIDBox.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA())

    frame.spellIDBox.art = frame.spellIDBox:CreateTexture(nil, "ARTWORK")
    frame.spellIDBox.art:SetPoint("TOPLEFT", frame.spellIDBox, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border)
    frame.spellIDBox.art:SetPoint("BOTTOMRIGHT", frame.spellIDBox, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border)
    frame.spellIDBox.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA())

    frame.spellIDBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    frame.spellIDBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    frame.addButton = UI.CreateButton(frame, "spellListAddButton", addButtonX, inputRowY, actionButtonWidth, SIZE.BUTTON.Height, "新增")
    frame.deleteButton = UI.CreateButton(frame, "spellListDeleteButton", deleteButtonX, inputRowY, actionButtonWidth, SIZE.BUTTON.Height, "删除")

    frame.listFrame = CreateFrame("Frame", addonName .. "spellListListFrame", frame)
    frame.listFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", spacing, listTopY)
    frame.listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -spacing, spacing)
    frame.listFrame:EnableMouseWheel(true)
    frame.listFrame.bg, frame.listFrame.art = UI.ApplyBorderAndFill(frame.listFrame, COLOR.ButtonBorder, COLOR.DropdownBg, border)

    frame.emptyText = frame.listFrame:CreateFontString(nil, "OVERLAY")
    frame.emptyText:SetPoint("CENTER", frame.listFrame, "CENTER")
    frame.emptyText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    frame.emptyText:SetJustifyH("CENTER")
    frame.emptyText:SetJustifyV("MIDDLE")
    frame.emptyText:SetTextColor(0.65, 0.65, 0.65)
    frame.emptyText:SetText("暂无数据")
    frame.emptyText:Hide()

    frame.rows = {}
    for i = 1, maxRows do
        local row = CreateFrame("Frame", addonName .. "spellListRow" .. i, frame.listFrame)
        row:SetPoint("TOPLEFT", frame.listFrame, "TOPLEFT", border, -border - (i - 1) * lineHeight)
        row:SetPoint("TOPRIGHT", frame.listFrame, "TOPRIGHT", -border, -border - (i - 1) * lineHeight)
        row:SetHeight(lineHeight)
        row:EnableMouse(true)
        row:EnableMouseWheel(true)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetColorTexture(0, 0, 0, 0)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", spacing, 0)
        row.icon:SetSize(lineHeight - border * 2, lineHeight - border * 2)
        row.icon:SetTexture(iconFallback)

        row.idText = row:CreateFontString(nil, "OVERLAY")
        row.idText:SetPoint("RIGHT", row, "RIGHT", -spacing, 0)
        row.idText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(4.5 * scale), "")
        row.idText:SetJustifyH("RIGHT")
        row.idText:SetJustifyV("MIDDLE")
        row.idText:SetTextColor(COLOR.Text:GetRGBA())

        row.nameText = row:CreateFontString(nil, "OVERLAY")
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", spacing, 0)
        row.nameText:SetPoint("RIGHT", row.idText, "LEFT", -spacing, 0)
        row.nameText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetJustifyV("MIDDLE")
        row.nameText:SetTextColor(COLOR.Text:GetRGBA())

        frame.rows[i] = row
    end

    function frame:_ClampScrollOffset()
        local total = self._spellIDs and #self._spellIDs or 0
        local maxOffset = math.max(0, total - maxRows)
        if not self._scrollOffset then
            self._scrollOffset = 0
        end
        if self._scrollOffset < 0 then
            self._scrollOffset = 0
        elseif self._scrollOffset > maxOffset then
            self._scrollOffset = maxOffset
        end
    end

    function frame:_SetRowVisual(row)
        if row._spellID and self._selectedSpellID == row._spellID then
            row.bg:SetColorTexture(73 / 255, 179 / 255, 234 / 255, 0.35)
            return
        end
        if row._hovered then
            row.bg:SetColorTexture(COLOR.RowHover:GetRGBA())
            return
        end
        row.bg:SetColorTexture(0, 0, 0, 0)
    end

    function frame:RefreshList()
        self._spellIDs = CollectSpellIDs(self._currentData)
        self:_ClampScrollOffset()
        if #self._spellIDs == 0 then
            self.emptyText:Show()
        else
            self.emptyText:Hide()
        end

        for index, row in ipairs(self.rows) do
            local listIndex = (self._scrollOffset or 0) + index
            local spellID = self._spellIDs[listIndex]

            row._spellID = spellID
            row._hovered = false
            if spellID then
                local spellName = GetSpellName(spellID) or ""
                local iconID = GetSpellTexture(spellID) or iconFallback
                row.icon:SetTexture(iconID)
                row.nameText:SetText(spellName)
                row.idText:SetText(tostring(spellID))
                row:Show()
            else
                row.icon:SetTexture(iconFallback)
                row.nameText:SetText("")
                row.idText:SetText("")
                row:Hide()
            end
            self:_SetRowVisual(row)
        end
    end

    function frame:BindSetting(setting)
        self._currentSetting = setting
        if self.titleText then
            local title = "法术列表"
            if type(setting) == "table" then
                title = tostring(setting.name or setting.key or title)
            end
            self.titleText:SetText(title)
        end
        if type(setting) ~= "table" or not setting.bind_config then
            self._currentData = {}
        else
            self._currentData = CopySpellList(setting.bind_config:get_value())
        end
        self._selectedSpellID = nil
        self._scrollOffset = 0
        self.spellIDBox:SetText("")
        self:RefreshList()
    end

    function frame:PersistCurrentValue()
        if type(self._currentSetting) ~= "table" then
            return
        end
        local config = self._currentSetting.bind_config
        if not config then
            return
        end
        config:set_value(CopySpellList(self._currentData))
        self._currentData = CopySpellList(config:get_value())
    end

    local function GetInputSpellID()
        local text = frame.spellIDBox:GetText() or ""
        text = text:gsub("%s+", "")
        return NormalizeSpellID(text)
    end

    frame.addButton:HookScript("OnMouseUp", function()
        if type(frame._currentSetting) ~= "table" then
            return
        end

        local spellID = GetInputSpellID()
        if not spellID then
            return
        end

        frame._currentData[spellID] = true
        frame._selectedSpellID = spellID
        frame.spellIDBox:SetText(tostring(spellID))
        frame:PersistCurrentValue()
        frame:RefreshList()
    end)

    frame.deleteButton:HookScript("OnMouseUp", function()
        if type(frame._currentSetting) ~= "table" then
            return
        end

        local spellID = GetInputSpellID()
        if not spellID then
            return
        end

        frame._currentData[spellID] = nil
        if frame._selectedSpellID == spellID then
            frame._selectedSpellID = nil
        end
        frame:PersistCurrentValue()
        frame:RefreshList()
    end)

    frame.listFrame:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            frame._scrollOffset = (frame._scrollOffset or 0) - 1
        else
            frame._scrollOffset = (frame._scrollOffset or 0) + 1
        end
        frame:_ClampScrollOffset()
        frame:RefreshList()
    end)

    for _, row in ipairs(frame.rows) do
        row:SetScript("OnMouseDown", function(self)
            if not self._spellID then
                return
            end
            frame._selectedSpellID = self._spellID
            frame.spellIDBox:SetText(tostring(self._spellID))
            frame:RefreshList()
        end)
        row:SetScript("OnEnter", function(self)
            if not self._spellID then
                return
            end
            self._hovered = true
            frame:_SetRowVisual(self)

            local spellID = self._spellID
            local spellName = GetSpellName(spellID) or "未知技能"
            local description = GetSpellDescription(spellID)
            if not description or description == "" then
                description = "无描述"
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", spacing, 0)
            GameTooltip:SetFrameStrata("TOOLTIP")
            GameTooltip:SetFrameLevel(1000)
            GameTooltip:SetText("SpellID: " .. tostring(spellID), 1, 1, 1, 1, true)
            GameTooltip:AddLine(spellName, 0.9, 0.9, 0.9, true)
            GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self._hovered = false
            frame:_SetRowVisual(self)
            GameTooltip:Hide()
        end)
        row:SetScript("OnMouseWheel", function(_, delta)
            if frame.listFrame:GetScript("OnMouseWheel") then
                frame.listFrame:GetScript("OnMouseWheel")(frame.listFrame, delta)
            end
        end)
    end

    Panel.SpellListEditorFrame = frame
    return frame
end

addonTable.Panel.AddSpellListRow = function(row_info)
    local SIZE = Panel.SIZE
    local config = row_info.bind_config
    ApplyDefaultValue(config, row_info.default_value)

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip)
    if not row then
        return nil
    end

    local buttonX = SIZE.SETTING_LINE.TitleWidth + SIZE.SETTING_LINE.Spacing
    local buttonWidth = SIZE.SETTING_LINE.WidgetWidth
    local button = UI.CreateButton(row, "spellListSettingButton" .. row:GetName(), buttonX, 0, buttonWidth, SIZE.BUTTON.Height, "编辑")
    button:HookScript("OnMouseUp", function()
        local editor = EnsureSpellListEditorFrame()
        if not editor then
            return
        end
        if editor:IsShown() and editor._currentSetting == row_info then
            editor:Hide()
            return
        end
        editor:Show()
        editor:BindSetting(row_info)
    end)

    return row
end
