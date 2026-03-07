# WoW 12.0 Compatibility Update - StormsDungeonData v1.1.0

## Overview

StormsDungeonData has been updated to be fully compatible with World of Warcraft 12.0+ which introduced significant addon API restrictions and the new `C_DamageMeter` API.

## What Changed

### 1. **New C_DamageMeter API Support (WoW 12.0+)**

**Before (COMBAT_LOG_EVENT_UNFILTERED):**
- Addon listened to raw combat log events
- All damage, healing, interrupts parsed manually
- Worked for all WoW versions
- **Restricted in WoW 12.0+**

**After (C_DamageMeter API):**
- Uses official Blizzard `C_DamageMeter` API in WoW 12.0+
- Automatic restriction handling via `C_RestrictedActions`
- More reliable, official data source
- Fallback to legacy API for older WoW versions

### 2. **New DamageMeterCompat Module**

New file: `DamageMeterCompat.lua`

Provides compatibility layer that:
- Auto-detects WoW version
- Switches between APIs automatically
- Handles addon restrictions gracefully
- Provides unified interface to both APIs

**Key Features:**
```lua
-- Check WoW version
if MPT.DamageMeterCompat.IsWoW12Plus then
    -- Use C_DamageMeter API
else
    -- Use COMBAT_LOG_EVENT_UNFILTERED
end

-- Check restrictions before accessing data
if DamageMeterCompat:IsRestricted(Enum.AddOnRestrictionType.Combat) then
    print("Data is currently restricted by Blizzard")
    return
end

-- Get data from either API
local damageData = DamageMeterCompat:GetDamageData()
local healingData = DamageMeterCompat:GetHealingData()
local interruptData = DamageMeterCompat:GetInterruptData()
```

### 3. **WoW 12.0 Addon Restrictions**

WoW 12.0 introduced `Enum.AddOnRestrictionType` with the following restriction types:

| Restriction Type | Value | When Active | Details |
|---|---|---|---|
| `Combat` | 0x1 | During active combat | Combat data hidden in restricted content |
| `Encounter` | 0x2 | During raid boss fights | Prevents advantage in raids |
| `ChallengeMode` | 0x4 | During Mythic+ dungeons | **IMPORTANT FOR M+** |
| `PvPMatch` | 0x8 | During PvP arenas/RBGs | Combat data hidden in PvP |
| `Map` | 0x10 | In certain map zones | Zone-specific restrictions |

**Status for Mythic+:**
- ✅ `C_DamageMeter` API is accessible
- ✅ Damage done data available
- ✅ Healing done data available
- ✅ Interrupt data available
- ⚠️ May have slight delays updating in real-time

### 4. **Module Initialization Order**

```
Core.lua
  ↓
DamageMeterCompat.lua (NEW - initialized first!)
  ↓
Database.lua
Events.lua
CombatLog.lua (updated to use DamageMeterCompat)
UI/ modules
Main.lua
```

### 5. **Event Registration Changes**

**Old Events (still work for pre-12.0):**
```lua
self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
```

**New Events (WoW 12.0+):**
```lua
self.frame:RegisterEvent("COMBAT_METRICS_SESSION_NEW")
self.frame:RegisterEvent("COMBAT_METRICS_SESSION_UPDATED")
self.frame:RegisterEvent("COMBAT_METRICS_SESSION_END")
```

**Implementation:**
The addon now intelligently selects which events to register based on WoW version.

### 6. **Data Collection Flow**

#### Pre-WoW 12.0:
```
COMBAT_LOG_EVENT_UNFILTERED
  ↓
CombatLog:OnCombatLogEvent()
  ↓
Parse manual events → playerStats
  ↓
Save to database
```

#### WoW 12.0+:
```
COMBAT_METRICS_SESSION_END (or on loot)
  ↓
CombatLog:FinalizeNewAPIData()
  ↓
C_DamageMeter.GetCombatSessionFromID()
  ↓
DamageMeterCompat:GetDamageData()
DamageMeterCompat:GetHealingData()
DamageMeterCompat:GetInterruptData()
  ↓
Populate playerStats
  ↓
Save to database
```

## Compatibility Matrix

| WoW Version | Interface | Status | Method | Notes |
|---|---|---|---|---|
| 11.0.x | 110005 | ✅ Supported | COMBAT_LOG_EVENT_UNFILTERED | Legacy API |
| 12.0 | 120005 | ✅ Supported | C_DamageMeter | New official API |
| 12.1+ | 120100+ | ✅ Supported | C_DamageMeter | Auto-detect |

## Migration Guide for Players

### Nothing to do! 
- Addon auto-detects your WoW version
- Automatically uses correct API
- No manual configuration needed
- Your saved data continues to work

### If You Experience Issues:

1. **"Data is restricted" message**
   - This is normal in restricted content
   - Data will be captured when restrictions lift
   - Save occurs at dungeon completion

