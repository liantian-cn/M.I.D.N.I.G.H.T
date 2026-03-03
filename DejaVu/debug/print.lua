--[[
文件定位：
  调试打印模块，用于定义插件调试日志输出的职责边界。

输入来源：
  依赖 debug 配置模块中的开关与输出级别约定。

输出职责：
  对外提供统一调试打印入口，便于后续定位初始化与渲染链路问题。

生命周期/调用时机：
  在调试开关开启时被各模块按需调用（后续实现）。

约束与非目标：
  当前不实现实际打印函数，仅保留模块作用说明。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

