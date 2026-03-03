--[[
文件定位：
  DejaVu 日志组件，提供统一的日志输出与调试辅助功能。

输入来源：
  来自各模块的日志调用请求，以及全局调试开关配置。

输出职责：
  对外提供日志打印接口，支持分级日志与条件输出。

生命周期/调用时机：
  在插件初始化早期加载，全生命周期可用。

约束与非目标：
  当前仅保留接口边界，不实现具体输出逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 日志组件命名空间
addon_table.Utils = addon_table.Utils or {}
addon_table.Utils.Logging = {}

local Logging = addon_table.Utils.Logging

-- 日志级别定义
Logging.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

-- 当前日志级别（后续从配置读取）
Logging.current_level = Logging.LEVEL.DEBUG

-- 日志输出函数（占位）
function Logging.Log(level, message)
    -- 后续实现
end

function Logging.Debug(message)
    Logging.Log(Logging.LEVEL.DEBUG, message)
end

function Logging.Info(message)
    Logging.Log(Logging.LEVEL.INFO, message)
end

function Logging.Warn(message)
    Logging.Log(Logging.LEVEL.WARN, message)
end

function Logging.Error(message)
    Logging.Log(Logging.LEVEL.ERROR, message)
end
