--[[
文件定位：
  DejaVu 设置面板主框架模块，负责创建面板根框架与通用 UI 工具。

功能说明：
  1) 计算并存储面板 UI 尺寸（与 EZPanel 外观一致）
  2) 提供按钮/边框/行悬停等通用 UI 工具
  3) 创建面板根框架，并为后续设置行提供容器

状态：
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ... -- 插件名称与共享表
local InitUI = addonTable.Event.Func.InitUI -- 初始化 UI 函数列表
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放计算
local COLOR = addonTable.Panel.COLOR -- 面板颜色表

local scale = 4 -- 与 EZPanel 一致的 UI 缩放基准

local SIZE -- 尺寸表（在创建面板时初始化）

local function InitializeSize() -- 初始化尺寸（与 EZPanel 数值一致）
    SIZE = { -- 尺寸表主体
        MainFrame = { -- 主框体尺寸
            Width = GetUIScaleFactor(scale * 120), -- 主框体宽度
            Height = GetUIScaleFactor(scale * 24), -- 主框体高度
            Border = GetUIScaleFactor(1), -- 主框体边框
            Spacing = GetUIScaleFactor(scale * 2), -- 内边距/间距
        }, -- MainFrame 结束
        BUTTON = { -- 按钮尺寸
            Width = GetUIScaleFactor(scale * 27.5), -- 按钮宽度
            Height = GetUIScaleFactor(scale * 9), -- 按钮高度
            Border = GetUIScaleFactor(2), -- 按钮边框
            IconBorder = GetUIScaleFactor(scale * 2), -- 图标边框
        }, -- BUTTON 结束
        SETTING_LINE = { -- 设置行尺寸
            Height = GetUIScaleFactor(scale * 9), -- 行高
            Spacing = GetUIScaleFactor(scale * 2), -- 行间距
            TitleWidth = GetUIScaleFactor(scale * 43), -- 标题宽度
            WidgetWidth = GetUIScaleFactor(scale * 71), -- 控件宽度
            SliderBarHeight = GetUIScaleFactor(scale * 1.5), -- 滑块条高度
            SliderSquareHeight = GetUIScaleFactor(scale * 4.5), -- 滑块方块高度
            SliderValueWidth = GetUIScaleFactor(scale * 12), -- 滑块数值区宽度
        } -- SETTING_LINE 结束
    } -- SIZE 结束
    addonTable.Panel.SIZE = SIZE -- 暴露到面板模块
end -- InitializeSize 结束

local UI = {} -- UI 工具集合
addonTable.Panel.UI = UI -- 挂到面板模块

function UI.ApplyBorderAndFill(frame, borderColor, fillColor, borderSize) -- 边框+填充
    local bg = frame:CreateTexture(nil, "BACKGROUND") -- 边框纹理
    bg:SetAllPoints(frame) -- 贴满父框体
    bg:SetColorTexture(borderColor:GetRGBA()) -- 边框色

    local art = frame:CreateTexture(nil, "ARTWORK") -- 填充纹理
    art:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize) -- 内缩边距
    art:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize) -- 内缩边距
    art:SetColorTexture(fillColor:GetRGBA()) -- 填充色

    return bg, art -- 返回两个纹理
end -- ApplyBorderAndFill 结束

function UI.BindRowHover(row, hoverTexture, title, tooltip) -- 行悬停与提示
    local function OnEnter(self) -- 鼠标进入
        hoverTexture:SetColorTexture(COLOR.RowHover:GetRGBA()) -- 高亮背景
        if tooltip and tooltip ~= "" then -- 有提示则显示
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", SIZE.MainFrame.Spacing, 0) -- 位置
            GameTooltip:SetFrameStrata("TOOLTIP") -- 层级
            GameTooltip:SetFrameLevel(1000) -- 层级
            GameTooltip:SetText(title, 1, 1, 1, 1, true) -- 标题
            GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true) -- 内容
            GameTooltip:Show() -- 显示
        end -- 提示判断结束
    end -- OnEnter 结束

    local function OnLeave() -- 鼠标离开
        hoverTexture:SetColorTexture(0, 0, 0, 0) -- 清除高亮
        if tooltip and tooltip ~= "" then -- 有提示则隐藏
            GameTooltip:Hide() -- 隐藏提示
        end -- 提示判断结束
    end -- OnLeave 结束

    row:SetScript("OnEnter", OnEnter) -- 绑定进入事件
    row:SetScript("OnLeave", OnLeave) -- 绑定离开事件
end -- BindRowHover 结束

function UI.ToggleFrame(frame) -- 显示/隐藏切换
    if frame:IsShown() then -- 如果已显示
        frame:Hide() -- 隐藏
    else -- 否则
        frame:Show() -- 显示
    end -- 显示判断结束
end -- ToggleFrame 结束

