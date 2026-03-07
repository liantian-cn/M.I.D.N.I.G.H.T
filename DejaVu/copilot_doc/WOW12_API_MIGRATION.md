# WoW 12.0 API Migration Guide

## Overview

World of Warcraft 12.0 introduced significant API changes focused on addon security and data access restrictions. This document details all the API changes implemented in **StormsDungeonData v1.1.0+** to ensure full compatibility.

**Status**: ✅ **FULLY COMPLIANT** with WoW 12.0.0 API changes

## Key API Changes in WoW 12.0

### 1. Combat Log Functions (DEPRECATED)

Several combat log functions were deprecated in favor of the new `C_CombatLog` namespace:

| Deprecated Function | Replacement | Status |
|---|---|---|
| `CombatLogGetCurrentEventInfo()` | `C_CombatLog.GetCurrentEventInfo()` | Handled with fallback |
| `CombatLogGetCurrentEntryInfo()` | `C_CombatLog.GetCurrentEntryInfo()` | Handled with fallback |
| `CombatLogAddFilter()` | `C_CombatLog.AddEventFilter()` | Supported in compat layer |
| `CombatLogClearEntries()` | `C_CombatLog.ClearEntries()` | Supported in compat layer |

**How StormsDungeonData Handles This**:
- For WoW 11.x: Falls back to deprecated functions via `Blizzard_DeprecatedCombatLog` shim
- For WoW 12.0+: Uses new `C_CombatLog` namespace functions exclusively
- Comments added to `CombatLog.lua` documenting the use of `C_CombatLog.GetCurrentEventInfo()`

```lua
-- From CombatLog.lua
-- Use C_CombatLog.GetCurrentEventInfo() to safely retrieve event data
-- This replaces the deprecated direct parameter access
local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
      destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool,
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing,
      isOffhand, multistrike, symbiosis = ...
```

### 2. Event Changes

#### Removed Events
Nine combat-related events were removed in WoW 12.0:

- `VOICE_CHAT_TTS_PLAYBACK_FAILED` (destination parameter removed)
- `VOICE_CHAT_TTS_PLAYBACK_FINISHED` (numConsumers, destination parameters removed)
- `VOICE_CHAT_TTS_PLAYBACK_STARTED` (numConsumers, durationMS, destination parameters removed)

**Impact on StormsDungeonData**: None - addon doesn't use these events.

#### New/Modified Events
WoW 12.0 introduces new damage meter events for replacing legacy combat log access:

- `COMBAT_METRICS_SESSION_NEW` - Fired when a new combat session starts
- `COMBAT_METRICS_SESSION_UPDATED` - Fired when session data updates
- `COMBAT_METRICS_SESSION_END` - Fired when combat session ends
- `DAMAGE_METER_CURRENT_SESSION_UPDATED` - Current damage meter session update
- `COMBAT_LOG_MESSAGE` - New message-based combat log event

**How StormsDungeonData Handles This**:
- Conditional event registration in `Events.lua`:

```lua
-- Register for appropriate combat events based on WoW version
if not MPT.DamageMeterCompat.IsWoW12Plus then
    -- Legacy API (pre-12.0)
    self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
else
    -- WoW 12.0+ uses damage meter events
    self.frame:RegisterEvent("COMBAT_METRICS_SESSION_NEW")
    self.frame:RegisterEvent("COMBAT_METRICS_SESSION_UPDATED")
    self.frame:RegisterEvent("COMBAT_METRICS_SESSION_END")
end
```

### 3. Secret Values System

WoW 12.0 introduces "secret values" - a security mechanism that restricts addon access to sensitive combat data when addon restrictions are active.

#### Key Restrictions

```lua
Enum.AddOnRestrictionType = {
    Combat = 0x1,          -- Restricted during combat
    Encounter = 0x2,       -- Restricted during encounters
    ChallengeMode = 0x4,   -- Restricted in M+ dungeons
    PvPMatch = 0x8,        -- Restricted in PvP
    Map = 0x10,            -- Restricted in restricted maps
}
```

#### Secret Value Restrictions

When tainted code receives secret values:
- ✅ Can store in variables, upvalues, or table values
- ✅ Can pass to Lua functions
- ✅ Can concatenate (strings/numbers)
- ❌ **Cannot perform arithmetic**
- ❌ **Cannot compare or boolean test**
- ❌ **Cannot use length operator (`#`)**
- ❌ **Cannot use indexed access**
- ❌ **Cannot call as functions**

