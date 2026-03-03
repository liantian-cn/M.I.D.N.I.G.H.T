--[[
文件定位：
  DejaVu 设置面板主框架模块，负责创建panelFrame容器。


状态：
  draft
]]

local addonName, addonTable = ...
local InitUI = addonTable.Event.Func.InitUI
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local COLOR = addonTable.Panel.COLOR

local scale = 4

local SIZE

local function InitializeSize()
    SIZE = {
        MainFrame = {
            Width = GetUIScaleFactor(scale * 120),
            Height = GetUIScaleFactor(scale * 24),
            Border = GetUIScaleFactor(1),
            Spacing = GetUIScaleFactor(scale * 2),
        },
        BUTTON = {
            Width = GetUIScaleFactor(scale * 27.5),
            Height = GetUIScaleFactor(scale * 9),
            Border = GetUIScaleFactor(2),
            IconBorder = GetUIScaleFactor(scale * 2),
        },
        SETTING_LINE = {
            Height = GetUIScaleFactor(scale * 9),
            Spacing = GetUIScaleFactor(scale * 2),
            TitleWidth = GetUIScaleFactor(scale * 43),
            WidgetWidth = GetUIScaleFactor(scale * 71),
            SliderBarHeight = GetUIScaleFactor(scale * 1.5),
            SliderSquareHeight = GetUIScaleFactor(scale * 4.5),
            SliderValueWidth = GetUIScaleFactor(scale * 12),
        }
    }
    addonTable.Panel.SIZE = SIZE
end

local UI = {}
addonTable.Panel.UI = UI

function UI.ApplyBorderAndFill(frame, borderColor, fillColor, borderSize)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(borderColor:GetRGBA())

    local art = frame:CreateTexture(nil, "ARTWORK")
    art:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    art:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
    art:SetColorTexture(fillColor:GetRGBA())

    return bg, art
end

function UI.BindRowHover(row, hoverTexture, title, tooltip)
    local function OnEnter(self)
        hoverTexture:SetColorTexture(COLOR.RowHover:GetRGBA())
        if tooltip and tooltip ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", SIZE.MainFrame.Spacing, 0)
            GameTooltip:SetFrameStrata("TOOLTIP")
            GameTooltip:SetFrameLevel(1000)
            GameTooltip:SetText(title, 1, 1, 1, 1, true)
            GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end

    local function OnLeave()
        hoverTexture:SetColorTexture(0, 0, 0, 0)
        if tooltip and tooltip ~= "" then
            GameTooltip:Hide()
        end
    end

    row:SetScript("OnEnter", OnEnter)
    row:SetScript("OnLeave", OnLeave)
end

function UI.ToggleFrame(frame)
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function UI.CreateButton(parent, slug, x_pos, y_pos, buttonWidth, buttonHeight, buttonText)
    local button = CreateFrame("Button", addonName .. slug, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x_pos, y_pos)
    button:SetSize(buttonWidth, buttonHeight)
    button:EnableMouse(true)

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA())

    button.art = button:CreateTexture(nil, "ARTWORK")
    button.art:SetPoint("TOPLEFT", button, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border)
    button.art:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border)
    button.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA())

    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetPoint("CENTER", button, "CENTER")
    button.text:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    button.text:SetJustifyH("CENTER")
    button.text:SetJustifyV("MIDDLE")
    button.text:SetTextColor(1, 1, 1)
    button.text:SetText(buttonText)

    button:SetScript("OnMouseDown", function()
        button.art:SetColorTexture(COLOR.ButtonMouseDown:GetRGBA())
    end)
    button:SetScript("OnMouseUp", function()
        button.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA())
    end)
    button:SetScript("OnEnter", function()
        button.bg:SetColorTexture(COLOR.ButtonHighlight:GetRGBA())
    end)
    button:SetScript("OnLeave", function()
        button.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA())
    end)
    return button
end

local function CreateSettingRow(title, tooltip)
    local panelFrame = addonTable.Panel.Frame
    if not panelFrame then
        return nil
    end

    if not panelFrame._rowCount then
        panelFrame._rowCount = 0
        panelFrame._contentHeight = SIZE.MainFrame.Spacing * 2
    end

    local rowIndex = panelFrame._rowCount
    local topOffset = panelFrame._topOffset or 0
    local rowY = -SIZE.MainFrame.Spacing - topOffset - rowIndex * (SIZE.SETTING_LINE.Height + SIZE.SETTING_LINE.Spacing)

    local row = CreateFrame("Frame", addonName .. "settingRow" .. rowIndex, panelFrame)
    row:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", SIZE.MainFrame.Spacing, rowY)
    row:SetPoint("TOPRIGHT", panelFrame, "TOPRIGHT", -SIZE.MainFrame.Spacing, rowY)
    row:SetHeight(SIZE.SETTING_LINE.Height)
    row:EnableMouse(true)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetColorTexture(0, 0, 0, 0)

    row.title = row:CreateFontString(nil, "OVERLAY")
    row.title:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.title:SetSize(SIZE.SETTING_LINE.TitleWidth, SIZE.SETTING_LINE.Height)
    row.title:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "")
    row.title:SetJustifyH("LEFT")
    row.title:SetJustifyV("MIDDLE")
    row.title:SetTextColor(COLOR.Text:GetRGBA())
    row.title:SetText(title)

    UI.BindRowHover(row, row.bg, title, tooltip)

    panelFrame._rowCount = rowIndex + 1
    panelFrame._contentHeight = SIZE.MainFrame.Spacing * 2
        + (panelFrame._topOffset or 0)
        + panelFrame._rowCount * SIZE.SETTING_LINE.Height
        + math.max(0, panelFrame._rowCount - 1) * SIZE.SETTING_LINE.Spacing
    panelFrame:SetHeight(panelFrame._contentHeight)

    return row
end
addonTable.Panel.CreateSettingRow = CreateSettingRow

local function CreatePanelFrame()
    if addonTable.Panel.Frame then
        return
    end

    InitializeSize()

    local frame = CreateFrame("Frame", addonName .. "panelFrame", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(SIZE.MainFrame.Width, SIZE.MainFrame.Height)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(900)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Show()

    frame.bg, frame.art = UI.ApplyBorderAndFill(frame, COLOR.WindowBorder, COLOR.WindowBg, SIZE.MainFrame.Border)
    frame._rowCount = 0
    frame._contentHeight = SIZE.MainFrame.Spacing * 2

    addonTable.Panel.Frame = frame
end

table.insert(InitUI, CreatePanelFrame)
