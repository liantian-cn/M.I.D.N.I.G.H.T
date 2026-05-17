local _, addonTable = ...

local Whirlwind = {}

local iwStacks    = 0
local iwExpiresAt = nil

local playerInCombat     = false
local pendingGenToken    = 0
local seenCastGUID       = {}

Whirlwind.IW_MAX_STACKS = 4
local IW_DURATION   = 20

-- Talents
local REQUIRED_TALENT_ID = 12950   -- Improved Whirlwind talent . WITHOUT tracker is not working
local CRASHING_THUNDER_TALENT_ID = 436707
local CRACKLING_THUNDER_TALENT_ID = 203201
local UNHINGED_TALENT_ID = 386628  -- Unhinged  - if enabled -> BT will not consume stacks during Bladestorm

-- Generators
local GENERATOR_IDS = {
    [190411] = true, -- Whirlwind
    [6343]   = true, -- Thunder Clap
    [435222] = true, -- Thunder Blast
}

-- Spenders consume
local SPENDER_IDS = {
    [23881]  = true, -- Bloodthirst
    [85288]  = true, -- Raging Blow
    [280735] = true, -- Execute
    [202168] = true, -- Impending Victory
    [184367] = true, -- Rampage
    [335096] = true, -- Bloodbath
    [335097] = true, -- Crushing Blow
    [5308]   = true, -- Execute (base)
}



local function HasUnhingedTalent()
    return C_SpellBook and C_SpellBook.IsSpellKnown(UNHINGED_TALENT_ID) or false
end

local function HasCracklingThunderTalent()
    return (C_SpellBook and C_SpellBook.IsSpellKnown(CRACKLING_THUNDER_TALENT_ID)) or false
end

local function HasCrashingThunderTalent()
    return (C_SpellBook and C_SpellBook.IsSpellKnown(CRASHING_THUNDER_TALENT_ID)) or false
end

local function HasNearbyHostileAoE(spellID)
    if not playerInCombat and not UnitAffectingCombat("player") then
        return false
    end

    local spellRange = {
        [190411] = function(unit)
            return CheckInteractDistance(unit, 2) -- ~11 yards
        end,
        [6343]   = function(unit)
            return CheckInteractDistance(unit, 2) or (HasCracklingThunderTalent() and CheckInteractDistance(unit, 5))
        end,
        [435222] = function(unit)
            return CheckInteractDistance(unit, 2) or (HasCracklingThunderTalent() and CheckInteractDistance(unit, 5))
        end,
    }

    -- check nameplates directly (AoE around player)
    if CheckInteractDistance then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit)
                and UnitCanAttack("player", unit)
                and not UnitIsDead(unit)
                and (spellRange[spellID] and spellRange[spellID](unit) or false)
            then
                return true
            end
        end
    end

    return false
end

function Whirlwind:OnLoad(powerBar)
    local playerClass = select(2, UnitClass("player"))

    if playerClass == "WARRIOR" then
        powerBar.Frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        powerBar.Frame:RegisterEvent("PLAYER_DEAD")
        powerBar.Frame:RegisterEvent("PLAYER_ALIVE")
        powerBar.Frame:RegisterEvent("PLAYER_TALENT_UPDATE")
        powerBar.Frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
        powerBar.Frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    end
end

function Whirlwind:OnEvent(powerBar, event, ...)
    if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        powerBar:ApplyVisibilitySettings()
        powerBar:UpdateDisplay()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        playerInCombat = true
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        playerInCombat = false
	    pendingGenToken = pendingGenToken + 1
        return
    end

    -- Handle Death and Resurrection Reset
    if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
        iwStacks = 0
        iwExpiresAt = nil
        seenCastGUID = {} -- Clear GUID cache to prevent memory bloat
        return
    end

    local unit, castGUID, spellID = ...
    if unit ~= "player" then return end
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end

    if castGUID and seenCastGUID[castGUID] then return end
    if castGUID then seenCastGUID[castGUID] = true end

    -- Generator -> award stacks
    if GENERATOR_IDS[spellID] then
        if (spellID == 6343 or spellID == 435222) and not HasCrashingThunderTalent() then
            return
        end

        -- IWT BUGFIX: instant-kill / combat ends instantly can block stacks.
        -- Also: first hit from OOC may not set combat fast enough, so snapshot hostile target too.
        local combatAtCast = InCombatLockdown() or playerInCombat
        local hostileTargetAtCast = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")

        pendingGenToken = pendingGenToken + 1
        local myToken = pendingGenToken

        -- small delay
        C_Timer.After(0.15, function()
            if myToken ~= pendingGenToken then return end
            if not (combatAtCast or hostileTargetAtCast) and not HasNearbyHostileAoE(spellID) then return end

            iwStacks = Whirlwind.IW_MAX_STACKS
            iwExpiresAt = GetTime() + IW_DURATION
        end)

        return
    end

    -- Spender -> consume stack
    if SPENDER_IDS[spellID] then
        -- Bloodthirst/Bloodbath
        if HasUnhingedTalent() and not select(1, C_Spell.IsSpellUsable(446035)) and (spellID == 23881 or spellID == 335096) then return end
        if (iwStacks or 0) <= 0 then return end

        iwStacks = math.max(0, (iwStacks or 0) - 1)
        if iwStacks == 0 then iwExpiresAt = nil end

        return
    end
end

function Whirlwind:GetStacks()
    if iwExpiresAt and GetTime() >= iwExpiresAt then
        iwStacks = 0
        iwExpiresAt = nil
    end

    return C_SpellBook.IsSpellKnown(REQUIRED_TALENT_ID) and self.IW_MAX_STACKS or nil, iwStacks
end

addonTable.Whirlwind = Whirlwind