# WoW 12.1 Active-Player Dispel Filtering Research

## Research Question

After filtering an AuraContainer group with `RAID_PLAYER_DISPELLABLE`, can `candidateFilters` further restrict the result to auras dispellable by the active player? Does the game expose the current specialization's supported dispel types?

## Scope and Source Version

- Target: WoW Mainline 12.1.0 PTR Changes 5, Build 68675.
- Game UI source: Gethe/wow-ui-source commit `3ea5134b14c626b09de1dcb1b0acf8f665460a53`, dated 2026-07-14.
- Project guide reviewed: `.context/development_guide/aura_container.md`.
- Access date: 2026-07-15.
- No external web claims were needed; conclusions are based on the local project records, the matching game UI source, and the generated API inventory.

## Executive Conclusion

For harmful auras on assistable units, the supported public solution is to use `HARMFUL|RAID`. The game source defines the harmful behavior of `RAID` as retaining auras the active player can dispel. If the conceptual pipeline must begin with `RAID_PLAYER_DISPELLABLE`, `HARMFUL|RAID_PLAYER_DISPELLABLE|RAID` expresses the intersection, although `RAID_PLAYER_DISPELLABLE` is normally redundant once `HARMFUL|RAID` is present.

`candidateFilters.includeDispelTypes` can perform a second-stage whitelist check against `auraData.dispelName`, but the public API does not expose a generic function that returns the current specialization's dispel-type set. The game computes a more precise per-aura boolean named `auraData.canActivePlayerDispel`, and Blizzard UI code uses it for its `DispellableByMe` display mode, but CustomAuraContainer does not expose that field as a candidate filter.

For helpful auras on enemies, such as purgeable, stealable, or enrage effects, the current public CustomAuraContainer contract cannot generically reduce `RAID_PLAYER_DISPELLABLE` to the exact subset actionable by the active player. A manually maintained class/spec/talent spell map is only an approximation because a dispel type alone does not encode offensive versus defensive dispel, stealing, soothing, self-only restrictions, or target restrictions.

## Findings

### 1. Filter Order Is Explicit

**Fact:** AuraContainer applies the standard filter string before `candidateFilters`.

The group membership path first invokes `ShouldIncludeAuraForFilterString` and then `DoesAuraPassCandidateFilters`. The project guide describes the same order.

Relevant sources:

- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerGroups.lua`, lines 503-516.
- `.context/development_guide/aura_container.md`, lines 188-210.

### 2. Dispel-Type Candidate Filters Are Type Whitelists, Not Capability Checks

**Fact:** `includeDispelTypes` and `excludeDispelTypes` index directly into `auraData.dispelName`.

Conceptually, the inclusion check is:

```lua
if candidateFilters.includeDispelTypes ~= nil then
    if not candidateFilters.includeDispelTypes[auraData.dispelName] then
        return false
    end
end
```

This proves that the filter answers “is this aura's dispel type in the supplied map?” It does not answer “can the active player act on this aura in its present unit and relationship context?”

Source: `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua`, lines 30-63.

### 3. `RAID` Already Represents the Active Player for Harmful Auras

**Source claim:** The game source documents the `RAID` filter as including helpful auras the player can apply and harmful auras the player can dispel.

**Inference:** When the requirement is limited to harmful auras on friendly or otherwise assistable units, this is the intended public C-side capability filter and is preferable to reconstructing specialization capabilities in addon Lua.

Recommended filter:

```lua
container:AddAuraGroup("dispellableByMe", "HARMFUL|RAID", {
    maxFrameCount = 3,
    initializeFrame = InitializeAuraButton,
})
```

Equivalent explicit intersection:

```lua
"HARMFUL|RAID_PLAYER_DISPELLABLE|RAID"
```

Source: `Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`, lines 266-284.

### 4. A Candidate-Filter-Based Harmful-Aura Route Exists Through `ProcessAura`

**Fact:** `AuraUtil.ProcessAura` classifies a harmful aura as `AuraUpdateChangedType.Dispel` only on its `aura.isRaid` path and when the aura has a recognized dispel type.

Therefore the following implements the requested two-stage structure for harmful auras:

```lua
container:SetAuraProcessingPolicy(
    CustomAuraContainerAuraProcessingPolicy.ProcessAura,
    {
        ignoreBuffs = true,
        ignoreDebuffs = true,
        ignoreDispelDebuffs = false,
    }
)

