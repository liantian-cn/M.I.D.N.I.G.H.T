--[[
文件定位：
  矩阵模块统一暴露入口，负责 matrix 子目录的命名空间对外一致化。

输入来源：
  来自 addon 根命名空间和 matrix 子模块加载顺序。

输出职责：
  对外暴露 addon_table.Matrix 统一入口，供 matrix_anchor/matrix_frame/matrix_grid 挂载。

生命周期/调用时机：
  在 matrix 子模块最先加载，作为矩阵域的稳定入口。

约束与非目标：
  当前仅建立命名约定，不实现矩阵渲染逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name
addon_table.Matrix = addon_table.Matrix or {}
