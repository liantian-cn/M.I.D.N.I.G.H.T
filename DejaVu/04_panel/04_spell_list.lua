--[[
文件定位：
  DejaVu 技能选项设置项模块，负责创建技能列表控件与编辑器。

功能说明：
  1) 创建“技能列表”设置行与编辑按钮（外观对齐 EZPanel）
  2) 提供技能编辑器面板（输入框、列表、滚动、悬停提示）
  3) 绑定 Config：默认值只设一次，新增/删除时写入

状态：
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ... -- 插件名称与共享表
local GetSpellName = C_Spell.GetSpellName -- 获取技能名
local GetSpellTexture = C_Spell.GetSpellTexture -- 获取技能图标
local GetSpellDescription = C_Spell.GetSpellDescription -- 获取技能描述

local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放
local Panel = addonTable.Panel -- 面板模块
local COLOR = Panel.COLOR -- 颜色表
local FONT = Panel.Font -- addonTable.Panel.Font -- 自定义字体路径
local UI = Panel.UI -- UI 工具

local floor = math.floor -- 向下取整
local insert = table.insert -- 数组插入

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

local function NormalizeSpellID(value) -- 规范化 SpellID
    local numberValue = tonumber(value) -- 转数字
    if not numberValue then -- 非数字
        return nil -- 直接返回
    end -- 数字判断结束
    numberValue = floor(numberValue) -- 取整
    if numberValue <= 0 then -- 只接受正数
        return nil -- 直接返回
    end -- 正数判断结束
    return numberValue -- 返回规范化 ID
end -- NormalizeSpellID 结束

local function CopySpellList(source) -- 复制技能表
    local copy = {} -- 新表
    if type(source) ~= "table" then -- 非表直接返回空
        return copy -- 返回空表
    end -- 类型判断结束
    for rawSpellID, enabled in pairs(source) do -- 遍历源表
        if enabled then -- 只复制 true 项
            local spellID = NormalizeSpellID(rawSpellID) -- 规范化
            if spellID then -- 有效则写入
                copy[spellID] = true -- 写入新表
            end -- 有效判断结束
        end -- enabled 判断结束
    end -- 遍历结束
    return copy -- 返回新表
end -- CopySpellList 结束

local function CollectSpellIDs(spellList) -- 收集技能 ID 数组
    local spellIDs = {} -- ID 数组
    if type(spellList) ~= "table" then -- 非表返回空
        return spellIDs -- 返回空数组
    end -- 类型判断结束
    for rawSpellID, enabled in pairs(spellList) do -- 遍历表
        if enabled then -- 只保留 true
            local spellID = NormalizeSpellID(rawSpellID) -- 规范化
            if spellID then -- 有效则插入
                insert(spellIDs, spellID) -- 写入数组
            end -- 有效判断结束
        end -- enabled 判断结束
    end -- 遍历结束
    return spellIDs -- 返回数组
end -- CollectSpellIDs 结束

