local addonName, addonTable = ... -- 插件入口固定写法
-- 官方API
local LoadAddOn = C_AddOns.LoadAddOn
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local DisableAddOn = C_AddOns.DisableAddOn


-- DejaVu Core
local DejaVu = _G["DejaVu"]
local logging = DejaVu.Logging
logging(addonName .. " loaded.")

LoadAddOn("DejaVu_Panel")
LoadAddOn("DejaVu_Matrix")
LoadAddOn("DejaVu_Aura")
LoadAddOn("DejaVu_Player")
LoadAddOn("DejaVu_Spell")
LoadAddOn("DejaVu_Enemy")
LoadAddOn("DejaVu_Party")
LoadAddOn("DejaVu_Common")

local className, classFilename, classId = UnitClass("player")

if classFilename == "DEATHKNIGHT" then
    LoadAddOn("DejaVu_DeathKnight")
elseif classFilename == "DRUID" then
    LoadAddOn("DejaVu_Druid")
elseif classFilename == "PRIEST" then
    LoadAddOn("DejaVu_Priest")
elseif classFilename == "DEMONHUNTER" then
    LoadAddOn("DejaVu_DemonHunter")
end

DisableAddOn("163UI_Info", UnitName("player"))
DisableAddOn("HeyboxPlayerInfo", UnitName("player"))
