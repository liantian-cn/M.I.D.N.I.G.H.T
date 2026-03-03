--[[
文件定位：
  DejaVu 坦克专精Cell组配置模块，定义坦克相关的Cell布局。

输入来源：
  来自坦克机制（仇恨、减伤、自疗等）与矩阵渲染需求。

输出职责：
  定义坦克专精Cell组的布局配置，调用Matrix.Cell/MegaCell创建方法。

生命周期/调用时机：
  在插件检测到玩家为坦克专精时加载。

约束与非目标：
  当前仅保留配置结构，不实现自动化逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- Spec模块命名空间
addon_table.Spec = addon_table.Spec or {}
addon_table.Spec.Tank = {}

local Tank = addon_table.Spec.Tank

-- Cell组配置
Tank.config = {
    name = "Tank",
    -- 在矩阵中的起始位置
    anchor_x = 0,
    anchor_y = 20,
    -- Cell组定义
    cells = {
        -- 威胁值（MegaCell）
        { type = "mega", x = 0, y = 0, id = "threat" },
        -- 减伤技能（Cell）
        { type = "cell", x = 8, y = 0, id = "mitigation_1" },
        { type = "cell", x = 12, y = 0, id = "mitigation_2" },
        -- 自疗（BadgeCell显示冷却）
        { type = "badge", x = 16, y = 0, id = "self_heal" },
    }
}

-- 初始化Cell组（占位）
function Tank.Init(matrix_frame)
    -- 后续实现：根据config创建Cell实例
end

-- 更新显示（占位）
function Tank.Update(tank_data)
    -- 后续实现：更新Cell内容
end