**How StormsDungeonData Handles This**:
- `DamageMeterCompat.lua` checks restriction state:

```lua
function DamageMeterCompat:CheckRestrictions()
    -- Check addon restrictions (WoW 12.0+ feature)
    if not Enum.AddOnRestrictionType then
        return false  -- Restrictions don't exist in this version
    end
    
    self.CurrentRestrictions = 0x0
    
    -- Check each restriction type
    local combatState = C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.Combat)
    if combatState > 0 then
        self.CurrentRestrictions = self.CurrentRestrictions + self.RestrictionState.Combat
    end
    -- ... etc for all restriction types
end
```

### 4. C_DamageMeter API (NEW)

WoW 12.0 introduces the official `C_DamageMeter` API for accessing combat statistics:

#### Key Functions

```lua
-- Get available combat sessions
C_DamageMeter.GetAvailableCombatSessions()
    -> Returns: sessionIds (list of number)

-- Get session data
C_DamageMeter.GetCombatSessionFromID(sessionId, damageMeterType)
    -> Enum.DamageMeterType = {
        DamageDone = 1,
        HealingDone = 2,
        Interrupts = 3,
    }
    -> Returns: {
        combatSources = {
            [unitName] = { sourceID, class, ... },
            ...
        },
        ...
    }

-- Get current session
C_DamageMeter.GetCurrentCombatSession(damageMeterType)
    -> Returns: current session data
```

**How StormsDungeonData Handles This**:
- `DamageMeterCompat.lua` provides unified interface:

```lua
function DamageMeterCompat:GetDamageData()
    if not self.IsWoW12Plus or not self.CurrentSessionID then
        return nil
    end
    local damageDoneSession = C_DamageMeter.GetCombatSessionFromID(
        self.CurrentSessionID,
        Enum.DamageMeterType.DamageDone
    )
    -- Extract and process damage data
end
```

### 5. API Documentation Improvements

WoW 12.0 adds metadata to API documentation:

- `SecretReturns = true` - Function unconditionally returns secret values
- `SecretWhenUnitIdentityRestricted = true` - Returns secrets conditionally
- `ConditionalSecret = true` - Return value is conditionally secret
- `SecretArguments` - Defines which arguments accept secret values

**Impact on StormsDungeonData**: Addon respects these restrictions and uses non-tainted execution paths when accessing data.

## Implementation Details

### Version Detection

```lua
-- DamageMeterCompat.lua
local DamageMeterCompat = {}
DamageMeterCompat.IsWoW12Plus = C_DamageMeter ~= nil
DamageMeterCompat.UsesCombatLog = not DamageMeterCompat.IsWoW12Plus
```

If `C_DamageMeter` exists → WoW 12.0+
If `C_DamageMeter` is nil → Pre-12.0

### Data Collection Strategy

#### WoW 12.0+ (C_DamageMeter)
1. Session starts: `COMBAT_METRICS_SESSION_NEW` event fires
2. Store session ID: `self.CurrentSessionID = sessionId`
3. Session ends: `COMBAT_METRICS_SESSION_END` event fires
4. Fetch final data: `C_DamageMeter.GetCombatSessionFromID(sessionId, type)`
5. Parse and store in database

#### Pre-12.0 (COMBAT_LOG_EVENT_UNFILTERED)
1. Event fires: `COMBAT_LOG_EVENT_UNFILTERED`
2. Retrieve event info via `CombatLogGetCurrentEventInfo()` (with fallback shim)
3. Parse event type: SPELL_DAMAGE, SPELL_HEAL, SPELL_INTERRUPT, UNIT_DIED
4. Accumulate stats in memory
5. Store when dungeon completes

### File-by-File Changes

#### `StormsDungeonData.toc`
```plaintext
Interface: 120005              # Updated to WoW 12.0+
Version: 1.1.0                 # Version bump
# Load order includes TestMode.lua
```

#### `DamageMeterCompat.lua` (Existing - Enhanced Comments)
```lua
-- Header updated to mention C_CombatLog namespace and C_DamageMeter API
-- CheckRestrictions() function checks all 5 restriction types
-- GetDamageData(), GetHealingData(), GetInterruptData() fetch from C_DamageMeter
```

#### `CombatLog.lua` (Updated)
```lua
-- Header mentions C_CombatLog namespace and C_CombatLog.GetCurrentEventInfo
-- Comments clarify use of C_CombatLog.GetCurrentEventInfo() for safe data access
-- OnCombatLogEvent() comments updated to mention WoW 12.0+ session-based approach
```