2. **Addon not tracking data in M+**
   - Ensure you loot the final chest (required trigger)
  - Check `/sdd status` to verify addon loaded
   - Try `/reload` to reload addon

3. **Old data stops loading**
   - Should not happen (data format unchanged)
  - Try `/sdd reset` if corrupted
   - Check SavedVariables file in Documents

## For Developers

### Using DamageMeterCompat in Your Code

```lua
-- Check if WoW 12.0+
if MPT.DamageMeterCompat.IsWoW12Plus then
    print("Using WoW 12.0+ C_DamageMeter API")
else
    print("Using legacy COMBAT_LOG_EVENT_UNFILTERED")
end

-- Check restrictions
if MPT.DamageMeterCompat:IsRestricted(Enum.AddOnRestrictionType.Combat) then
    print("Combat data currently restricted")
    return false
end

-- Get data from API
local damage = MPT.DamageMeterCompat:GetDamageData()
local healing = MPT.DamageMeterCompat:GetHealingData()
local interrupts = MPT.DamageMeterCompat:GetInterruptData()

-- Check session availability
local sessions = MPT.DamageMeterCompat:GetAvailableSessions()
for _, sessionID in ipairs(sessions) do
    local sessionInfo = MPT.DamageMeterCompat:GetSessionInfo(sessionID)
    -- Use sessionInfo
end
```

### Data Structure Changes

**Old (manual parsing):**
```lua
{
    damage = totalAmount,
    healing = totalAmount,
    interrupts = count,
}
```

**New (C_DamageMeter):**
```lua
{
    damage = source.totalAmount,        -- Total damage dealt
    dps = source.amountPerSecond,       -- Damage per second
    class = source.classFilename,       -- Class identifier
    specIcon = source.specIconID,       -- Spec icon
}
```

## Technical Details

### How Restrictions Work

Blizzard's addon restriction system uses flags:

```lua
local stateCombat = C_RestrictedActions.GetAddOnRestrictionState(
    Enum.AddOnRestrictionType.Combat
)

if stateCombat > 0 then
    -- Restriction is active, wait for it to clear
    C_Timer.After(1, function()
        -- Retry after 1 second
    end)
end
```

### Session IDs in C_DamageMeter

Each combat session gets a unique ID:

```lua
-- Get all sessions
local sessions = C_DamageMeter.GetAvailableCombatSessions()

-- Get specific session data
local session = C_DamageMeter.GetCombatSessionFromID(
    sessionID,
    Enum.DamageMeterType.DamageDone  -- or HealingDone, DamageTaken, etc.
)

-- Access combat sources
for _, source in ipairs(session.combatSources) do
    print(source.name, source.totalAmount)
end
```

## Version Information

- **Addon Version**: 1.1.0 (updated from 1.0.0)
- **Interface**: 120005 (WoW 12.0.5+)
- **Backwards Compatible**: Yes (auto-detect)
- **SavedVariables Format**: Unchanged
- **Breaking Changes**: None

## FAQ

### Q: Will my old saved data still work?
**A:** Yes! Data format is unchanged. The addon can read all previous runs.

### Q: Do I need to delete and reinstall?
**A:** No, just update the addon files. No configuration needed.

### Q: What if I play on both WoW 11.x and 12.0?
**A:** The addon auto-detects and uses the correct API for each version.

### Q: Does the addon track faster or slower now?
**A:** Same speed. The new API provides the same data, just from an official source.

### Q: Are there any features that don't work in WoW 12.0?
**A:** No. All features work the same. The C_DamageMeter API provides all necessary data.

### Q: What about PvP and raid data?
**A:** Same restrictions apply as before. Combat logging is restricted in those scenarios for addon fairness.

### Q: Can I mix WoW versions?
**A:** Yes. The addon works on any WoW version from 11.0.5 to 12.0+.

## Testing

If you want to test the addon:

1. **Pre-WoW 12.0:** Run normally, addon uses COMBAT_LOG_EVENT_UNFILTERED
2. **WoW 12.0+:** Run normally, addon auto-switches to C_DamageMeter
3. **Check status**: Type `/sdd status` to see which API is in use
4. **Run M+:** Complete a dungeon, verify scoreboard appears

## Support

If you encounter issues:

1. Type `/sdd status` - shows API in use and run count
2. Check chat for error messages (start with `[StormsDungeonData]`)
3. Verify addon is enabled in AddOns list
4. Try `/reload` to reload addon
5. Check WoW Error Logs folder for more details

## Summary

**TL;DR:**
- WoW 12.0 introduced API restrictions
- StormsDungeonData now uses the official `C_DamageMeter` API
- Auto-detects WoW version and switches APIs automatically
- No player action needed - works transparently
- All features work exactly as before
- Saved data continues to work perfectly
