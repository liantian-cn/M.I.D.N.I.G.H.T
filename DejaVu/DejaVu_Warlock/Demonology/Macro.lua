local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert
local pairs                             = pairs

local CreateFrame                       = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization

local className, classFilename, classId = UnitClass("player") -- luacheck: ignore className classId
local currentSpec                       = GetSpecialization()
if classFilename ~= "WARLOCK" then
    C_AddOns.DisableAddOn(addonName)
    return
end
if currentSpec ~= 2 then return end

local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target古尔丹之手", key = "ALT-NUMPAD1", text = "/cast [@target] 古尔丹之手" })
insert(macroList, { title = "focus法术封锁", key = "ALT-NUMPAD2", text = "/cast [@focus,exists,harm] [@target,exists,harm] 法术封锁(恶魔掌控技能)" })
insert(macroList, { title = "召唤小鬼", key = "ALT-NUMPAD3", text = "/cast 召唤小鬼" })
insert(macroList, { title = "target召唤恐惧猎犬", key = "ALT-NUMPAD4", text = "/cast [@target] 召唤恐惧猎犬" })
insert(macroList, { title = "召唤恶魔卫士", key = "ALT-NUMPAD5", text = "/cast 召唤恶魔卫士" })
insert(macroList, { title = "target恶魔之箭", key = "ALT-NUMPAD6", text = "/cast [@target] 恶魔之箭" })
insert(macroList, { title = "target暗影箭", key = "ALT-NUMPAD7", text = "/cast [@target] 暗影箭" })
insert(macroList, { title = "内爆", key = "ALT-NUMPAD8", text = "/cast 内爆" })
insert(macroList, { title = "target召唤末日守卫", key = "ALT-NUMPAD9", text = "/cast [@target] 召唤末日守卫" })
insert(macroList, { title = "target召唤恶魔暴君", key = "ALT-NUMPAD0", text = "/cast [@target] 召唤恶魔暴君" })
insert(macroList, { title = "target魔典：邪能破坏者", key = "SHIFT-NUMPAD1", text = "/cast [@target] 魔典：邪能破坏者" })
insert(macroList, { title = "恶魔治疗石", key = "SHIFT-NUMPAD5", text = "/cast 灵魂燃烧 \n/cast 恶魔治疗石" })
insert(macroList, { title = "强效治疗药水", key = "SHIFT-NUMPAD6", text = "/cast 强效治疗药水" })
insert(macroList, { title = "focus巨斧投掷", key = "SHIFT-NUMPAD2", text = "/cast [@focus,exists,harm] [@target,exists,harm] 巨斧投掷(特殊技能)" })
insert(macroList, { title = "target法术封锁", key = "SHIFT-NUMPAD7", text = "/cast [@target,exists,harm] 法术封锁(恶魔掌控技能)" })
insert(macroList, { title = "target巨斧投掷", key = "SHIFT-NUMPAD8", text = "/cast [@target,exists,harm] 巨斧投掷(特殊技能)" })

for macroIndex, macro in pairs(macroList) do -- luacheck: ignore macroIndex
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    print("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
