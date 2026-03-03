--[[
文件定位：
  DejaVu BadgeCell创建模块，负责带角标语义单元的创建。

输入来源：
  依赖cell_spec中Badge角标象限约定与core/color颜色语义。

输出职责：
  对外提供BadgeCell创建函数，供slots和spec模块调用。

生命周期/调用时机：
  在需要主语义+角标语义的槽位时按需调用。

约束与非目标：
  当前仅保留创建接口边界，不实现角标绘制。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Matrix命名空间存在
addon_table.Matrix = addon_table.Matrix or {}
addon_table.Matrix.BadgeCell = {}

local BadgeCell = addon_table.Matrix.BadgeCell

-- BadgeCell元表
BadgeCell.prototype = {
    width = 4,
    height = 4,
    badge_size = 2,
}

-- 角标位置
BadgeCell.POSITION = {
    TOP_LEFT = 1,
    TOP_RIGHT = 2,
    BOTTOM_LEFT = 3,
    BOTTOM_RIGHT = 4,
}

-- 创建BadgeCell（占位）
function BadgeCell.Create(parent, x, y, main_color)
    -- 后续实现
    -- 返回badge_cell实例
end

-- 设置角标（占位）
function BadgeCell.SetBadge(badge_cell, position, color)
    -- 后续实现
end

-- 清除（占位）
function BadgeCell.Clear(badge_cell)
    -- 后续实现
end
