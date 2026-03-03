--[[
文件定位：
  DejaVu 滑块设置项模块，负责在panelFrame上创建滑块控件。




状态：
  draft
]]

local addonName, addonTable = ...
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local Panel = addonTable.Panel
local COLOR = Panel.COLOR

local scale = 4

local strFind = string.find
local strSub = string.sub
local strFormat = string.format
local floor = math.floor

local function GetStepDecimals(step)
    local s = tostring(step)
    local dot = strFind(s, "%.")
    if not dot then
        return 0
    end
    local decimals = #s - dot
    while decimals > 0 and strSub(s, -1) == "0" do
        s = strSub(s, 1, -2)
        decimals = decimals - 1
    end
    return decimals
end

local function FormatStepValue(value, decimals)
    if decimals <= 0 then
        return strFormat("%d", floor(value + 0.5))
    end
    return strFormat("%." .. decimals .. "f", value)
end

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

addonTable.Panel.AddSliderRow = function(row_info)
    local SIZE = Panel.SIZE
    local config = row_info.bind_config
    ApplyDefaultValue(config, row_info.default_value)

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip)
    if not row then
        return nil
    end

    local minValue = row_info.min_value
    local maxValue = row_info.max_value
    local step = row_info.step
    local decimals = GetStepDecimals(step)

    local widget = CreateFrame("Frame", addonName .. "sliderWidget" .. row:GetName(), row)
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

    local slider = CreateFrame("Slider", addonName .. "slider" .. row:GetName(), widget)
    slider:SetPoint("LEFT", widget, "LEFT", SIZE.MainFrame.Spacing, 0)
    slider:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing * 2 - SIZE.SETTING_LINE.SliderValueWidth, 0)
    slider:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local bar = CreateFrame("Frame", addonName .. "sliderBar" .. row:GetName(), widget)
    bar:SetAllPoints(slider)
    bar.left = bar:CreateTexture(nil, "ARTWORK")
    bar.left:SetPoint("LEFT", bar, "LEFT")
    bar.left:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)
    bar.left:SetColorTexture(COLOR.SliderLeft:GetRGBA())
    bar.right = bar:CreateTexture(nil, "ARTWORK")
    bar.right:SetPoint("RIGHT", bar, "RIGHT")
    bar.right:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)
    bar.right:SetColorTexture(COLOR.SliderRight:GetRGBA())

    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(SIZE.SETTING_LINE.SliderSquareHeight, SIZE.SETTING_LINE.SliderSquareHeight)
    thumb:SetColorTexture(COLOR.Base:GetRGBA())
    slider:SetThumbTexture(thumb)
    local thumbBorder = slider:CreateTexture(nil, "BACKGROUND")
    thumbBorder:SetSize(SIZE.SETTING_LINE.SliderSquareHeight + SIZE.MainFrame.Border * 2, SIZE.SETTING_LINE.SliderSquareHeight + SIZE.MainFrame.Border * 2)
    thumbBorder:SetColorTexture(COLOR.ButtonBorder:GetRGBA())
    thumbBorder:SetPoint("CENTER", thumb, "CENTER")

    local valueText = widget:CreateFontString(nil, "OVERLAY")
    valueText:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing, 0)
    valueText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    valueText:SetJustifyH("RIGHT")
    valueText:SetJustifyV("MIDDLE")
    valueText:SetTextColor(COLOR.Text:GetRGBA())

    local function ApplySliderVisual(value)
        local percent = (value - minValue) / (maxValue - minValue)
        local barWidth = bar:GetWidth()
        local filled = percent * barWidth
        bar.left:SetWidth(filled)
        bar.right:SetWidth(barWidth - filled)
        valueText:SetText(FormatStepValue(value, decimals))
    end

    local function SetSliderValue(value)
        slider:SetValue(value)
        ApplySliderVisual(value)
    end

    slider:SetScript("OnValueChanged", function(_, value)
        ApplySliderVisual(value)
    end)
    slider:SetScript("OnMouseUp", function()
        if config then
            config:set_value(slider:GetValue())
        end
    end)

    local initialValue = row_info.default_value
    if config then
        initialValue = config:get_value()
    end
    SetSliderValue(initialValue)

    if config then
        config:register_callback(function(value)
            SetSliderValue(value)
        end)
    end
    return row
end
