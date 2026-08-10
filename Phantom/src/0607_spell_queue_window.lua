-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local Config = addonTable.Config
local ConfigRows = addonTable.ConfigRows

-- 本地变量定义
local insert = table.insert
local print = print

-- 代码部分

--[[
摘要：      输出独立延迟窗口配置
分类：      环境信息
分类索引：  7
位置：      5行45列

描述：
注册“延迟窗口”滑块配置，允许在 250 至 550 毫秒之间按 10 毫秒步进调整，默认值为 400 毫秒。
配置变化时打印当前值，并通过独立回调刷新 Cell；Cell 将毫秒值除以 10 后编码到 B 通道。

主要变量信息：
- DEFAULT_CONFIG_VALUE：延迟窗口默认值，单位为毫秒。
- spellQueueWindow：保存延迟窗口数值并分发变更回调的配置对象。
- cell：环境信息分类第 7 个 Cell，位于第 5 行第 45 列。

修改记录：
- 2026-07-26：根据本次补充注释需求补充文件说明、配置、回调与 Cell 编码注释。
]]

-- 分类、Cell 位置与配置默认值定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 7
local CELL_POSITION_X = 45
local CELL_POSITION_Y = 5
local DEFAULT_CONFIG_VALUE = 400

local spellQueueWindow = Config("spell_queue_window")
spellQueueWindow:set_default(DEFAULT_CONFIG_VALUE)

-- 配置面板使用滑块编辑毫秒值，并与配置对象双向绑定。
insert(ConfigRows, {
    type = "slider",
    key = "spell_queue_window",
    name = "延迟窗口",
    tooltip = "延迟窗口的时间, 单位ms, 这个值越小, 按键越晚",
    min_value = 250,
    max_value = 550,
    step = 10,
    default_value = DEFAULT_CONFIG_VALUE,
    bind_config = spellQueueWindow,
})

local function printSpellQueueWindow(value)
    print("延迟窗口设置为：" .. value)
end

spellQueueWindow:register_callback(printSpellQueueWindow)

local function InitFrame()
    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_CONFIG_VALUE / 10,
    })

    -- R、G 通道标识环境信息分类及索引，B 通道保存毫秒值除以 10 后的编码。
    local function updateSpellQueueWindow(value)
        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            (value / 10) / 255
        )
    end

    -- 配置变化时刷新 Cell，初始化时也读取当前配置写入一次。
    spellQueueWindow:register_callback(updateSpellQueueWindow)
    updateSpellQueueWindow(spellQueueWindow:get_value())
end

insert(addonTable.FrameInitFuncs, InitFrame)
