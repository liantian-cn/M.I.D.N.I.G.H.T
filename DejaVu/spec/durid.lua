--[[
文件定位：
  DejaVu 德鲁伊职业特色Cell组配置模块，定义德鲁伊形态相关的Cell布局。

输入来源：
  来自德鲁伊形态切换机制与矩阵渲染需求。

输出职责：
  定义德鲁伊职业特色Cell组的布局配置，调用Matrix.Cell/MegaCell创建方法。

生命周期/调用时机：
  在插件检测到玩家为德鲁伊时加载。

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
addon_table.Spec.Durid = {}

local Durid = addon_table.Spec.Durid

-- Cell组配置
Durid.config = {
    name = "Durid",
    -- 在矩阵中的起始位置
    anchor_x = 0,
    anchor_y = 24,
    -- Cell组定义
    cells = {
        -- 当前形态（MegaCell）
        { type = "mega", x = 0, y = 0, id = "form" },
        -- 连击点/日能月能（BadgeCell）
        { type = "badge", x = 8, y = 0, id = "resource" },
        -- 形态特有技能（Cell）
        { type = "cell", x = 12, y = 0, id = "form_spell_1" },
        { type = "cell", x = 16, y = 0, id = "form_spell_2" },
    }
}

-- 初始化Cell组（占位）
function Durid.Init(matrix_frame)
    -- 后续实现：根据config创建Cell实例
end

-- 更新显示（占位）
function Durid.Update(durid_data)
    -- 后续实现：更新Cell内容
end
