local addonName, DejaVu_Core = ...
local After = C_Timer.After
local GetTime = GetTime
local max = math.max
local min = math.min
local print = print
local tostring = tostring
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenHeight = GetScreenHeight

_G["DejaVu"] = DejaVu_Core
DejaVu_Core.DEBUG = true             -- 是否开启调试模式
DejaVu_Core.Enable = true            -- 是否开启插件
DejaVu_Core.VERSION = "12.0.1.66709" -- 插件版本
DejaVu_Core.RangedRange = 40         -- 默认的远程检测范围
DejaVu_Core.MeleeRange = 5           -- 默认的近战检测范围
DejaVu_Core.BadgeTitleTable = {}     -- 脚标提示表（key格式: icon_r_g_b, value格式: {icon=图标路径或ID, color=脚标颜色, title=提示文本}）
-- /dump DejaVu.BadgeTitleTable

local function logging(msg)
    print("|cFFFFBB66[" .. addonName .. "]|r" .. tostring(msg))
end



local function GetUIScaleFactor(pixelValue)
    local physicalHeight = select(2, GetPhysicalScreenSize())
    local UI_scale = UIParent:GetScale()
    return pixelValue * 768 / physicalHeight / UI_scale
end


DejaVu_Core.Logging = logging
DejaVu_Core.GetUIScaleFactor = GetUIScaleFactor




DejaVu_Core.BurstTime = GetTime() + 60

DejaVu_Core.InBurst = function()
    return DejaVu_Core.BurstTime > GetTime()
end

DejaVu_Core.BurstRemaining = function()
    return min(60.0, max(0, DejaVu_Core.BurstTime - GetTime()))
end

SLASH_BURST1 = "/burst"
SlashCmdList["BURST"] = function(msg)
    local delaySeconds = tonumber(msg)
    if delaySeconds then
        DejaVu_Core.BurstTime = GetTime() + delaySeconds
    end
end

After(0, function()
    SetCVar("secretChallengeModeRestrictionsForced", 1)
    SetCVar("secretCombatRestrictionsForced", 1)
    SetCVar("secretEncounterRestrictionsForced", 1)
    SetCVar("secretMapRestrictionsForced", 1)
    SetCVar("secretPvPMatchRestrictionsForced", 1)
    SetCVar("secretAuraDataRestrictionsForced", 1)
    SetCVar("scriptErrors", 1);
    SetCVar("doNotFlashLowHealthWarning", 1);
    SetCVar("cameraIndirectVisibility", 1);
    SetCVar("cameraIndirectOffset", 10);
    SetCVar("SpellQueueWindow", 150);
    SetCVar("targetNearestDistance", 5)
    SetCVar("cameraDistanceMaxZoomFactor", 2.6)
    SetCVar("CameraReduceUnexpectedMovement", 1)
    SetCVar("synchronizeSettings", 1)
    SetCVar("synchronizeConfig", 1)
    SetCVar("synchronizeBindings", 1)
    SetCVar("synchronizeMacros", 1)
    SetCVar("useUiScale", 0)
    -- SetCVar("ffxAntiAliasingMode", 0)
end)
