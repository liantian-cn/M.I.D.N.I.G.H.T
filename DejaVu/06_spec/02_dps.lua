--[[
文件定位：
  DejaVu DPS专精Cell组配置模块，定义DPS相关的Cell布局。

输入来源：
  来自DPS机制（爆发、资源、优先级等）与矩阵渲染需求。

输出职责：
  定义DPS专精Cell组的布局配置，调用Matrix.Cell/MegaCell创建方法。

生命周期/调用时机：
  在插件检测到玩家为DPS专精时加载。

约束与非目标：
  当前仅保留配置结构，不实现自动化逻辑。

状态：
  draft
]]

local addonName, addonTable = ...

addonTable = addonTable or {}
addonTable.__addonName = addonName

-- 确保Spec命名空间存在
addonTable.Spec = addonTable.Spec or {}
addonTable.Spec.DPS = {}

local DPS = addonTable.Spec.DPS
