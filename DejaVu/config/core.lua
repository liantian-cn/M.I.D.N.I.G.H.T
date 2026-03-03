--[[
文件定位：
  核心配置模块，定义协议版本、矩阵尺寸、基础常量等全局参数容器。

输入来源：
  由项目文档中的协议草案约束驱动（protocol/matrix/cell 相关文档）。

输出职责：
  对外提供 core 配置域，作为其他配置与功能模块的基础依赖。

生命周期/调用时机：
  在配置链路最先加载，供 layout/colors/debug/index 模块引用。

约束与非目标：
  当前仅声明配置职责，不填充具体参数实现细节。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

