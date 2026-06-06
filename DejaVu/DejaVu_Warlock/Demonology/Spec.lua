local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert
local random                            = math.random

-- luacheck: globals UnitCreatureFamily
local CreateFrame                       = CreateFrame
local UnitClass                         = UnitClass
local UnitPower                         = UnitPower
local UnitPowerMax                      = UnitPowerMax
local UnitCreatureFamily                = UnitCreatureFamily
local GetSpecialization                 = GetSpecialization
local GetTime                           = GetTime
local GetPlayerAuraBySpellID            = C_UnitAuras.GetPlayerAuraBySpellID
local IsSpellKnown                      = C_SpellBook.IsSpellKnown

local className, classFilename, classId = UnitClass("player") -- luacheck: ignore className classId
local currentSpec                       = GetSpecialization()
if classFilename ~= "WARLOCK" then
    C_AddOns.DisableAddOn(addonName)
    return
end
if currentSpec ~= 2 then return end

local DejaVu = _G["DejaVu"]
local Cell = DejaVu.Cell
local MartixInitFuncs = DejaVu.MartixInitFuncs

local SOUL_SHARDS_POWER_TYPE = Enum.PowerType.SoulShards
local ARGUS_DOMINION_BUFF_ID = 1276166
local PET_TYPE_UNKNOWN = 0
local PET_TYPE_FELHUNTER = 127
local PET_TYPE_FELGUARD = 255

local warlockBurstStartTime = 0

local function InitFrame()
    local eventFrame = CreateFrame("Frame")

    local cells = {
        -- x:55 y:13
        -- Purpose: display Demonology warlock soul shards, using the same power type SenseiClassResourceBar uses for warlocks.
        SoulShards = Cell:New(55, 13),
        -- x:56 y:13
        -- Purpose: display Demonology warlock current pet interrupt family, 0 unknown, 127 Felhunter, 255 Felguard.
        PetInterruptFamily = Cell:New(56, 13)
    }

    local function UpdateSoulShards()
        local current = UnitPower("player", SOUL_SHARDS_POWER_TYPE)
        local max = UnitPowerMax("player", SOUL_SHARDS_POWER_TYPE)
        if max and max > 0 then
            cells.SoulShards:setCellRGBA(current / max)
        else
            cells.SoulShards:setCellRGBA(0)
        end
    end

    local function UpdateBurstTimer()
        local auraData = GetPlayerAuraBySpellID(ARGUS_DOMINION_BUFF_ID)
        local isArgusDominionActive = auraData ~= nil

        if isArgusDominionActive then
            if warlockBurstStartTime == 0 then
                warlockBurstStartTime = GetTime()
            end
            DejaVu.BurstTime = warlockBurstStartTime
        else
            warlockBurstStartTime = 0
            DejaVu.BurstTime = 0
        end
    end

    local function UpdatePetInterruptFamily()
        local family = UnitCreatureFamily("pet")
        if family == "恶魔卫士" or family == "Felguard" then
            cells.PetInterruptFamily:setCellRGBA(PET_TYPE_FELGUARD / 255)
        elseif family == "地狱猎犬" or family == "Felhunter" then
            cells.PetInterruptFamily:setCellRGBA(PET_TYPE_FELHUNTER / 255)
        else
            cells.PetInterruptFamily:setCellRGBA(PET_TYPE_UNKNOWN)
        end
    end

    local fastTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(frame, elapsed) -- luacheck: ignore frame
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            UpdateSoulShards()
            UpdateBurstTimer()
            UpdatePetInterruptFamily()
        end
    end)

    -- Purpose: refresh Demonology soul shards when player power changes.
    eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    -- Purpose: update burst timer when Argus's Dominion changes.
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    -- Purpose: refresh the soul shard cell after login/loading transitions.
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Purpose: refresh pet interrupt family when the active pet changes.
    eventFrame:RegisterEvent("UNIT_PET")

    eventFrame:SetScript("OnEvent", function(self, event, unit) -- luacheck: ignore self event unit
        UpdateSoulShards()
        UpdateBurstTimer()
        UpdatePetInterruptFamily()
    end)
end
insert(MartixInitFuncs, InitFrame)
