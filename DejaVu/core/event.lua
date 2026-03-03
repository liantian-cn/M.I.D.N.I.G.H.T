--[[
文件定位：
  DejaVu 事件组件，统一管理WoW事件监听与分发。

输入来源：
  来自WoW API的事件触发，以及业务模块的事件注册请求。

输出职责：
  对外提供事件注册/注销接口，统一管理事件生命周期。

生命周期/调用时机：
  在插件初始化阶段加载，持续监听直至插件卸载。

约束与非目标：
  当前仅保留接口边界，不实现具体事件绑定逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Core命名空间存在
addon_table.Core = addon_table.Core or {}
addon_table.Core.Event = {}

local Event = addon_table.Core.Event

-- 事件帧（占位）
Event.frame = nil

-- 事件处理器表
Event.handlers = {}

-- 关注的事件列表
Event.events = {
    -- 战斗事件
    "PLAYER_ENTER_COMBAT",
    "PLAYER_LEAVE_COMBAT",
    -- 单位事件
    "UNIT_HEALTH",
    "UNIT_POWER_UPDATE",
    -- 施法事件
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_SUCCEEDED",
    -- 增益减益
    "UNIT_AURA",
    -- 玩家状态
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

-- 注册事件处理器（占位）
function Event.Register(event, handler)
    -- 后续实现
end

-- 注销事件处理器（占位）
function Event.Unregister(event, handler)
    -- 后续实现
end

-- 初始化事件系统（占位）
function Event.Init()
    -- 后续实现
end
