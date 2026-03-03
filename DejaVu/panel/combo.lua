--[[
文件定位：
  DejaVu 下拉选项设置项模块，负责创建下拉菜单控件。

功能说明：
  1) 根据行配置创建下拉框 UI（外观对齐 EZPanel）
  2) 绑定 Config：默认值只设一次，选择后写入
  3) Config 外部变更时同步显示文本

状态：
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ... -- 插件名称与共享表
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放计算
local Panel = addonTable.Panel -- 面板模块
local COLOR = Panel.COLOR -- 颜色表
local UI = Panel.UI -- UI 工具

local scale = 4 -- UI 缩放基准

local function ApplyDefaultValue(config, value) -- 只设一次默认值
    if not config or not config.key then -- 配置对象无效
        return -- 直接退出
    end -- 配置检查结束
    if Panel.DefaultApplied[config.key] then -- 已设过默认值
        return -- 直接退出
    end -- 默认值检查结束
    config:set_default(value) -- 设默认值
    Panel.DefaultApplied[config.key] = true -- 标记已处理
end -- ApplyDefaultValue 结束

local function CreateDropdownControl(row, options, defaultValue, config) -- 创建下拉控件
    if not row then -- 行不存在
        return nil -- 直接返回
    end -- 行检查结束
    local SIZE = Panel.SIZE -- 尺寸表
    local ownerFrame = Panel.Frame or row:GetParent() -- 列表容器

    local widget = CreateFrame("Frame", addonName .. "dropdownWidget" .. row:GetName(), row) -- 控件容器
    widget:SetPoint("LEFT", row.title, "RIGHT", SIZE.SETTING_LINE.Spacing, 0) -- 定位
    widget:SetSize(SIZE.SETTING_LINE.WidgetWidth, SIZE.SETTING_LINE.Height) -- 尺寸
    widget:EnableMouse(true) -- 可交互

    widget.bg = widget:CreateTexture(nil, "BACKGROUND") -- 外边框
    widget.bg:SetAllPoints(widget) -- 填满
    widget.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA()) -- 颜色

    widget.art = widget:CreateTexture(nil, "ARTWORK") -- 内填充
    widget.art:SetPoint("TOPLEFT", widget, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border) -- 内缩
    widget.art:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border) -- 内缩
    widget.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA()) -- 颜色

    local valueText = widget:CreateFontString(nil, "OVERLAY") -- 显示文本
    valueText:SetPoint("LEFT", widget, "LEFT", SIZE.MainFrame.Spacing, 0) -- 左对齐
    valueText:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing, 0) -- 右对齐
    valueText:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "") -- 字体
    valueText:SetJustifyH("LEFT") -- 左对齐
    valueText:SetJustifyV("MIDDLE") -- 垂直居中
    valueText:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色

    local listFrame = CreateFrame("Frame", addonName .. "dropdownList" .. row:GetName(), ownerFrame) -- 列表容器
    listFrame:SetPoint("TOPLEFT", widget, "BOTTOMLEFT", 0, -SIZE.SETTING_LINE.Spacing / 2) -- 位置
    listFrame:SetPoint("TOPRIGHT", widget, "BOTTOMRIGHT", 0, -SIZE.SETTING_LINE.Spacing / 2) -- 位置
    listFrame:SetHeight(#options * SIZE.SETTING_LINE.Height) -- 高度
    listFrame:SetFrameStrata("TOOLTIP") -- 层级
    listFrame:SetFrameLevel(920) -- 层级
    listFrame:Hide() -- 初始隐藏

    listFrame.bg, listFrame.art = UI.ApplyBorderAndFill(listFrame, COLOR.ButtonBorder, COLOR.DropdownBg, SIZE.MainFrame.Border) -- 边框

    local function FindIndexByValue(value) -- 根据 k 查找索引
        for i, option in ipairs(options) do -- 遍历选项
            if option.k == value then -- 命中
                return i -- 返回索引
            end -- 命中判断结束
        end -- 遍历结束
        return nil -- 未找到
    end -- FindIndexByValue 结束

    local function SetDropdownValue(value, fromUser) -- 设置显示与写入
        local index = FindIndexByValue(value) or 1 -- 找索引
        local option = options[index] -- 选项对象
        if not option then -- 无选项
            return -- 直接退出
        end -- 选项检查结束
        valueText:SetText(option.v) -- 显示文本
        if fromUser and config then -- 用户点击且有配置
            config:set_value(option.k) -- 写入配置
        end -- 写入判断结束
    end -- SetDropdownValue 结束

    for i, option in ipairs(options) do -- 渲染每个选项
        local item = CreateFrame("Frame", addonName .. "dropdownItem" .. row:GetName() .. i, listFrame) -- 选项行
        item:SetPoint("TOPLEFT", listFrame, "TOPLEFT", SIZE.MainFrame.Border, -SIZE.MainFrame.Border - (i - 1) * SIZE.SETTING_LINE.Height) -- 定位
        item:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -SIZE.MainFrame.Border, -SIZE.MainFrame.Border - (i - 1) * SIZE.SETTING_LINE.Height) -- 定位
        item:SetHeight(SIZE.SETTING_LINE.Height) -- 行高
        item:EnableMouse(true) -- 可点击

        item.bg = item:CreateTexture(nil, "BACKGROUND") -- 背景
        item.bg:SetAllPoints(item) -- 填满
        item.bg:SetColorTexture(0, 0, 0, 0) -- 默认透明

        item.text = item:CreateFontString(nil, "OVERLAY") -- 文本
        item.text:SetPoint("LEFT", item, "LEFT", SIZE.MainFrame.Spacing, 0) -- 左对齐
        item.text:SetPoint("RIGHT", item, "RIGHT", -SIZE.MainFrame.Spacing, 0) -- 右对齐
        item.text:SetFont("Fonts\\FRIZQT__.TTF", GetUIScaleFactor(5 * scale), "") -- 字体
        item.text:SetJustifyH("LEFT") -- 左对齐
        item.text:SetJustifyV("MIDDLE") -- 垂直居中
        item.text:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色
        item.text:SetText(option.v) -- 选项文本

        item:SetScript("OnEnter", function() -- 悬停
            item.bg:SetColorTexture(COLOR.RowHover:GetRGBA()) -- 高亮
        end) -- 悬停结束
        item:SetScript("OnLeave", function() -- 离开
            item.bg:SetColorTexture(0, 0, 0, 0) -- 还原
        end) -- 离开结束
        item:SetScript("OnMouseDown", function() -- 点击
            SetDropdownValue(option.k, true) -- 设置并写入
            listFrame:Hide() -- 隐藏列表
        end) -- 点击结束
    end -- 选项渲染结束

    local function ToggleList() -- 切换列表显示
        if #options <= 0 then -- 无选项
            return -- 直接退出
        end -- 无选项判断结束
        UI.ToggleFrame(listFrame) -- 切换显示
    end -- ToggleList 结束

    row:SetScript("OnMouseDown", ToggleList) -- 行点击切换
    widget:SetScript("OnMouseDown", ToggleList) -- 控件点击切换

    SetDropdownValue(defaultValue, false) -- 初始化显示
    return widget, SetDropdownValue -- 返回控件与设置函数
end -- CreateDropdownControl 结束

addonTable.Panel.AddComboRow = function(row_info) -- 创建下拉框行
    local config = row_info.bind_config -- 绑定配置
    ApplyDefaultValue(config, row_info.default_value) -- 只设一次默认值

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip) -- 创建行
    if not row then -- 创建失败
        return nil -- 直接返回
    end -- 行创建检查结束

    local _, setValue = CreateDropdownControl(row, row_info.options, row_info.default_value, config) -- 创建控件
    if config then -- 绑定配置
        setValue(config:get_value(), false) -- 同步当前值
        config:register_callback(function(value) -- 配置变化回调
            setValue(value, false) -- 同步显示
        end) -- 回调注册结束
    end -- 配置绑定结束
    return row -- 返回行
end -- AddComboRow 结束
