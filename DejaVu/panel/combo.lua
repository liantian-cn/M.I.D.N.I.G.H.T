--[[
文件定位：
  DejaVu 下拉选项设置项模块，负责在panelFrame上创建下拉菜单控件。


状态：
  draft
]]

local addonName, addonTable = ...
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local Panel = addonTable.Panel
local COLOR = Panel.COLOR
local UI = Panel.UI

local scale = 4

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

local function CreateDropdownControl(row, options, defaultValue, config)
    if not row then
        return nil
    end
    local SIZE = Panel.SIZE
    local ownerFrame = Panel.Frame or row:GetParent()

    local widget = CreateFrame("Frame", addonName .. "dropdownWidget" .. row:GetName(), row)
    widget:SetPoint("LEFT", row.title, "RIGHT", SIZE.SETTING_LINE.Spacing, 0)
    widget:SetSize(SIZE.SETTING_LINE.WidgetWidth, SIZE.SETTING_LINE.Height)
    widget:EnableMouse(true)

    widget.bg = widget:CreateTexture(nil, "BACKGROUND")
    widget.bg:SetAllPoints(widget)
    widget.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA())

    widget.art = widget:CreateTexture(nil, "ARTWORK")
    widget.art:SetPoint("TOPLEFT", widget, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border)
    widget.art:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border)
    widget.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA())

    local valueText = widget:CreateFontString(nil, "OVERLAY")
    valueText:SetPoint("LEFT", widget, "LEFT", SIZE.MainFrame.Spacing, 0)
    valueText:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing, 0)
    valueText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    valueText:SetJustifyH("LEFT")
    valueText:SetJustifyV("MIDDLE")
    valueText:SetTextColor(COLOR.Text:GetRGBA())

    local listFrame = CreateFrame("Frame", addonName .. "dropdownList" .. row:GetName(), ownerFrame)
    listFrame:SetPoint("TOPLEFT", widget, "BOTTOMLEFT", 0, -SIZE.SETTING_LINE.Spacing / 2)
    listFrame:SetPoint("TOPRIGHT", widget, "BOTTOMRIGHT", 0, -SIZE.SETTING_LINE.Spacing / 2)
    listFrame:SetHeight(#options * SIZE.SETTING_LINE.Height)
    listFrame:SetFrameStrata("TOOLTIP")
    listFrame:SetFrameLevel(920)
    listFrame:Hide()

    listFrame.bg, listFrame.art = UI.ApplyBorderAndFill(listFrame, COLOR.ButtonBorder, COLOR.DropdownBg, SIZE.MainFrame.Border)

    local function FindIndexByValue(value)
        for i, option in ipairs(options) do
            if option.k == value then
                return i
            end
        end
        return nil
    end

    local function SetDropdownValue(value, fromUser)
        local index = FindIndexByValue(value) or 1
        local option = options[index]
        if not option then
            return
        end
        valueText:SetText(option.v)
        if fromUser and config then
            config:set_value(option.k)
        end
    end

    for i, option in ipairs(options) do
        local item = CreateFrame("Frame", addonName .. "dropdownItem" .. row:GetName() .. i, listFrame)
        item:SetPoint("TOPLEFT", listFrame, "TOPLEFT", SIZE.MainFrame.Border, -SIZE.MainFrame.Border - (i - 1) * SIZE.SETTING_LINE.Height)
        item:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -SIZE.MainFrame.Border, -SIZE.MainFrame.Border - (i - 1) * SIZE.SETTING_LINE.Height)
        item:SetHeight(SIZE.SETTING_LINE.Height)
        item:EnableMouse(true)

        item.bg = item:CreateTexture(nil, "BACKGROUND")
        item.bg:SetAllPoints(item)
        item.bg:SetColorTexture(0, 0, 0, 0)

        item.text = item:CreateFontString(nil, "OVERLAY")
        item.text:SetPoint("LEFT", item, "LEFT", SIZE.MainFrame.Spacing, 0)
        item.text:SetPoint("RIGHT", item, "RIGHT", -SIZE.MainFrame.Spacing, 0)
        item.text:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
        item.text:SetJustifyH("LEFT")
        item.text:SetJustifyV("MIDDLE")
        item.text:SetTextColor(COLOR.Text:GetRGBA())
        item.text:SetText(option.v)

        item:SetScript("OnEnter", function()
            item.bg:SetColorTexture(COLOR.RowHover:GetRGBA())
        end)
        item:SetScript("OnLeave", function()
            item.bg:SetColorTexture(0, 0, 0, 0)
        end)
        item:SetScript("OnMouseDown", function()
            SetDropdownValue(option.k, true)
            listFrame:Hide()
        end)
    end

    local function ToggleList()
        if #options <= 0 then
            return
        end
        UI.ToggleFrame(listFrame)
    end

    row:SetScript("OnMouseDown", ToggleList)
    widget:SetScript("OnMouseDown", ToggleList)

    SetDropdownValue(defaultValue, false)
    return widget, SetDropdownValue
end

addonTable.Panel.AddComboRow = function(row_info)
    local config = row_info.bind_config
    ApplyDefaultValue(config, row_info.default_value)

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip)
    if not row then
        return nil
    end

    local _, setValue = CreateDropdownControl(row, row_info.options, row_info.default_value, config)
    if config then
        setValue(config:get_value(), false)
        config:register_callback(function(value)
            setValue(value, false)
        end)
    end
    return row
end