function UI.CreateButton(parent, slug, x_pos, y_pos, buttonWidth, buttonHeight, buttonText) -- 标准按钮
    local button = CreateFrame("Button", addonName .. slug, parent) -- 创建按钮
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x_pos, y_pos) -- 定位
    button:SetSize(buttonWidth, buttonHeight) -- 尺寸
    button:EnableMouse(true) -- 可点击

    button.bg = button:CreateTexture(nil, "BACKGROUND") -- 边框
    button.bg:SetAllPoints() -- 填满
    button.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA()) -- 边框色

    button.art = button:CreateTexture(nil, "ARTWORK") -- 填充
    button.art:SetPoint("TOPLEFT", button, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border) -- 内缩
    button.art:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border) -- 内缩
    button.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA()) -- 默认底色

    button.text = button:CreateFontString(nil, "OVERLAY") -- 按钮文字
    button.text:SetPoint("CENTER", button, "CENTER") -- 居中
    button.text:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "") -- 字体
    button.text:SetJustifyH("CENTER") -- 水平居中
    button.text:SetJustifyV("MIDDLE") -- 垂直居中
    button.text:SetTextColor(1, 1, 1) -- 文字颜色
    button.text:SetText(buttonText) -- 文案

    button:SetScript("OnMouseDown", function() -- 按下效果
        button.art:SetColorTexture(COLOR.ButtonMouseDown:GetRGBA()) -- 深色
    end) -- 按下回调结束
    button:SetScript("OnMouseUp", function() -- 抬起效果
        button.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA()) -- 恢复
    end) -- 抬起回调结束
    button:SetScript("OnEnter", function() -- 悬停
        button.bg:SetColorTexture(COLOR.ButtonHighlight:GetRGBA()) -- 高亮边框
    end) -- 悬停回调结束
    button:SetScript("OnLeave", function() -- 离开
        button.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA()) -- 恢复边框
    end) -- 离开回调结束
    return button -- 返回按钮
end -- CreateButton 结束

local function CreateSettingRow(title, tooltip) -- 创建一行设置项
    local panelFrame = addonTable.Panel.Frame -- 面板容器
    if not panelFrame then -- 容器不存在
        return nil -- 直接返回
    end -- 容器判断结束

    if not panelFrame._rowCount then -- 初始化行计数
        panelFrame._rowCount = 0 -- 行计数
        panelFrame._contentHeight = SIZE.MainFrame.Spacing * 2 -- 内容高度
    end -- 行计数初始化结束

    local rowIndex = panelFrame._rowCount -- 当前行索引
    local topOffset = panelFrame._topOffset or 0 -- 额外顶部偏移
    local rowY = -SIZE.MainFrame.Spacing - topOffset - rowIndex * (SIZE.SETTING_LINE.Height + SIZE.SETTING_LINE.Spacing) -- 行 Y

    local row = CreateFrame("Frame", addonName .. "settingRow" .. rowIndex, panelFrame) -- 行框体
    row:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", SIZE.MainFrame.Spacing, rowY) -- 左上
    row:SetPoint("TOPRIGHT", panelFrame, "TOPRIGHT", -SIZE.MainFrame.Spacing, rowY) -- 右上
    row:SetHeight(SIZE.SETTING_LINE.Height) -- 行高
    row:EnableMouse(true) -- 可响应鼠标

    row.bg = row:CreateTexture(nil, "BACKGROUND") -- 行背景
    row.bg:SetAllPoints(row) -- 填满
    row.bg:SetColorTexture(0, 0, 0, 0) -- 默认透明

    row.title = row:CreateFontString(nil, "OVERLAY") -- 标题文本
    row.title:SetPoint("LEFT", row, "LEFT", 0, 0) -- 左对齐
    row.title:SetSize(SIZE.SETTING_LINE.TitleWidth, SIZE.SETTING_LINE.Height) -- 标题区域
    row.title:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "") -- 字体
    row.title:SetJustifyH("LEFT") -- 左对齐
    row.title:SetJustifyV("MIDDLE") -- 垂直居中
    row.title:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色
    row.title:SetText(title) -- 标题

    UI.BindRowHover(row, row.bg, title, tooltip) -- 绑定悬停效果

    panelFrame._rowCount = rowIndex + 1 -- 行数 +1
    panelFrame._contentHeight = SIZE.MainFrame.Spacing * 2 -- 基础高度
        + (panelFrame._topOffset or 0) -- 顶部偏移
        + panelFrame._rowCount * SIZE.SETTING_LINE.Height -- 行高总和
        + math.max(0, panelFrame._rowCount - 1) * SIZE.SETTING_LINE.Spacing -- 行间距
    panelFrame:SetHeight(panelFrame._contentHeight) -- 自适应高度

    return row -- 返回行框体
end -- CreateSettingRow 结束
addonTable.Panel.CreateSettingRow = CreateSettingRow -- 暴露创建行函数

local function CreatePanelFrame() -- 创建面板主框体
    if addonTable.Panel.Frame then -- 已创建则跳过
        return -- 直接退出
    end -- 已创建判断结束

    InitializeSize() -- 初始化尺寸（第二帧时 UI 缩放准确）

    local frame = CreateFrame("Frame", addonName .. "panelFrame", UIParent) -- 主框体
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- 居中
    frame:SetSize(SIZE.MainFrame.Width, SIZE.MainFrame.Height) -- 尺寸
    frame:SetFrameStrata("TOOLTIP") -- 层级
    frame:SetFrameLevel(900) -- 层级
    frame:SetMovable(true) -- 可拖动
    frame:EnableMouse(true) -- 可交互
    frame:RegisterForDrag("LeftButton") -- 左键拖动
    frame:SetClampedToScreen(true) -- 限制屏幕内
    frame:SetScript("OnDragStart", frame.StartMoving) -- 开始拖动
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing) -- 结束拖动
    frame:Show() -- 显示

    frame.bg, frame.art = UI.ApplyBorderAndFill(frame, COLOR.WindowBorder, COLOR.WindowBg, SIZE.MainFrame.Border) -- 边框
    frame._rowCount = 0 -- 行计数
    frame._contentHeight = SIZE.MainFrame.Spacing * 2 -- 内容高度

    addonTable.Panel.Frame = frame -- 保存主框体
end -- CreatePanelFrame 结束

table.insert(InitUI, CreatePanelFrame) -- 第二帧创建面板
