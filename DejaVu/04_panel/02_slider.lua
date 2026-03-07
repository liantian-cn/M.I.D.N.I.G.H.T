--[[
文件定位：
  DejaVu 滑块设置项模块，负责在面板上创建滑块控件。

功能说明：
  1) 根据行配置创建滑块 UI（外观对齐 EZPanel）
  2) 绑定 Config：默认值只设一次，交互时写入
  3) Config 外部变更时同步滑块显示

状态：
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ...                         -- 插件名称与共享表
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放计算
local Panel = addonTable.Panel                            -- 面板模块
local COLOR = Panel.COLOR                                 -- 颜色表
local FONT = Panel.Font                                   -- addonTable.Panel.Font -- 自定义字体路径



local scale = 4                                                                                                                                             -- UI 缩放基准

local strFind = string.find                                                                                                                                 -- 字符查找
local strSub = string.sub                                                                                                                                   -- 字符截取
local strFormat = string.format                                                                                                                             -- 字符格式化
local floor = math.floor                                                                                                                                    -- 向下取整

local function GetStepDecimals(step)                                                                                                                        -- 计算步进小数位
    local s = tostring(step)                                                                                                                                -- 转字符串
    local dot = strFind(s, "%.")                                                                                                                            -- 查找小数点
    if not dot then                                                                                                                                         -- 无小数点
        return 0                                                                                                                                            -- 整数步进
    end                                                                                                                                                     -- 小数点判断结束
    local decimals = #s - dot                                                                                                                               -- 小数位数
    while decimals > 0 and strSub(s, -1) == "0" do                                                                                                          -- 去掉末尾0
        s = strSub(s, 1, -2)                                                                                                                                -- 截断
        decimals = decimals - 1                                                                                                                             -- 更新小数位
    end                                                                                                                                                     -- 去零结束
    return decimals                                                                                                                                         -- 返回小数位数
end                                                                                                                                                         -- GetStepDecimals 结束

local function FormatStepValue(value, decimals)                                                                                                             -- 格式化显示值
    if decimals <= 0 then                                                                                                                                   -- 整数显示
        return strFormat("%d", floor(value + 0.5))                                                                                                          -- 四舍五入
    end                                                                                                                                                     -- 整数判断结束
    return strFormat("%." .. decimals .. "f", value)                                                                                                        -- 保留小数
end                                                                                                                                                         -- FormatStepValue 结束

local function ApplyDefaultValue(config, value)                                                                                                             -- 只设一次默认值
    if not config or not config.key then                                                                                                                    -- 配置对象无效
        return                                                                                                                                              -- 直接退出
    end                                                                                                                                                     -- 配置检查结束
    if Panel.DefaultApplied[config.key] then                                                                                                                -- 已设过默认值
        return                                                                                                                                              -- 直接退出
    end                                                                                                                                                     -- 默认值检查结束
    config:set_default(value)                                                                                                                               -- 设默认值
    Panel.DefaultApplied[config.key] = true                                                                                                                 -- 标记已处理
end                                                                                                                                                         -- ApplyDefaultValue 结束

