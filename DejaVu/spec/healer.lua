--[[
文件定位：
  DejaVu 治疗专精Cell组配置模块，定义治疗相关的Cell布局。

输入来源：
  来自治疗机制（团队血量、预读、蓝量等）与矩阵渲染需求。

输出职责：
  定义治疗专精Cell组的布局配置，调用Matrix.Cell/MegaCell创建方法。

生命周期/调用时机：
  在插件检测到玩家为治疗专精时加载。

约束与非目标：
  当前仅保留配置结构，不实现自动化逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Spec命名空间存在
addon_table.Spec = addon_table.Spec or {}
addon_table.Spec.Healer = {}

local Healer = addon_table.Spec.Healer

-- Cell组配置
Healer.config = {
    name = "Healer",
    -- 在矩阵中的起始位置
    anchor_x = 0,
    anchor_y = 20,
    -- Cell组定义
    cells = {
        -- 蓝量（MegaCell）
        { type = "mega", x = 0, y = 0, id = "mana" },
        -- 主要治疗技能（BadgeCell显示冷却）
        { type = "badge", x = 8, y = 0, id = "heal_1" },
        { type = "badge", x = 12, y = 0, id = "heal_2" },
        -- HoT监控（Cell）
        { type = "cell", x = 16, y = 0, id = "hot_1" },
        { type = "cell", x = 20, y = 0, id = "hot_2" },
    }
}

-- 初始化Cell组（占位）
function Healer.Init(matrix_frame)
    -- 后续实现：根据config创建Cell实例
end

-- 更新显示（占位）
function Healer.Update(healer_data)
    -- 后续实现：更新Cell内容
end
