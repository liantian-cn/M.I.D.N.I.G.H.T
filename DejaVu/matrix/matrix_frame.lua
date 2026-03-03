--[[
文件定位：
  Matrix 根 Frame 模块，用于承载矩阵容器 Frame 的职责定义。

输入来源：
  依赖 layout 配置与锚点规则，以及 WoW UI Frame 创建能力。

输出职责：
  对外提供矩阵根容器的创建与访问边界，作为所有 Cell 挂载父节点。

生命周期/调用时机：
  在启动编排阶段初始化（后续实现），在插件运行期持续存在。

约束与非目标：
  当前不创建真实 UI 对象，仅保留结构意图与职责注释。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

