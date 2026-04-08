local addonName, DejaVuCore = ... -- luacheck: ignore addonName

local GetTime = GetTime
local max = math.max
local min = math.min
local print = print
local tostring = tostring
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenHeight = GetScreenHeight

_G["DejaVu"] = DejaVuCore
DejaVuCore.DEBUG = true             -- 是否开启调试模式
DejaVuCore.Enable = true            -- 是否开启插件
DejaVuCore.VERSION = "12.0.1.66709" -- 插件版本
DejaVuCore.RangedRange = 42         -- 默认的远程检测范围

local function logging(msg)
    print("|cFFFFBB66[" .. addonName .. "]|r" .. tostring(msg))
end



local function GetUIScaleFactor(pixelValue)
    local physicalHeight = select(2, GetPhysicalScreenSize())
    local UI_scale = UIParent:GetScale()
    return pixelValue * 768 / physicalHeight / UI_scale
end


DejaVuCore.Logging = logging
DejaVuCore.GetUIScaleFactor = GetUIScaleFactor




DejaVuCore.BurstTime = GetTime() + 60

DejaVuCore.InBurst = function()
    return DejaVuCore.BurstTime > GetTime()
end

DejaVuCore.BurstRemaining = function()
    return min(60.0, max(0, DejaVuCore.BurstTime - GetTime()))
end

-- SLASH_BURST1 = "/burst"
-- SlashCmdList["BURST"] = function(msg) -- -- luacheck: ignore addonName
--     local delaySeconds = tonumber(msg)
--     if delaySeconds then
--         DejaVuCore.BurstTime = GetTime() + delaySeconds
--     end
-- end

SetCVar("secretChallengeModeRestrictionsForced", 1)
SetCVar("secretCombatRestrictionsForced", 1)
SetCVar("secretEncounterRestrictionsForced", 1)
SetCVar("secretMapRestrictionsForced", 1)
SetCVar("secretPvPMatchRestrictionsForced", 1)
SetCVar("secretAuraDataRestrictionsForced", 1)
