--[[
文件定位：
  DejaVu 玩家减益Cell组配置模块，定义玩家Debuff相关的Cell布局。

输入来源：
  来自UNIT_AURA事件与矩阵渲染需求。

输出职责：
  定义玩家减益Cell组的布局配置，调用Matrix.BadgeCell创建方法。

生命周期/调用时机：
  在插件初始化时注册，在减益变化时更新。

约束与非目标：
  当前仅保留配置结构，不实现自动化逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Slots命名空间存在
addon_table.Slots = addon_table.Slots or {}
addon_table.Slots.Aura = addon_table.Slots.Aura or {}
addon_table.Slots.Aura.PlayerDebuff = {}

local PlayerDebuff = addon_table.Slots.Aura.PlayerDebuff

-- Cell组配置
PlayerDebuff.config = {
    name = "PlayerDebuff",
    -- 在矩阵中的起始位置
    anchor_x = 0,
    anchor_y = 12,
    -- Cell组定义（使用BadgeCell显示类型和层数）
    cells = {
        { type = "badge", x = 0, y = 0, id = "debuff_1" },
        { type = "badge", x = 4, y = 0, id = "debuff_2" },
        { type = "badge", x = 8, y = 0, id = "debuff_3" },
        { type = "badge", x = 12, y = 0, id = "debuff_4" },
        { type = "badge", x = 16, y = 0, id = "debuff_5" },
        { type = "badge", x = 20, y = 0, id = "debuff_6" },
    }
}

-- 初始化Cell组（占位）
function PlayerDebuff.Init(matrix_frame)
    -- 后续实现：根据config创建Cell实例
end

-- 更新显示（占位）
function PlayerDebuff.Update(aura_data)
    -- 后续实现：更新Cell内容
end