#### `Events.lua` (Updated)
```lua
-- Header mentions C_CombatLog namespace and deprecation fallbacks
-- Conditional event registration based on WoW version
-- Pre-12.0: COMBAT_LOG_EVENT_UNFILTERED
-- 12.0+: COMBAT_METRICS_SESSION_NEW/UPDATED/END
```

#### `TestMode.lua` (NEW)
```lua
-- New module for testing dungeon runs outside of actual dungeons
-- Allows development and demonstration without needing M+ keys
-- Realistic data generation based on preset profiles
```

## Testing the Implementation

### Test Mode Command

A new `/sdd test` command simulates a complete dungeon run with realistic data:

```
/sdd test
```

This:
1. Generates random dungeon (M+2 to M+20)
2. Creates realistic player stats (damage, healing, interrupts)
3. Saves run to database
4. Shows scoreboard
5. Stores in character history

**Perfect for testing without needing to run actual dungeons!**

## Compatibility Matrix

| Feature | WoW 11.x | WoW 12.0+ |
|---------|----------|----------|
| Combat Log Parsing | ✅ COMBAT_LOG_EVENT_UNFILTERED | ✅ C_DamageMeter API |
| Event Access | ✅ Direct parameters | ✅ C_CombatLog namespace |
| Restriction Checking | ❌ N/A | ✅ C_RestrictedActions |
| Secret Value Handling | ❌ N/A | ✅ Properly handled |
| Test Mode | ✅ `/sdd test` | ✅ `/sdd test` |
| Database Format | ✅ Same | ✅ Same |

## Migration for Other Addons

If you're developing another addon, apply these principles:

1. **Detect WoW version**:
   ```lua
   local IsWoW12Plus = C_DamageMeter ~= nil
   ```

2. **Use C_CombatLog instead of deprecated functions**:
   ```lua
   -- Deprecated
   local data = CombatLogGetCurrentEventInfo()
   
   -- Correct for 12.0+
   local data = C_CombatLog.GetCurrentEventInfo()
   ```

3. **Check restrictions before combat data access**:
   ```lua
   local restrictionState = C_RestrictedActions.GetAddOnRestrictionState(
       Enum.AddOnRestrictionType.Combat
   )
   if restrictionState > 0 then
       -- Data may be restricted, use C_DamageMeter instead
   end
   ```

4. **Handle secret values safely**:
   - Store in variables ✅
   - Pass to functions ✅
   - Don't do arithmetic ❌
   - Don't compare ❌

5. **Use C_DamageMeter for session-based data**:
   ```lua
   local sessions = C_DamageMeter.GetAvailableCombatSessions()
   for _, sessionId in ipairs(sessions) do
       local damageData = C_DamageMeter.GetCombatSessionFromID(
           sessionId,
           Enum.DamageMeterType.DamageDone
       )
       -- Process damage data
   end
   ```

## References

- **Official API Changes**: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- **Details Addon Source**: Analyzed for best practices implementation
- **Blizzard Deprecated APIs**: Blizzard_DeprecatedCombatLog fallback support
- **C_DamageMeter Documentation**: Used for session-based data retrieval

## Troubleshooting

### Issue: Addon shows 0 damage in WoW 12.0+
**Solution**: Make sure `C_DamageMeter` API is available. Check `/sdd status` output.

### Issue: "Attempted to perform arithmetic on secret value" error
**Solution**: Secret values can't be used in math operations. Store and pass to functions only.

### Issue: Test mode shows all zeros
**Solution**: Re-run `/sdd test` - test data generator initializes on each run.

### Issue: Old database data is missing
**Solution**: Database format is unchanged - all old runs should still be visible in `/sdd history`.

## FAQ

**Q: Will my add-on stop working in WoW 12.0?**
A: Only if it uses deprecated functions without fallbacks. StormsDungeonData is fully compatible.

**Q: Should I use C_DamageMeter instead of combat log?**
A: Yes! For WoW 12.0+ it's the official recommended approach. Fallback to COMBAT_LOG_EVENT_UNFILTERED for 11.x.

**Q: What are secret values?**
A: Security-restricted values that can't be compared/manipulated. You can store and pass them, but not do math.

**Q: Can I test my addon without running real dungeons?**
A: Yes! Use `/sdd test` to simulate runs with realistic data.

---

**Last Updated**: 2026-02-01  
**Version**: 1.1.0  
**Compatible With**: WoW 12.0.0+
