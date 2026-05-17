local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert
local pairs                             = pairs

local CreateFrame                       = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization

local className, classFilename, classId = UnitClass("player") -- luacheck: ignore className classId
local currentSpec                       = GetSpecialization()
if classFilename ~= "HUNTER" then
    C_AddOns.DisableAddOn(addonName)
    return
end
if currentSpec ~= 1 then return end

local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "璇", key = "ALT-NUMPAD1", text = "/cast [target=focus,help,nodead][target=pet,exists,nodead][] 璇" })
insert(macroList, { title = "鍙敜瀹犵墿", key = "ALT-NUMPAD2", text = "/cast 鍙敜瀹犵墿" })
insert(macroList, { title = "澶嶆椿瀹犵墿", key = "ALT-NUMPAD3", text = "/cast 澶嶆椿瀹犵墿" })
insert(macroList, { title = "target鏉€鎴懡浠?", key = "ALT-NUMPAD4", text = "/cast [@target] 鏉€鎴懡浠?" })
insert(macroList, { title = "target鐙傞噹鎬掔伀", key = "ALT-NUMPAD5", text = "/cast [@target] 鐙傞噹鎬掔伀" })
insert(macroList, { title = "target鐙傞噹闉瑸", key = "ALT-NUMPAD6", text = "/cast [@target] 鐙傞噹闉瑸" })
insert(macroList, { title = "target鐚庝汉鍗拌", key = "ALT-NUMPAD7", text = "/cast [@target] 鐚庝汉鍗拌" })
insert(macroList, { title = "target瀹佺灏勫嚮", key = "ALT-NUMPAD8", text = "/cast [@target] 瀹佺灏勫嚮" })
insert(macroList, { title = "target鍙嶅埗灏勫嚮", key = "ALT-NUMPAD9", text = "/cast [@target] 鍙嶅埗灏勫嚮" })
insert(macroList, { title = "focus鍙嶅埗灏勫嚮", key = "ALT-NUMPAD0", text = "/cast [@focus] 鍙嶅埗灏勫嚮" })
insert(macroList, { title = "target鐪奸暅铔囧皠鍑?", key = "SHIFT-NUMPAD1", text = "/cast [@target] 鐪奸暅铔囧皠鍑?" })
insert(macroList, { title = "focus瀹佺灏勫嚮", key = "SHIFT-NUMPAD2", text = "/cast [@focus] 瀹佺灏勫嚮" })

for macroIndex, macro in pairs(macroList) do -- luacheck: ignore macroIndex
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    print("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
