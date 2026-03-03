--[[
文件定位：
  Matrix 锚点模块，负责定义矩阵在屏幕上的锚点与偏移规则归属。

输入来源：
  来自配置层 layout 参数和 matrix_spec 文档中的锚点约定。

输出职责：
  对外提供锚点语义边界，供 matrix_frame 与 matrix_grid 在后续实现中使用。

生命周期/调用时机：
  在 matrix 子系统初始化前加载，作为坐标计算的前置约束。

约束与非目标：
  当前不实现坐标运算，仅声明锚点规则所在模块。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

