--[[
文件定位：
  DejaVu 全局变量模块，定义插件级命名空间与全局配置。

输入来源：
  来自插件初始化时的全局环境，以及协议文档中的命名约定。

输出职责：
  对外提供统一的模块入口和全局变量容器。

生命周期/调用时机：
  在插件加载最早阶段初始化，作为其他所有模块的基础依赖。

约束与非目标：
  当前仅建立命名空间结构，不实现具体业务逻辑。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 核心模块命名空间
addon_table.Core = addon_table.Core or {}

-- 配置域
addon_table.Core.Config = addon_table.Core.Config or {}

-- 变量域
addon_table.Core.Vars = addon_table.Core.Vars or {}

-- 协议版本（与Terminal对齐）
addon_table.Core.PROTOCOL_VERSION = "0.1.0"

-- 插件版本
addon_table.Core.VERSION = "12.0.1.66198"
