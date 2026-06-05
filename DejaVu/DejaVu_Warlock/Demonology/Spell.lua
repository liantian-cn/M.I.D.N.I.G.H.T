local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert

-- luacheck: globals UnitCreatureFamily
local UnitClass                         = UnitClass
local UnitCreatureFamily                = UnitCreatureFamily
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

local FELGUARD_INTERRUPT_SPELL_ID = 119914
local FELHUNTER_INTERRUPT_SPELL_ID = 119910

local function GetPetInterruptSpellID()
    local family = UnitCreatureFamily("pet")
    if family == "恶魔卫士" or family == "Felguard" then
        return FELGUARD_INTERRUPT_SPELL_ID
    elseif family == "地狱猎犬" or family == "Felhunter" then
        return FELHUNTER_INTERRUPT_SPELL_ID
    end
    return nil
end

insert(cooldownSpells, { spellID = 105174, name = "古尔丹之手" })
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
insert(cooldownSpells, {
    spellIDGetter = GetPetInterruptSpellID,
    spellIDs = { FELGUARD_INTERRUPT_SPELL_ID, FELHUNTER_INTERRUPT_SPELL_ID },
    name = "宠物打断"
})
