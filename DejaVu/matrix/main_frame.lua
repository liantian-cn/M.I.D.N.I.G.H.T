--[[
文件定位：
  DejaVu Matrix主框架模块，负责创建matrixFrame容器。

输入来源：
  依赖core/size的尺寸配置，以及WoW UI Frame创建能力。

输出职责：
  对外提供matrixFrame创建函数，作为所有Cell挂载的父节点。

生命周期/调用时机：
  在插件初始化阶段创建，运行期持续存在。

约束与非目标：
  当前仅保留创建接口边界，不实现实际Frame创建。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- Matrix模块命名空间
addon_table.Matrix = addon_table.Matrix or {}
addon_table.Matrix.MainFrame = {}

local MainFrame = addon_table.Matrix.MainFrame

-- matrixFrame实例（占位）
MainFrame.frame = nil

-- 创建matrixFrame（占位）
function MainFrame.Create()
    -- 后续实现
end

-- 设置锚点（占位）
function MainFrame.SetAnchor(point, relative_to, relative_point, x, y)
    -- 后续实现
end

-- 设置缩放（占位）
function MainFrame.SetScale(scale)
    -- 后续实现
end

-- 显示/隐藏（占位）
function MainFrame.Show()
    -- 后续实现
end

function MainFrame.Hide()
    -- 后续实现
end
