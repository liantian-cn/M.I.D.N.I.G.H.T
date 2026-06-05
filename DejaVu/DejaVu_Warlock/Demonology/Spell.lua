local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert

local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization

local className, classFilename, classId = UnitClass("player") -- luacheck: ignore className classId
local currentSpec                       = GetSpecialization()
if classFilename ~= "WARLOCK" then
    C_AddOns.DisableAddOn(addonName)
    return
end
if currentSpec ~= 2 then return end

local DejaVu = _G["DejaVu"]
local cooldownSpells = DejaVu.cooldownSpells
local chargeSpells = DejaVu.chargeSpells

insert(cooldownSpells, { spellID = 105174, name = "古尔丹之手" })
insert(cooldownSpells, { spellID = 691, name = "召唤地狱猎犬" })
insert(cooldownSpells, { spellID = 688, name = "召唤小鬼" })
insert(cooldownSpells, { spellID = 104316, name = "召唤恐惧猎犬" })
insert(cooldownSpells, { spellID = 30146, name = "召唤恶魔卫士" })
insert(cooldownSpells, { spellID = 264178, name = "恶魔之箭" })
insert(cooldownSpells, { spellID = 686, name = "暗影箭" })
insert(cooldownSpells, { spellID = 196277, name = "内爆" })
insert(cooldownSpells, { spellID = 1276672, name = "召唤末日守卫" })
insert(cooldownSpells, { spellID = 265187, name = "召唤恶魔暴君" })
insert(cooldownSpells, { spellID = 1276467, name = "魔典：邪能破坏者" })
insert(cooldownSpells, { type = "item", itemID = 224464, name = "恶魔治疗石" })
insert(cooldownSpells, { type = "item", itemID = 258138, name = "强效治疗药水" })
insert(cooldownSpells, { spellID =  119914, name = "巨斧投掷" })
insert(cooldownSpells, { spellID =  119910, name = "法术封锁" })