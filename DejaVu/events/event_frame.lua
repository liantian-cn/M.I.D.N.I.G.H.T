--[[
文件定位：
  全局事件帧模块，用于创建并持有唯一的 EventFrame 实例。

输入来源：
  依赖 WoW API 的 CreateFrame("Frame") 能力以及 event_map 的事件定义。

输出职责：
  对外提供事件帧实例与基础注册入口，作为事件系统唯一载体。

生命周期/调用时机：
  在事件系统初始化阶段加载并创建（后续实现），全生命周期保持单例。

约束与非目标：
  当前不创建真实 Frame，不注册回调，仅定义模块职责边界。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

