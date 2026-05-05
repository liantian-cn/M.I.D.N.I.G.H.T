local addonName, addonTable = ... -- 插件入口固定写法


-- Lua 原生函数
local insert                            = table.insert
local pairs                             = pairs

-- WoW 官方 API
local CreateFrame                       = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEMONHUNTER" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是恶魔猎手则停止
if currentSpec ~= 2 then return end -- 不是复仇专精则停止


local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target幽魂炸弹", key = "ALT-NUMPAD1", text = "/cast [@target] 幽魂炸弹" })
insert(macroList, { title = "target怨念咒符", key = "ALT-NUMPAD2", text = "/cast [@cursor] 怨念咒符" })
insert(macroList, { title = "target灵魂裂劈", key = "ALT-NUMPAD3", text = "/cast [@target] 灵魂裂劈" })
insert(macroList, { title = "target烈焰咒符", key = "ALT-NUMPAD4", text = "/cast [@cursor] 烈焰咒符" })
insert(macroList, { title = "邪能毁灭", key = "ALT-NUMPAD5", text = "/cast 邪能毁灭" })
insert(macroList, { title = "献祭光环", key = "ALT-NUMPAD6", text = "/cast 献祭光环" })
insert(macroList, { title = "恶魔变形", key = "ALT-NUMPAD7", text = "/cast 恶魔变形" })
insert(macroList, { title = "target投掷利刃", key = "ALT-NUMPAD8", text = "/cast [@target] 投掷利刃" })
insert(macroList, { title = "target瓦解", key = "ALT-NUMPAD9", text = "/cast [@target] 瓦解" })
insert(macroList, { title = "focus瓦解", key = "ALT-NUMPAD0", text = "/cast [@focus] 瓦解" })
insert(macroList, { title = "鲁莽药水", key = "SHIFT-NUMPAD1", text = "/cast 鲁莽药水" })
insert(macroList, { title = "target破裂", key = "SHIFT-NUMPAD2", text = "/cast [@target] 破裂" })
insert(macroList, { title = "停止施法", key = "SHIFT-NUMPAD3", text = "/stopcasting" })
insert(macroList, { title = "恶魔尖刺", key = "SHIFT-NUMPAD4", text = "/cast 恶魔尖刺" })


for _, macro in pairs(macroList) do
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    print("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
