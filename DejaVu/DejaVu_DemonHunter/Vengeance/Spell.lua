-- luacheck: globals C_SpellActivationOverlay
local addonName, addonTable             = ...          -- luacheck: ignore addonName

local insert                            = table.insert -- 表插入

-- WoW 官方 API
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
-- DejaVu Core
local DejaVu = _G["DejaVu"]
local cooldownSpells = DejaVu.cooldownSpells
local chargeSpells = DejaVu.chargeSpells



insert(cooldownSpells, { spellID = 247454, name = "幽魂炸弹" })
insert(cooldownSpells, { spellID = 390163, name = "怨念咒符" })
insert(cooldownSpells, { spellID = 228477, name = "灵魂裂劈" })
insert(cooldownSpells, { spellID = 187827, name = "恶魔变形" })
insert(cooldownSpells, { spellID = 204596, name = "烈焰咒符" })
insert(cooldownSpells, { spellID = 183752, name = "瓦解" })
insert(cooldownSpells, { spellID = 258920, name = "献祭光环" })
insert(cooldownSpells, { spellID = 1236994, name = "鲁莽药水" })
insert(cooldownSpells, { spellID = 212084, name = "邪能毁灭" })

insert(chargeSpells, { spellID = 204157, name = "投掷利刃" })
insert(chargeSpells, { spellID = 263642, name = "破裂" })
insert(chargeSpells, { spellID = 203720, name = "恶魔尖刺" })
