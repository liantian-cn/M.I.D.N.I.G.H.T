-- luacheck: globals C_SpellActivationOverlay
local addonName, addonTable             = ...          -- luacheck: ignore addonName

local insert                            = table.insert -- 表插入

-- WoW 官方 API
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "PRIEST" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是牧师则停止
if currentSpec ~= 4 then return end -- 不是戒律专精则停止
-- DejaVu Core
local DejaVu = _G["DejaVu"]
