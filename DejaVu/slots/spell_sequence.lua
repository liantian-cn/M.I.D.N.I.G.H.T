--[[
文件定位：
  DejaVu 施法序列Cell组配置模块，定义施法技能相关的Cell布局。

输入来源：
  来自技能系统与矩阵渲染需求。

输出职责：
  定义施法序列Cell组的布局配置，调用Matrix.Cell/MegaCell创建方法。

生命周期/调用时机：
  在插件初始化时注册，在施法事件触发时更新。

约束与非目标：
  当前仅保留配置结构，不实现自动化逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- Slots模块命名空间
addon_table.Slots = addon_table.Slots or {}
addon_table.Slots.SpellSequence = {}

local SpellSequence = addon_table.Slots.SpellSequence

-- Cell组配置
SpellSequence.config = {
    name = "SpellSequence",
    -- 在矩阵中的起始位置
    anchor_x = 0,
    anchor_y = 0,
    -- Cell组定义
    cells = {
        -- 当前施法（MegaCell）
        { type = "mega", x = 0, y = 0, id = "current_cast" },
        -- 队列技能1-3（Cell）
        { type = "cell", x = 8, y = 0, id = "queue_1" },
        { type = "cell", x = 12, y = 0, id = "queue_2" },
        { type = "cell", x = 16, y = 0, id = "queue_3" },
    }
}

-- 初始化Cell组（占位）
function SpellSequence.Init(matrix_frame)
    -- 后续实现：根据config创建Cell实例
end

-- 更新显示（占位）
function SpellSequence.Update(spell_data)
    -- 后续实现：更新Cell内容
end
