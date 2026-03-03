--[[
文件定位：



状态：
  draft
]]
local addonName, addonTable = ...

addonTable.Panel = {}


addonTable.Panel.COLOR = {
    Black           = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),
    WindowBg        = CreateColor(30 / 255, 30 / 255, 30 / 255, 1),
    WindowText      = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),
    WindowBorder    = CreateColor(83 / 255, 88 / 255, 91 / 255, 1),
    Base            = CreateColor(255 / 255, 255 / 255, 255 / 255, 1),
    ButtonBorder    = CreateColor(52 / 255, 52 / 255, 52 / 255, 1),
    ButtonHighlight = CreateColor(86 / 255, 86 / 255, 86 / 255, 1),
    ButtonMouseUp   = CreateColor(43 / 255, 43 / 255, 43 / 255, 1),
    ButtonMouseDown = CreateColor(37 / 255, 37 / 255, 37 / 255, 1),
    SliderLeft      = CreateColor(73 / 255, 179 / 255, 234 / 255, 1),  -- 滑块左侧填充色
    SliderRight     = CreateColor(159 / 255, 159 / 255, 159 / 255, 1), -- 滑块右侧背景色
    RowHover        = CreateColor(50 / 255, 50 / 255, 50 / 255, 1),
    Text            = CreateColor(230 / 255, 230 / 255, 230 / 255, 1),
    DropdownBg      = CreateColor(34 / 255, 34 / 255, 34 / 255, 1),

}


addonTable.Panel.Rows = {}

--[[
    面板每行的格式的例子
]]

local Config                    = addonTable.Config

local slider_example_config     = Config("slider_example_config")
local combo_example_config      = Config("combo_example_config")
local spell_list_example_config = Config("spell_list_example_config")

local slider_row                = {
    type = "slider",
    key = "slider_example",
    name = "滑块示例",
    tooltip = "这只是一个例子, 最小值0, 最大值100, 步进5, 默认值20",
    min_value = 0,
    max_value = 100,
    step = 5,
    default_value = 20,
    bind_config = slider_example_config
}

local combo_row                 = {
    type = "combo",
    key = "combo_example",
    name = "下拉框例子",
    tooltip = "这只是一个例子。",
    default_value = "zhangsan",
    options = {
        { k = "zhangsan", v = "张三" },
        { k = "lisi", v = "李四" },
    },
    bind_config = combo_example_config
}

local spell_list_row            = {
    type = "spell_list",
    key = "spell_list_example",
    name = "技能图标例子",
    tooltip = "这只是一个例子。 ",
    default_value = {
        [294929] = true,
        [5487] = true,
    },
    bind_config = spell_list_example_config
}

table.insert(addonTable.Panel.Rows, slider_row)
table.insert(addonTable.Panel.Rows, combo_row)
table.insert(addonTable.Panel.Rows, spell_list_row)
