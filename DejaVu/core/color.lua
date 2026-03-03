--[[
文件定位：
  DejaVu 颜色定义模块，承载Cell/MegaCell/BadgeCell的颜色语义映射表。

输入来源：
  由color_palette文档和协议草案中的颜色语义要求共同定义。

输出职责：
  对外提供统一的颜色配置域，供渲染流程读取颜色定义。

生命周期/调用时机：
  在插件初始化早期加载，供所有绘制相关模块共享。

约束与非目标：
  当前仅定义颜色常量，不实现颜色计算和容差策略。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Core命名空间存在
addon_table.Core = addon_table.Core or {}
addon_table.Core.Color = {}

local Color = addon_table.Core.Color

-- 语义颜色定义（RGB 0-255）
Color.Palette = {
    -- 职业色
    WARRIOR = { r = 199, g = 156, b = 110 },
    PALADIN = { r = 245, g = 140, b = 186 },
    HUNTER = { r = 171, g = 212, b = 115 },
    ROGUE = { r = 255, g = 245, b = 105 },
    PRIEST = { r = 255, g = 255, b = 255 },
    DEATHKNIGHT = { r = 196, g = 31, b = 59 },
    SHAMAN = { r = 0, g = 112, b = 222 },
    MAGE = { r = 105, g = 204, b = 240 },
    WARLOCK = { r = 148, g = 130, b = 201 },
    MONK = { r = 0, g = 255, b = 150 },
    DRUID = { r = 255, g = 125, b = 10 },
    DEMONHUNTER = { r = 163, g = 48, b = 201 },
    EVOKER = { r = 51, g = 147, b = 127 },

    -- 状态色
    HEALTH_HIGH = { r = 0, g = 255, b = 0 },
    HEALTH_MEDIUM = { r = 255, g = 255, b = 0 },
    HEALTH_LOW = { r = 255, g = 0, b = 0 },

    -- 资源色
    MANA = { r = 0, g = 0, b = 255 },
    RAGE = { r = 255, g = 0, b = 0 },
    ENERGY = { r = 255, g = 255, b = 0 },
    FOCUS = { r = 255, g = 125, b = 10 },
    RUNIC = { r = 0, g = 255, b = 255 },
}

-- 获取颜色（占位）
function Color.Get(name)
    return Color.Palette[name]
end