container:AddAuraGroup("dispellableByMe", "HARMFUL|RAID_PLAYER_DISPELLABLE", {
    candidateFilters = {
        processedAuraType = AuraUtil.AuraUpdateChangedType.Dispel,
    },
    initializeFrame = InitializeAuraButton,
})
```

**Recommendation:** Prefer `HARMFUL|RAID` unless another design constraint specifically requires the ProcessAura classification. The processing policy is container-wide and adds unnecessary machinery for this single filtering requirement.

Sources:

- `Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`, lines 342-376.
- `.context/development_guide/aura_container.md`, lines 434-456.

### 5. The Game Has a Per-Aura Active-Player Result, Not a Public Type-Set Getter

**Fact:** Current Blizzard UI code consumes `auraData.canActivePlayerDispel`.

The private-aura raid-frame implementation checks this field when the configured display mode is `Enum.RaidDispelDisplayType.DispellableByMe`. Combat audio alert code uses the same field for player debuff alerts. The edit-mode AuraData provider also includes it in sample AuraData.

Sources:

- `Interface/AddOns/Blizzard_PrivateAurasUI/Blizzard_PrivateAurasUI.lua`, lines 403-417.
- `Interface/AddOns/Blizzard_CombatAudioAlerts/Blizzard_CombatAudioAlertManager.lua`, lines 1037-1063.
- `Interface/AddOns/Blizzard_FrameXMLUtil/EditModeAuraDataProvider.lua`, lines 18-24.

**Fact:** `ValidateCandidateFilters` and `DoesAuraPassCandidateFilters` do not support `canActivePlayerDispel`.

**Important behavior:** Supplying the following does not implement filtering:

```lua
candidateFilters = {
    canActivePlayerDispel = true,
}
```

The inbound table copy retains unknown fields, validation does not reject this field, and the candidate evaluator never reads it. It is therefore silently ineffective.

Sources:

- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`, lines 72-139 and 250-264.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua`, lines 30-108.

### 6. `AuraUtil.DispellableDebuffTypes` Is Not the Current Specialization's Capability Set

**Fact:** The table is a global set of recognized harmful dispel categories:

```lua
Magic = true
Curse = true
Disease = true
Poison = true
Bleed = true
```

It is used by aura classification and does not vary by class, specialization, talents, known spells, unit relationship, or target.

Source: `Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`, lines 318-325.

**Fact:** A search of the generated API inventory found no public API whose purpose is to return the active player's or active specialization's dispel types. The only dispel-related `C_UnitAuras` query found was `GetAuraDispelTypeColor`, which maps an aura instance's dispel type through a color curve and does not describe player capability.

### 7. Enemy Helpful Auras Remain a Public-API Gap

**Fact:** Week 5 expanded `RAID_PLAYER_DISPELLABLE` to include helpful auras on enemies that a raid member can dispel or steal.

**Fact:** `AuraUtil.ProcessAura` routes helpful auras through its Buff path, not its Dispel path. Consequently, `processedAuraType = Dispel` intentionally removes enemy helpful auras rather than selecting those actionable by the active player.

**Inference:** Neither `includeDispelTypes` nor `isStealable = true` is a generic replacement for `canActivePlayerDispel`. For example, a `Magic` aura type does not reveal whether the active player has a defensive dispel, offensive purge, or spell-steal capability, and `isStealable` describes the aura rather than the player's current spell availability.

**Recommendation:** A complete public solution would require Blizzard to expose either:

- `candidateFilters.canActivePlayerDispel = true`, or
- a standard active-player filter such as `PLAYER_DISPELLABLE` that covers both friendly harmful and enemy helpful semantics.

Until then, exact active-player filtering of enemy helpful auras is not generally implementable through CustomAuraContainer alone.

### 8. External Capability Changes Require an Explicit Refresh

**Fact:** Managed AuraContainer registers its own aura and weapon-enchantment updates but does not register specialization or group-roster events.

**Recommendation:** A consumer whose filter result depends on active-player or group capability should call `container:UpdateAllAuras()` after relevant external changes, including at least specialization and group-roster changes. If dispel capability can change through talents or learned spells without a specialization transition, the addon should also refresh from its selected talent/spell update path.

Updating candidate filters through `SetAuraGroupCandidateFilters` already requests a full aura refresh.

Sources:

- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainer.lua`, lines 130-183.
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`, lines 347-363.
- Blizzard's own BuffFrame listener refreshes on `GROUP_ROSTER_UPDATE` and `PLAYER_SPECIALIZATION_CHANGED`: `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua`, lines 282-307.

## Conflicting or Incomplete Evidence

1. The implementation of standard aura filter tokens is in the game client rather than the Lua UI source. The conclusion about `RAID` uses Blizzard's current source comment and the surrounding `aura.isRaid` processing behavior; the underlying C implementation is not available in this repository.
2. `canActivePlayerDispel` is clearly present and consumed by Blizzard Lua, but it is not listed as a standalone getter in the generated API inventory. In addition, AuraData is fully secret in the relevant WoW 12.1 restricted situations, so direct addon-side AuraData inspection is not a valid replacement for AuraContainer filtering.
3. Exact active-player semantics for every offensive purge, spell-steal, enrage removal, self-only cleanse, and talent-modified spell cannot be reconstructed from `dispelName` alone.

## Confidence

- **High:** Standard filter then candidate-filter ordering; exact behavior of `includeDispelTypes`; absence of `canActivePlayerDispel` support in candidate filters; ProcessAura's harmful Dispel classification; AuraContainer event registrations.
- **High:** No public current-specialization dispel-type getter exists in the inspected Build 68675 generated API inventory.
- **Medium-high:** `HARMFUL|RAID` is the intended complete active-player solution for friendly harmful auras, based on Blizzard's source definition and processing path, with the final token implementation residing in the client.
- **High:** Current CustomAuraContainer cannot generically express exact active-player handling of enemy helpful auras.

## Relevance to Phantom

For a Phantom cell that displays friendly dispellable debuffs, use `HARMFUL|RAID` and avoid a maintained class/spec dispel matrix. If an existing design requires `RAID_PLAYER_DISPELLABLE` as its first-stage source, intersect it with `RAID` or use the documented ProcessAura classification, while keeping the harmful restriction explicit. Do not add `canActivePlayerDispel` as an undocumented candidate key because it is silently ignored.

For target/focus enemy helpful indicators, retain `RAID_PLAYER_DISPELLABLE` only if the intended meaning is “someone in the group can handle this.” Do not label that result as “I can handle this” without a player-capability mapping or a future Blizzard API extension.

## Sources

All game source links below refer to WoW UI source commit `3ea5134b14c626b09de1dcb1b0acf8f665460a53` (12.1.0 Build 68675), accessed 2026-07-15.

- [AuraContainer candidate evaluation](https://github.com/Gethe/wow-ui-source/blob/3ea5134b14c626b09de1dcb1b0acf8f665460a53/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua#L30-L108)
- [CustomAuraContainer candidate validation and inbound copying](https://github.com/Gethe/wow-ui-source/blob/3ea5134b14c626b09de1dcb1b0acf8f665460a53/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua#L72-L139)
- [Aura filter definitions and ProcessAura](https://github.com/Gethe/wow-ui-source/blob/3ea5134b14c626b09de1dcb1b0acf8f665460a53/Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua#L266-L376)
- [Blizzard `DispellableByMe` implementation](https://github.com/Gethe/wow-ui-source/blob/3ea5134b14c626b09de1dcb1b0acf8f665460a53/Interface/AddOns/Blizzard_PrivateAurasUI/Blizzard_PrivateAurasUI.lua#L403-L417)
- [Managed AuraContainer event registration](https://github.com/Gethe/wow-ui-source/blob/3ea5134b14c626b09de1dcb1b0acf8f665460a53/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainer.lua#L130-L183)
- Project API change record: `.context/api_changes/12.1.0/Week5.md`, dated 2026-07-14.
- Project AuraContainer guide: `.context/development_guide/aura_container.md`, current working copy accessed 2026-07-15.
