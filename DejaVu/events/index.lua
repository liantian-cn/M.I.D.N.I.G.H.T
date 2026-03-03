--[[
文件定位：
  事件模块统一暴露入口，负责 events 子目录的命名空间对外一致化。

输入来源：
  来自 addon 根命名空间和 events 子模块加载顺序。

输出职责：
  对外暴露 addon_table.Events 统一入口，供 event_map/event_frame/event_router 挂载。

生命周期/调用时机：
  在 events 子模块最先加载，作为事件域的稳定入口。

约束与非目标：
  当前仅建立命名约定，不实现事件处理逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name
addon_table.Events = addon_table.Events or {}
