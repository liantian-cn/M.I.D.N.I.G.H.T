--[[
文件定位：
  DejaVu 插件入口文件，负责承接 WoW 加载器对插件主入口文件的加载。

输入来源：
  来自 DejaVu.toc 的最终加载项，以及 core 模块提供的启动能力。

输出职责：
  明确入口边界，调用启动流程完成插件初始化。

生命周期/调用时机：
  在 DejaVu.toc 加载顺序末尾执行，用于完成最终入口接线。

约束与非目标：
  本阶段仅保留入口结构，不实现完整初始化逻辑。

状态：
  draft
]]

local addonName, addonTable = ...

addonTable = addonTable or {}
addonTable.__addonName = addonName

-- 插件入口点（占位）
local function Initialize()
    -- 后续实现：调用各模块初始化
end

-- 注册ADDON_LOADED事件
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loaded_addonName)
    if loaded_addonName == addonName then
        Initialize()
    end
end)


-- 设置游戏变量，确保插件正常运行
SetCVar("secretChallengeModeRestrictionsForced", 1)
SetCVar("secretCombatRestrictionsForced", 1)
SetCVar("secretEncounterRestrictionsForced", 1)
SetCVar("secretMapRestrictionsForced", 1)
SetCVar("secretPvPMatchRestrictionsForced", 1)
SetCVar("secretAuraDataRestrictionsForced", 1)
SetCVar("scriptErrors", 1);
SetCVar("doNotFlashLowHealthWarning", 1);
