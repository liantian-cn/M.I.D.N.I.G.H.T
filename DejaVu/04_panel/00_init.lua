--[[
文件定位：
  DejaVu 面板初始化模块，负责建立面板表、颜色表与示例设置行。

功能说明：
  1) 创建 addonTable.Panel 作为面板模块入口
  2) 定义面板使用的颜色表（与 EZPanel 外观一致）
  3) 提供 Rows 容器并写入三个示例设置项

状态：
  waiting_real_test（等待真实测试）
]]
local addonName, addonTable = ... -- 插件名称与共享表

addonTable.Panel = {}             -- 面板模块主表


addonTable.Panel.COLOR = {                                                          -- 面板配色表
    Black           = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),                    -- 纯黑
    WindowBg        = CreateColor(30 / 255, 30 / 255, 30 / 255, 1),                 -- 窗口背景色
    WindowText      = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),                    -- 窗口文字色（备用）
    WindowBorder    = CreateColor(83 / 255, 88 / 255, 91 / 255, 1),                 -- 窗口边框色
    Base            = CreateColor(255 / 255, 255 / 255, 255 / 255, 1),              -- 基础白
    ButtonBorder    = CreateColor(52 / 255, 52 / 255, 52 / 255, 1),                 -- 按钮边框色
    ButtonHighlight = CreateColor(86 / 255, 86 / 255, 86 / 255, 1),                 -- 按钮悬停高亮
    ButtonMouseUp   = CreateColor(43 / 255, 43 / 255, 43 / 255, 1),                 -- 按钮正常底色
    ButtonMouseDown = CreateColor(37 / 255, 37 / 255, 37 / 255, 1),                 -- 按钮按下底色
    SliderLeft      = CreateColor(73 / 255, 179 / 255, 234 / 255, 1),               -- 滑块已填充色
    SliderRight     = CreateColor(159 / 255, 159 / 255, 159 / 255, 1),              -- 滑块未填充色
    RowHover        = CreateColor(50 / 255, 50 / 255, 50 / 255, 1),                 -- 行悬停色
    Text            = CreateColor(230 / 255, 230 / 255, 230 / 255, 1),              -- 文本颜色
    DropdownBg      = CreateColor(34 / 255, 34 / 255, 34 / 255, 1),                 -- 下拉列表背景色
}                                                                                   -- COLOR 结束

addonTable.Panel.Font = "Interface\\Addons\\" .. addonName .. "\\fonts\\DejaVu.ttf" -- 自定义字体路径
addonTable.Panel.Rows = {}                                                          -- 面板行配置容器（在加载期写入，在第二帧构建 UI）
addonTable.Panel.DefaultApplied = {}                                                -- 记录已 set_default 的 key，确保只执行一次

--[[
    面板每行的格式的例子
]]

local Config = addonTable.Config -- 配置对象工厂

local slider_example_config = Config("slider_example_config") -- 滑块配置项
local combo_example_config = Config("combo_example_config") -- 下拉框配置项
local spell_list_example_config = Config("spell_list_example_config") -- 技能列表配置项

local slider_row = { -- 滑块示例行
    type = "slider", -- 设置类型
    key = "slider_example", -- 行标识
    name = "滑块示例", -- 标题文本
    tooltip = "这只是一个例子, 最小值0, 最大值100, 步进5, 默认值20", -- 提示信息
    min_value = 0, -- 最小值
    max_value = 100, -- 最大值
    step = 5, -- 步进
    default_value = 20, -- 默认值
    bind_config = slider_example_config -- 绑定的配置对象
} -- slider_row 结束

local combo_row = { -- 下拉框示例行
    type = "combo", -- 设置类型
    key = "combo_example", -- 行标识
    name = "下拉框例子", -- 标题文本
    tooltip = "这只是一个例子。", -- 提示信息
    default_value = "zhangsan", -- 默认选中值
    options = { -- 选项列表
        { k = "zhangsan", v = "张三" }, -- 选项1
        { k = "lisi", v = "李四" }, -- 选项2
    }, -- options 结束
    bind_config = combo_example_config -- 绑定的配置对象
} -- combo_row 结束

local spell_list_row = { -- 技能列表示例行
    type = "spell_list", -- 设置类型
    key = "spell_list_example", -- 行标识
    name = "技能图标例子", -- 标题文本
    tooltip = "这只是一个例子。 ", -- 提示信息
    default_value = { -- 默认技能集合
        [294929] = true, -- 示例技能1
        [5487] = true, -- 示例技能2
    }, -- default_value 结束
    bind_config = spell_list_example_config -- 绑定的配置对象
} -- spell_list_row 结束

table.insert(addonTable.Panel.Rows, slider_row) -- 写入滑块示例
table.insert(addonTable.Panel.Rows, combo_row) -- 写入下拉框示例
table.insert(addonTable.Panel.Rows, spell_list_row) -- 写入技能列表示例
