--[[
文件定位：
  布局配置模块，约束 Matrix 锚点、偏移、缩放与网格对齐相关参数。

输入来源：
  由 matrix_spec 草案中的锚点与坐标约定提供规范依据。

输出职责：
  对外提供 layout 配置域，供 matrix 子模块计算根 Frame 与网格位置。

生命周期/调用时机：
  在 core 配置之后加载，并在 matrix 模块初始化前可用。

约束与非目标：
  本阶段不实现动态布局算法，仅保留参数归属与用途说明。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