local function EnsureSpellListEditorFrame() -- 确保编辑器存在
    if Panel.SpellListEditorFrame then -- 已创建
        return Panel.SpellListEditorFrame -- 直接返回
    end -- 已创建判断结束
    if not Panel.Frame then -- 主面板未创建
        return nil -- 直接返回
    end -- 主面板判断结束

    local SIZE = Panel.SIZE -- 尺寸表
    local scale = 4 -- UI 缩放基准
    local maxRows = 15 -- 列表最大行数
    local lineHeight = SIZE.SETTING_LINE.Height -- 行高
    local panelWidth = GetUIScaleFactor(scale * 120) -- 编辑器宽度
    local panelHeight = GetUIScaleFactor(scale * 152) + lineHeight -- 编辑器高度
    local spacing = SIZE.MainFrame.Spacing -- 间距
    local border = SIZE.MainFrame.Border -- 边框
    local iconFallback = 61304 -- 备用图标

    local frame = CreateFrame("Frame", addonName .. "spellListEditorFrame", UIParent) -- 编辑器框体
    frame:SetPoint("TOPLEFT", Panel.Frame, "TOPRIGHT", 0, 0) -- 放在主面板右侧
    frame:SetSize(panelWidth, panelHeight) -- 尺寸
    frame:SetFrameStrata("TOOLTIP") -- 层级
    frame:SetFrameLevel(905) -- 层级
    frame:Hide() -- 默认隐藏

    frame.bg, frame.art = UI.ApplyBorderAndFill(frame, COLOR.WindowBorder, COLOR.WindowBg, SIZE.MainFrame.Border) -- 边框

    local contentWidth = panelWidth - spacing * 2 -- 内容区宽度
    local actionButtonWidth = GetUIScaleFactor(scale * 16) -- 按钮宽度
    local actionGap = spacing -- 按钮间距
    local inputWidth = contentWidth - actionButtonWidth * 2 - actionGap * 2 -- 输入框宽度
    local addButtonX = spacing -- 新增按钮 X
    local deleteButtonX = addButtonX + actionButtonWidth + actionGap -- 删除按钮 X
    local inputX = deleteButtonX + actionButtonWidth + actionGap -- 输入框 X
    local inputRowY = -(spacing * 2 + lineHeight) -- 输入行 Y
    local listTopY = -(spacing * 3 + lineHeight * 2) -- 列表顶部 Y

    frame.titleText = frame:CreateFontString(nil, "OVERLAY") -- 标题文本
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", spacing, -spacing) -- 定位
    frame.titleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -spacing, -spacing) -- 定位
    frame.titleText:SetHeight(lineHeight) -- 高度
    frame.titleText:SetFont(FONT, GetUIScaleFactor(5 * scale), "") -- 字体
    frame.titleText:SetJustifyH("CENTER") -- 水平居中
    frame.titleText:SetJustifyV("MIDDLE") -- 垂直居中
    frame.titleText:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色
    frame.titleText:SetText("法术列表") -- 文案

    frame.spellIDBox = CreateFrame("EditBox", addonName .. "spellListInputBox", frame) -- 输入框
    frame.spellIDBox:SetPoint("TOPLEFT", frame, "TOPLEFT", inputX, inputRowY) -- 定位
    frame.spellIDBox:SetSize(inputWidth, lineHeight) -- 尺寸
    frame.spellIDBox:SetFont(FONT, GetUIScaleFactor(5 * scale), "") -- 字体
    frame.spellIDBox:SetJustifyH("LEFT") -- 左对齐
    frame.spellIDBox:SetJustifyV("MIDDLE") -- 垂直居中
    frame.spellIDBox:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色
    frame.spellIDBox:SetAutoFocus(false) -- 不自动聚焦
    frame.spellIDBox:SetMultiLine(false) -- 单行
    frame.spellIDBox:SetTextInsets(spacing, spacing, 0, 0) -- 内边距

    frame.spellIDBox.bg = frame.spellIDBox:CreateTexture(nil, "BACKGROUND") -- 输入框边框
    frame.spellIDBox.bg:SetAllPoints(frame.spellIDBox) -- 填满
    frame.spellIDBox.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA()) -- 边框色

    frame.spellIDBox.art = frame.spellIDBox:CreateTexture(nil, "ARTWORK") -- 输入框填充
    frame.spellIDBox.art:SetPoint("TOPLEFT", frame.spellIDBox, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border) -- 内缩
    frame.spellIDBox.art:SetPoint("BOTTOMRIGHT", frame.spellIDBox, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border) -- 内缩
    frame.spellIDBox.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA()) -- 填充色

    frame.spellIDBox:SetScript("OnEnterPressed", function(self) -- 回车取消焦点
        self:ClearFocus() -- 清理焦点
    end) -- 回车回调结束
    frame.spellIDBox:SetScript("OnEscapePressed", function(self) -- ESC 取消焦点
        self:ClearFocus() -- 清理焦点
    end) -- ESC 回调结束

    frame.addButton = UI.CreateButton(frame, "spellListAddButton", addButtonX, inputRowY, actionButtonWidth, SIZE.BUTTON.Height, "新增") -- 新增按钮
    frame.deleteButton = UI.CreateButton(frame, "spellListDeleteButton", deleteButtonX, inputRowY, actionButtonWidth, SIZE.BUTTON.Height, "删除") -- 删除按钮

    frame.listFrame = CreateFrame("Frame", addonName .. "spellListListFrame", frame) -- 列表容器
    frame.listFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", spacing, listTopY) -- 定位
    frame.listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -spacing, spacing) -- 定位
    frame.listFrame:EnableMouseWheel(true) -- 支持滚轮
    frame.listFrame.bg, frame.listFrame.art = UI.ApplyBorderAndFill(frame.listFrame, COLOR.ButtonBorder, COLOR.DropdownBg, border) -- 边框

    frame.emptyText = frame.listFrame:CreateFontString(nil, "OVERLAY") -- 空文本
    frame.emptyText:SetPoint("CENTER", frame.listFrame, "CENTER") -- 居中
    frame.emptyText:SetFont(FONT, GetUIScaleFactor(5 * scale), "") -- 字体
    frame.emptyText:SetJustifyH("CENTER") -- 居中
    frame.emptyText:SetJustifyV("MIDDLE") -- 居中
    frame.emptyText:SetTextColor(0.65, 0.65, 0.65) -- 文字色
    frame.emptyText:SetText("暂无数据") -- 文案
    frame.emptyText:Hide() -- 默认隐藏

    frame.rows = {} -- 行数组
    for i = 1, maxRows do -- 创建固定行
        local row = CreateFrame("Frame", addonName .. "spellListRow" .. i, frame.listFrame) -- 行框体
        row:SetPoint("TOPLEFT", frame.listFrame, "TOPLEFT", border, -border - (i - 1) * lineHeight) -- 定位
        row:SetPoint("TOPRIGHT", frame.listFrame, "TOPRIGHT", -border, -border - (i - 1) * lineHeight) -- 定位
        row:SetHeight(lineHeight) -- 行高
        row:EnableMouse(true) -- 可交互
        row:EnableMouseWheel(true) -- 支持滚轮

        row.bg = row:CreateTexture(nil, "BACKGROUND") -- 行背景
        row.bg:SetAllPoints(row) -- 填满
        row.bg:SetColorTexture(0, 0, 0, 0) -- 默认透明

        row.icon = row:CreateTexture(nil, "ARTWORK") -- 图标
        row.icon:SetPoint("LEFT", row, "LEFT", spacing, 0) -- 定位
        row.icon:SetSize(lineHeight - border * 2, lineHeight - border * 2) -- 尺寸
        row.icon:SetTexture(iconFallback) -- 默认图标

        row.idText = row:CreateFontString(nil, "OVERLAY") -- ID 文本
        row.idText:SetPoint("RIGHT", row, "RIGHT", -spacing, 0) -- 右对齐
        row.idText:SetFont(FONT, GetUIScaleFactor(4.5 * scale), "") -- 字体
        row.idText:SetJustifyH("RIGHT") -- 右对齐
        row.idText:SetJustifyV("MIDDLE") -- 垂直居中
        row.idText:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色

        row.nameText = row:CreateFontString(nil, "OVERLAY") -- 名称文本
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", spacing, 0) -- 左对齐
        row.nameText:SetPoint("RIGHT", row.idText, "LEFT", -spacing, 0) -- 右对齐
        row.nameText:SetFont(FONT, GetUIScaleFactor(5 * scale), "") -- 字体
        row.nameText:SetJustifyH("LEFT") -- 左对齐
        row.nameText:SetJustifyV("MIDDLE") -- 垂直居中
        row.nameText:SetTextColor(COLOR.Text:GetRGBA()) -- 文字色

        frame.rows[i] = row -- 保存行
    end -- 行创建结束

    function frame:_ClampScrollOffset() -- 约束滚动偏移
        local total = self._spellIDs and #self._spellIDs or 0 -- 总数
        local maxOffset = math.max(0, total - maxRows) -- 最大偏移
        if not self._scrollOffset then -- 未设置
            self._scrollOffset = 0 -- 初始化
        end -- 未设置判断结束
        if self._scrollOffset < 0 then -- 下界
            self._scrollOffset = 0 -- 修正
        elseif self._scrollOffset > maxOffset then -- 上界
            self._scrollOffset = maxOffset -- 修正
        end -- 边界判断结束
    end -- _ClampScrollOffset 结束

    function frame:_SetRowVisual(row) -- 更新行高亮
        if row._spellID and self._selectedSpellID == row._spellID then -- 选中行
            row.bg:SetColorTexture(73 / 255, 179 / 255, 234 / 255, 0.35) -- 选中高亮
            return -- 结束
        end -- 选中判断结束
        if row._hovered then -- 悬停行
            row.bg:SetColorTexture(COLOR.RowHover:GetRGBA()) -- 悬停高亮
            return -- 结束
        end -- 悬停判断结束
        row.bg:SetColorTexture(0, 0, 0, 0) -- 默认背景
    end -- _SetRowVisual 结束

    function frame:RefreshList() -- 刷新列表
        self._spellIDs = CollectSpellIDs(self._currentData) -- 生成 ID 列表
        self:_ClampScrollOffset() -- 修正滚动
        if #self._spellIDs == 0 then -- 空列表
            self.emptyText:Show() -- 显示空提示
        else -- 非空列表
            self.emptyText:Hide() -- 隐藏空提示
        end -- 空列表判断结束

        for index, row in ipairs(self.rows) do -- 填充行
            local listIndex = (self._scrollOffset or 0) + index -- 计算真实索引
            local spellID = self._spellIDs[listIndex] -- 当前 ID

            row._spellID = spellID -- 绑定 ID
            row._hovered = false -- 重置悬停
            if spellID then -- 有 ID
                local spellName = GetSpellName(spellID) or "" -- 名称
                local iconID = GetSpellTexture(spellID) or iconFallback -- 图标
                row.icon:SetTexture(iconID) -- 设置图标
                row.nameText:SetText(spellName) -- 设置名称
                row.idText:SetText(tostring(spellID)) -- 设置 ID
                row:Show() -- 显示
            else -- 无 ID
                row.icon:SetTexture(iconFallback) -- 默认图标
                row.nameText:SetText("") -- 清空名称
                row.idText:SetText("") -- 清空 ID
                row:Hide() -- 隐藏
            end -- 是否有 ID 判断结束
            self:_SetRowVisual(row) -- 更新高亮
        end -- 行遍历结束
    end -- RefreshList 结束

    function frame:BindSetting(setting) -- 绑定设置项
        self._currentSetting = setting -- 当前设置项
        if self.titleText then -- 更新标题
            local title = "法术列表" -- 默认标题
            if type(setting) == "table" then -- 有设置对象
                title = tostring(setting.name or setting.key or title) -- 标题取设置名
            end -- 设置对象判断结束
            self.titleText:SetText(title) -- 设置标题
        end -- 标题更新结束
        if type(setting) ~= "table" or not setting.bind_config then -- 无配置
            self._currentData = {} -- 空数据
        else -- 有配置
            self._currentData = CopySpellList(setting.bind_config:get_value()) -- 读取配置并复制
        end -- 配置判断结束
        self._selectedSpellID = nil -- 清空选中
        self._scrollOffset = 0 -- 归零滚动
        self.spellIDBox:SetText("") -- 清空输入
        self:RefreshList() -- 刷新显示
    end -- BindSetting 结束

    function frame:PersistCurrentValue() -- 写入当前数据
        if type(self._currentSetting) ~= "table" then -- 无设置对象
            return -- 直接退出
        end -- 设置对象判断结束
        local config = self._currentSetting.bind_config -- 取配置
        if not config then -- 无配置
            return -- 直接退出
        end -- 配置判断结束
        config:set_value(CopySpellList(self._currentData)) -- 写入配置
        self._currentData = CopySpellList(config:get_value()) -- 重新读取
    end -- PersistCurrentValue 结束

    local function GetInputSpellID() -- 读取输入框
        local text = frame.spellIDBox:GetText() or "" -- 取文本
        text = text:gsub("%s+", "") -- 去空格
        return NormalizeSpellID(text) -- 规范化
    end -- GetInputSpellID 结束

    frame.addButton:HookScript("OnMouseUp", function() -- 新增按钮
        if type(frame._currentSetting) ~= "table" then -- 无设置
            return -- 直接退出
        end -- 设置判断结束

        local spellID = GetInputSpellID() -- 取输入
        if not spellID then -- 无效输入
            return -- 直接退出
        end -- 输入判断结束

        frame._currentData[spellID] = true -- 写入
        frame._selectedSpellID = spellID -- 选中
        frame.spellIDBox:SetText(tostring(spellID)) -- 回写输入框
        frame:PersistCurrentValue() -- 写入配置
        frame:RefreshList() -- 刷新
    end) -- 新增回调结束

    frame.deleteButton:HookScript("OnMouseUp", function() -- 删除按钮
        if type(frame._currentSetting) ~= "table" then -- 无设置
            return -- 直接退出
        end -- 设置判断结束

        local spellID = GetInputSpellID() -- 取输入
        if not spellID then -- 无效输入
            return -- 直接退出
        end -- 输入判断结束

        frame._currentData[spellID] = nil -- 删除
        if frame._selectedSpellID == spellID then -- 清除选中
            frame._selectedSpellID = nil -- 清空
        end -- 选中判断结束
        frame:PersistCurrentValue() -- 写入配置
        frame:RefreshList() -- 刷新
    end) -- 删除回调结束

    frame.listFrame:SetScript("OnMouseWheel", function(listFrame, delta) -- 列表滚轮
        local editorFrame = listFrame:GetParent()
        if delta > 0 then -- 上滚
            editorFrame._scrollOffset = (editorFrame._scrollOffset or 0) - 1 -- 向上
        else -- 下滚
            editorFrame._scrollOffset = (editorFrame._scrollOffset or 0) + 1 -- 向下
        end -- 滚动方向判断结束
        editorFrame:_ClampScrollOffset() -- 修正
        editorFrame:RefreshList() -- 刷新
    end) -- 滚轮回调结束

    for rowIndex = 1, #frame.rows do -- 行交互
        local row = frame.rows[rowIndex]
        row:SetScript("OnMouseDown", function(self) -- 点击选择
            if not self._spellID then -- 无 ID
                return -- 直接退出
            end -- ID 判断结束
            frame._selectedSpellID = self._spellID -- 选中
            frame.spellIDBox:SetText(tostring(self._spellID)) -- 回写输入框
            frame:RefreshList() -- 刷新
        end) -- 点击回调结束
        row:SetScript("OnEnter", function(self) -- 悬停提示
            if not self._spellID then -- 无 ID
                return -- 直接退出
            end -- ID 判断结束
            self._hovered = true -- 标记悬停
            frame:_SetRowVisual(self) -- 更新高亮

            local spellID = self._spellID -- 当前 ID
            local spellName = GetSpellName(spellID) or "未知技能" -- 名称
            local description = GetSpellDescription(spellID) -- 描述
            if not description or description == "" then -- 无描述
                description = "无描述" -- 兜底描述
            end -- 描述判断结束

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", spacing, 0) -- 提示位置
            GameTooltip:SetFrameStrata("TOOLTIP") -- 层级
            GameTooltip:SetFrameLevel(1000) -- 层级
            GameTooltip:SetText("SpellID: " .. tostring(spellID), 1, 1, 1, 1, true) -- 标题
            GameTooltip:AddLine(spellName, 0.9, 0.9, 0.9, true) -- 名称
            GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true) -- 描述
            GameTooltip:Show() -- 显示
        end) -- 悬停回调结束
        row:SetScript("OnLeave", function(self) -- 离开提示
            self._hovered = false -- 清除悬停
            frame:_SetRowVisual(self) -- 更新
            GameTooltip:Hide() -- 隐藏
        end) -- 离开回调结束
        row:SetScript("OnMouseWheel", function(rowFrame, delta) -- 行滚轮
            local listMouseWheelScript = frame.listFrame:GetScript("OnMouseWheel")
            if listMouseWheelScript then -- 代理到列表
                listMouseWheelScript(rowFrame:GetParent(), delta) -- 调用列表滚轮
            end -- 代理判断结束
        end) -- 行滚轮回调结束
    end -- 行遍历结束

    Panel.SpellListEditorFrame = frame -- 保存编辑器
    return frame -- 返回编辑器
