--[[
文件定位：
  事件路由模块，用于将 EventFrame 接收到的事件分发到对应处理入口。

输入来源：
  来自 event_frame 提供的事件触发，以及 event_map 提供的映射关系。

输出职责：
  对外提供事件分发协议，保证后续业务模块可按统一方式接入事件处理。

生命周期/调用时机：
  在事件系统初始化后可用，运行期持续参与事件分发流程。

约束与非目标：
  当前不实现处理函数注册与执行，仅保留路由职责说明。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

