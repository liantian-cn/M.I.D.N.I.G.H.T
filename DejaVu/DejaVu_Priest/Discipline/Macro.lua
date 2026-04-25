-- luacheck: globals C_AddOns CreateFrame GetSpecialization SetOverrideBindingClick UIParent UnitClass
local addonName, addonTable = ... -- luacheck: ignore addonTable -- 插件入口固定写法


-- Lua 原生函数
local insert                            = table.insert
local pairs                             = pairs

-- WoW 官方 API
local CreateFrame                       = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local _, classFilename = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "PRIEST" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是牧师则停止
if currentSpec ~= 1 then return end -- 不是戒律专精则停止


local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "player苦修", key = "ALT-NUMPAD1", text = "/focus player \n/cast [@player] 苦修" })
insert(macroList, { title = "party1苦修", key = "ALT-NUMPAD2", text = "/focus party1 \n/cast [@party1] 苦修" })
insert(macroList, { title = "party2苦修", key = "ALT-NUMPAD3", text = "/focus party2 \n/cast [@party2] 苦修" })
insert(macroList, { title = "party3苦修", key = "ALT-NUMPAD4", text = "/focus party3 \n/cast [@party3] 苦修" })
insert(macroList, { title = "party4苦修", key = "ALT-NUMPAD5", text = "/focus party4 \n/cast [@party4] 苦修" })
insert(macroList, { title = "player快速治疗", key = "ALT-NUMPAD6", text = "/focus player \n/cast [@player] 快速治疗" })
insert(macroList, { title = "party1快速治疗", key = "ALT-NUMPAD7", text = "/focus party1 \n/cast [@party1] 快速治疗" })
insert(macroList, { title = "party2快速治疗", key = "ALT-NUMPAD8", text = "/focus party2 \n/cast [@party2] 快速治疗" })
insert(macroList, { title = "party3快速治疗", key = "ALT-NUMPAD9", text = "/focus party3 \n/cast [@party3] 快速治疗" })
insert(macroList, { title = "party4快速治疗", key = "ALT-NUMPAD0", text = "/focus party4 \n/cast [@party4] 快速治疗" })
insert(macroList, { title = "player真言术盾", key = "ALT-F2", text = "/focus player \n/cast [@player] 真言术：盾" })
insert(macroList, { title = "party1真言术盾", key = "ALT-F3", text = "/focus party1 \n/cast [@party1] 真言术：盾" })
insert(macroList, { title = "party2真言术盾", key = "ALT-F5", text = "/focus party2 \n/cast [@party2] 真言术：盾" })
insert(macroList, { title = "party3真言术盾", key = "ALT-F6", text = "/focus party3 \n/cast [@party3] 真言术：盾" })
insert(macroList, { title = "party4真言术盾", key = "ALT-F7", text = "/focus party4 \n/cast [@party4] 真言术：盾" })
insert(macroList, { title = "player纯净术", key = "ALT-F8", text = "/focus player \n/cast [@player] 纯净术" })
insert(macroList, { title = "party1纯净术", key = "ALT-F9", text = "/focus party1 \n/cast [@party1] 纯净术" })
insert(macroList, { title = "party2纯净术", key = "ALT-F10", text = "/focus party2 \n/cast [@party2] 纯净术" })
insert(macroList, { title = "party3纯净术", key = "ALT-F11", text = "/focus party3 \n/cast [@party3] 纯净术" })
insert(macroList, { title = "party4纯净术", key = "ALT-F12", text = "/focus party4 \n/cast [@party4] 纯净术" })
insert(macroList, { title = "player耀", key = "SHIFT-NUMPAD1", text = "/focus player \n/cast [@player] 真言术：耀" })
insert(macroList, { title = "party1耀", key = "SHIFT-NUMPAD2", text = "/focus party1 \n/cast [@party1] 真言术：耀" })
insert(macroList, { title = "party2耀", key = "SHIFT-NUMPAD3", text = "/focus party2 \n/cast [@party2] 真言术：耀" })
insert(macroList, { title = "party3耀", key = "SHIFT-NUMPAD4", text = "/focus party3 \n/cast [@party3] 真言术：耀" })
insert(macroList, { title = "party4耀", key = "SHIFT-NUMPAD5", text = "/focus party4 \n/cast [@party4] 真言术：耀" })
insert(macroList, { title = "player灌注", key = "SHIFT-NUMPAD6", text = "/focus player \n/cast [@player] 能量灌注" })
insert(macroList, { title = "party1灌注", key = "SHIFT-NUMPAD7", text = "/focus party1 \n/cast [@party1] 能量灌注" })
insert(macroList, { title = "party2灌注", key = "SHIFT-NUMPAD8", text = "/focus party2 \n/cast [@party2] 能量灌注" })
insert(macroList, { title = "party3灌注", key = "SHIFT-NUMPAD9", text = "/focus party3 \n/cast [@party3] 能量灌注" })
insert(macroList, { title = "party4灌注", key = "SHIFT-NUMPAD0", text = "/focus party4 \n/cast [@party4] 能量灌注" })
insert(macroList, { title = "绝望祷言", key = "SHIFT-F8", text = "/cast 绝望祷言" })
insert(macroList, { title = "福音", key = "SHIFT-F9", text = "/cast 福音" })
insert(macroList, { title = "target痛", key = "SHIFT-,", text = "/cast [@target] 暗言术：痛" })
insert(macroList, { title = "focus痛", key = "ALT-,", text = "/cast [@focus] 暗言术：痛" })
insert(macroList, { title = "target灭", key = "SHIFT-.", text = "/cast [@target] 暗言术：灭" })
insert(macroList, { title = "focus灭", key = "ALT-.", text = "/cast [@focus] 暗言术：灭" })
insert(macroList, { title = "target心灵震爆", key = "SHIFT-/", text = "/cast [@target] 心灵震爆" })
insert(macroList, { title = "focus心灵震爆", key = "ALT-/", text = "/cast [@focus] 心灵震爆" })
insert(macroList, { title = "target苦修", key = "SHIFT-;", text = "/cast [@target] 苦修" })
insert(macroList, { title = "focus苦修", key = "ALT-;", text = "/cast [@focus] 苦修" })
insert(macroList, { title = "target惩击", key = "SHIFT-'", text = "/cast [@target] 惩击" })
insert(macroList, { title = "focus惩击", key = "ALT-'", text = "/cast [@focus] 惩击" })



for _, macro in pairs(macroList) do
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    print("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