end -- EnsureSpellListEditorFrame 结束

addonTable.Panel.AddSpellListRow = function(row_info) -- 创建技能列表行
    local SIZE = Panel.SIZE -- 尺寸表
    local config = row_info.bind_config -- 绑定配置
    ApplyDefaultValue(config, row_info.default_value) -- 只设一次默认值

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip) -- 创建行
    if not row then -- 创建失败
        return nil -- 直接返回
    end -- 行创建判断结束

    local buttonX = SIZE.SETTING_LINE.TitleWidth + SIZE.SETTING_LINE.Spacing -- 按钮 X
    local buttonWidth = SIZE.SETTING_LINE.WidgetWidth -- 按钮宽度
    local button = UI.CreateButton(row, "spellListSettingButton" .. row:GetName(), buttonX, 0, buttonWidth, SIZE.BUTTON.Height, "编辑") -- 编辑按钮
    button:HookScript("OnMouseUp", function() -- 点击打开/关闭
        local editor = EnsureSpellListEditorFrame() -- 获取编辑器
        if not editor then -- 无编辑器
            return -- 直接退出
        end -- 编辑器判断结束
        if editor:IsShown() and editor._currentSetting == row_info then -- 已打开且同一项
            editor:Hide() -- 关闭
            return -- 直接退出
        end -- 同一项判断结束
        editor:Show() -- 打开
        editor:BindSetting(row_info) -- 绑定设置项
    end) -- 点击回调结束

    return row -- 返回行
end -- AddSpellListRow 结束
