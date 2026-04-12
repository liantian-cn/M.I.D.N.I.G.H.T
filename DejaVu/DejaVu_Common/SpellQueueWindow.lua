local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local insert = table.insert
local After = C_Timer.After
local random = math.random

-- WoW 官方 API

local DejaVu = _G["DejaVu"]
local Config = DejaVu.Config
local ConfigRows = DejaVu.ConfigRows
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell

local spell_queue_window = Config("spell_queue_window") -- 滑块配置项

insert(ConfigRows, {
    type = "slider", -- 设置类型
    key = "spell_queue_window", -- 行标识
    name = "延迟窗口", -- 标题文本
    tooltip = "延迟窗口的时间, 单位ms, 这个值越小, 按键越晚", -- 提示信息
    min_value = 200, -- 最小值
    max_value = 400, -- 最大值
    step = 10, -- 步进
    default_value = 300, -- 默认值
    bind_config = spell_queue_window, -- 绑定的配置对象
})



local function spell_queue_window_updater(value)
    print("延迟窗口设置为：" .. value)
end
spell_queue_window:register_callback(spell_queue_window_updater)


After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local cell = Cell:New(57, 9)
    cell:setCellRGBA(20 / 255)
    local function Updater(value)
        local mean = (value / 10) / 255
        -- print(mean)
        cell:setCellRGBA(mean)
    end
    spell_queue_window:register_callback(Updater)
end)
