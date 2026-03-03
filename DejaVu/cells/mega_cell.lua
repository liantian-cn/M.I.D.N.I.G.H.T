--[[
文件定位：
  MegaCell 构建模块，负责 8x8 图标级单元的构建职责定义。

输入来源：
  依赖 cell_spec 文档中的 MegaCell 规格及颜色配置域。

输出职责：
  对外提供 MegaCell 的构建边界，供单元工厂与渲染链路统一调用。

生命周期/调用时机：
  在需要高信息密度单元时被上层流程调用（后续实现）。

约束与非目标：
  当前不实现纹理绘制、数据编码和刷新逻辑，仅保留注释骨架。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