addonTable.Panel.AddSliderRow = function(row_info)                                                                                                          -- 创建滑块行
    local SIZE = Panel.SIZE                                                                                                                                 -- 尺寸表
    local config = row_info.bind_config                                                                                                                     -- 绑定配置
    ApplyDefaultValue(config, row_info.default_value)                                                                                                       -- 只设一次默认值

    local row = Panel.CreateSettingRow(row_info.name, row_info.tooltip)                                                                                     -- 创建行
    if not row then                                                                                                                                         -- 创建失败
        return nil                                                                                                                                          -- 直接返回
    end                                                                                                                                                     -- 行创建检查结束

    local minValue = row_info.min_value                                                                                                                     -- 最小值
    local maxValue = row_info.max_value                                                                                                                     -- 最大值
    local step = row_info.step                                                                                                                              -- 步进
    local decimals = GetStepDecimals(step)                                                                                                                  -- 小数位数

    local widget = CreateFrame("Frame", addonName .. "sliderWidget" .. row:GetName(), row)                                                                  -- 控件容器
    widget:SetPoint("LEFT", row.title, "RIGHT", SIZE.SETTING_LINE.Spacing, 0)                                                                               -- 位置
    widget:SetSize(SIZE.SETTING_LINE.WidgetWidth, SIZE.SETTING_LINE.Height)                                                                                 -- 尺寸
    widget:EnableMouse(true)                                                                                                                                -- 可交互

    widget.bg = widget:CreateTexture(nil, "BACKGROUND")                                                                                                     -- 外边框
    widget.bg:SetAllPoints(widget)                                                                                                                          -- 填满
    widget.bg:SetColorTexture(COLOR.ButtonBorder:GetRGBA())                                                                                                 -- 边框色

    widget.art = widget:CreateTexture(nil, "ARTWORK")                                                                                                       -- 内填充
    widget.art:SetPoint("TOPLEFT", widget, "TOPLEFT", SIZE.BUTTON.Border, -SIZE.BUTTON.Border)                                                              -- 内缩
    widget.art:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -SIZE.BUTTON.Border, SIZE.BUTTON.Border)                                                      -- 内缩
    widget.art:SetColorTexture(COLOR.ButtonMouseUp:GetRGBA())                                                                                               -- 背景色

    local slider = CreateFrame("Slider", addonName .. "slider" .. row:GetName(), widget)                                                                    -- 滑块
    slider:SetPoint("LEFT", widget, "LEFT", SIZE.MainFrame.Spacing, 0)                                                                                      -- 左对齐
    slider:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing * 2 - SIZE.SETTING_LINE.SliderValueWidth, 0)                                          -- 右对齐
    slider:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)                                                                                                     -- 高度
    slider:SetOrientation("HORIZONTAL")                                                                                                                     -- 水平
    slider:SetMinMaxValues(minValue, maxValue)                                                                                                              -- 范围
    slider:SetValueStep(step)                                                                                                                               -- 步进
    slider:SetObeyStepOnDrag(true)                                                                                                                          -- 拖动吸附步进

    local bar = CreateFrame("Frame", addonName .. "sliderBar" .. row:GetName(), widget)                                                                     -- 轨道容器
    bar:SetAllPoints(slider)                                                                                                                                -- 同步滑块区域
    bar.left = bar:CreateTexture(nil, "ARTWORK")                                                                                                            -- 左填充
    bar.left:SetPoint("LEFT", bar, "LEFT")                                                                                                                  -- 左对齐
    bar.left:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)                                                                                                   -- 高度
    bar.left:SetColorTexture(COLOR.SliderLeft:GetRGBA())                                                                                                    -- 颜色
    bar.right = bar:CreateTexture(nil, "ARTWORK")                                                                                                           -- 右填充
    bar.right:SetPoint("RIGHT", bar, "RIGHT")                                                                                                               -- 右对齐
    bar.right:SetHeight(SIZE.SETTING_LINE.SliderBarHeight)                                                                                                  -- 高度
    bar.right:SetColorTexture(COLOR.SliderRight:GetRGBA())                                                                                                  -- 颜色

    local thumb = slider:CreateTexture(nil, "ARTWORK")                                                                                                      -- 滑块方块
    thumb:SetSize(SIZE.SETTING_LINE.SliderSquareHeight, SIZE.SETTING_LINE.SliderSquareHeight)                                                               -- 大小
    thumb:SetColorTexture(COLOR.Base:GetRGBA())                                                                                                             -- 颜色
    slider:SetThumbTexture(thumb)                                                                                                                           -- 绑定方块
    local thumbBorder = slider:CreateTexture(nil, "BACKGROUND")                                                                                             -- 方块边框
    thumbBorder:SetSize(SIZE.SETTING_LINE.SliderSquareHeight + SIZE.MainFrame.Border * 2, SIZE.SETTING_LINE.SliderSquareHeight + SIZE.MainFrame.Border * 2) -- 尺寸
    thumbBorder:SetColorTexture(COLOR.ButtonBorder:GetRGBA())                                                                                               -- 颜色
    thumbBorder:SetPoint("CENTER", thumb, "CENTER")                                                                                                         -- 居中

    local valueText = widget:CreateFontString(nil, "OVERLAY")                                                                                               -- 数值文本
    valueText:SetPoint("RIGHT", widget, "RIGHT", -SIZE.MainFrame.Spacing, 0)                                                                                -- 右对齐
    valueText:SetFont(FONT, GetUIScaleFactor(5 * scale), "")                                                                                                -- 字体
    valueText:SetJustifyH("RIGHT")                                                                                                                          -- 右对齐
    valueText:SetJustifyV("MIDDLE")                                                                                                                         -- 垂直居中
    valueText:SetTextColor(COLOR.Text:GetRGBA())                                                                                                            -- 文字色

    local function ApplySliderVisual(value)                                                                                                                 -- 更新视觉
        local percent = (value - minValue) / (maxValue - minValue)                                                                                          -- 百分比
        local barWidth = bar:GetWidth()                                                                                                                     -- 轨道宽度
        local filled = percent * barWidth                                                                                                                   -- 填充宽度
        bar.left:SetWidth(filled)                                                                                                                           -- 左侧宽度
        bar.right:SetWidth(barWidth - filled)                                                                                                               -- 右侧宽度
        valueText:SetText(FormatStepValue(value, decimals))                                                                                                 -- 显示值
    end                                                                                                                                                     -- ApplySliderVisual 结束

    local function SetSliderValue(value)                                                                                                                    -- 设置数值
        slider:SetValue(value)                                                                                                                              -- 写入滑块
        ApplySliderVisual(value)                                                                                                                            -- 同步视觉
    end                                                                                                                                                     -- SetSliderValue 结束

    slider:SetScript("OnValueChanged", function(_, value)                                                                                                   -- 拖动时更新
        ApplySliderVisual(value)                                                                                                                            -- 更新视觉
    end)                                                                                                                                                    -- 拖动回调结束
    slider:SetScript("OnMouseUp", function()                                                                                                                -- 鼠标抬起时写入配置
        if config then                                                                                                                                      -- 有配置对象
            config:set_value(slider:GetValue())                                                                                                             -- 写入配置
        end                                                                                                                                                 -- 配置判断结束
    end)                                                                                                                                                    -- 鼠标抬起回调结束

    local initialValue = row_info.default_value                                                                                                             -- 默认值
    if config then                                                                                                                                          -- 有配置对象
        initialValue = config:get_value()                                                                                                                   -- 从配置取当前值
    end                                                                                                                                                     -- 配置读取结束
    SetSliderValue(initialValue)                                                                                                                            -- 初始化显示

    if config then                                                                                                                                          -- 绑定外部回调
        config:register_callback(function(value)                                                                                                            -- 配置变更时
            SetSliderValue(value)                                                                                                                           -- 同步滑块
        end)                                                                                                                                                -- 回调注册结束
    end                                                                                                                                                     -- 外部回调结束
    return row                                                                                                                                              -- 返回行
end                                                                                                                                                         -- AddSliderRow 结束
