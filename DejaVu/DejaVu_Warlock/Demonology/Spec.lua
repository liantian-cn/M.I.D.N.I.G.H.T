local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert
local random                            = math.random

local CreateFrame                       = CreateFrame
local UnitClass                         = UnitClass
local UnitPower                         = UnitPower
local UnitPowerMax                      = UnitPowerMax
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
local Config = DejaVu.Config
local MartixInitFuncs = DejaVu.MartixInitFuncs

local SOUL_SHARDS_POWER_TYPE = Enum.PowerType.SoulShards
local ARGUS_DOMINION_BUFF_ID = 1276166

local warlock_burst_mode = Config("warlock_burst_mode")
local warlockBurstStartTime = 0

local function InitFrame()
    local eventFrame = CreateFrame("Frame")

    local cells = {
        -- x:55 y:13
        -- Purpose: display Demonology warlock soul shards, using the same power type SenseiClassResourceBar uses for warlocks.
        SoulShards = Cell:New(55, 13)
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

    local function UpdateBurstModeReset()
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

        if warlock_burst_mode:get_value() and not isArgusDominionActive then
            warlock_burst_mode:set_value(false)
        end
    end

    local fastTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(frame, elapsed) -- luacheck: ignore frame
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            UpdateSoulShards()
            UpdateBurstModeReset()
        end
    end)

    -- Purpose: refresh Demonology soul shards when player power changes.
    eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    -- Purpose: reset burst mode when Argus's Dominion disappears.
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    -- Purpose: refresh the soul shard cell after login/loading transitions.
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(self, event, unit) -- luacheck: ignore self event unit
        UpdateSoulShards()
        UpdateBurstModeReset()
    end)
end
insert(MartixInitFuncs, InitFrame)
