# Changelog

## 2026-06-05

### Add dynamic Warlock pet interrupt cooldown

- Added dynamic cooldown spell entry support so a slot can resolve its spell ID at refresh time.
- Changed Demonology Warlock pet interrupt output to use Axe Toss for Felguard and Spell Lock for Felhunter in one shared cooldown slot.

Verification:

- `luacheck DejaVu_Spell\Cooldown.lua DejaVu_Warlock\Demonology\Spell.lua` -> 0 warnings / 0 errors
- Full DejaVu `luacheck ... DejaVu_Warlock` -> 0 errors; existing warnings remain in unrelated modules and bundled libs

## 2026-06-04

### Add Terminal Warlock healing item logic

- Added Demonology Warlock rotation handling for `恶魔治疗石` and `强效治疗药水` below 60% player health, using the matching `SHIFT-NUMPAD5` and `SHIFT-NUMPAD6` macro bindings.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed

### Add Warlock healing item macros

- Added Demonology Warlock override macros for `恶魔治疗石` on `SHIFT-NUMPAD5` and `强效治疗药水` on `SHIFT-NUMPAD6`, matching the Devourer Demon Hunter healing item bindings while using the Warlock-specific healthstone.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors

### Remove Warlock burst permission auto-reset

- Removed the Demonology Warlock burst permission auto-reset from the Argus Dominion aura watcher; the aura watcher now only maintains `DejaVu.BurstTime`.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors

### Rename Warlock burst toggle label

- Renamed the Demonology Warlock panel checkbox from `爆发模式` to `爆发许可` while keeping the existing `warlock_burst_mode` config key unchanged.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors

### Track Warlock burst timer from Argus Dominion

- Added Demonology Warlock burst timer tracking so `DejaVu.BurstTime` starts when the Argus Dominion aura appears and resets when the aura disappears, matching the Devourer Demon Hunter timing behavior.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors

### Reset Warlock burst mode when Argus Dominion is absent

- Changed Demonology Warlock burst-mode reset to turn the toggle off whenever burst mode is enabled and the Argus Dominion aura is no longer present, without requiring a prior observed active aura state.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors

## 2026-06-02

### Reset Warlock burst mode from Argus Dominion

- Changed Demonology Warlock burst-mode auto-reset to watch `阿古斯的支配` aura ID `1276166`; the toggle now turns off when that buff disappears.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors
- `git diff --check` -> no whitespace errors

## 2026-06-02

### Tune Demonology Warlock steady cooldowns

- Updated `WarlockDemonology.py` steady-state logic so Doomguard is used on 4+ targets or at combat start, while Grimoire: Felguard is favored for single-target situations.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-06-02

### Add Demonology Warlock burst mode

- Added a Demonology Warlock `爆发模式` setting cell at `setting.cell(0)` / `x=55,y=12`.
- Updated `WarlockDemonology.py` so burst mode enters a pre-Tyrant setup when Tyrant is ready, pauses Hand of Gul'dan, casts Doomguard and Grimoire: Felguard when ready, builds to at least 2 shards, then casts Tyrant.
- Reset the DejaVu burst mode toggle when the Demonic Tyrant aura disappears.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors
- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-06-01

### Add Demonology Warlock burst cycle

- Reworked `WarlockDemonology.py` burst handling from the guide image into pre-portal setup, portal-window Hand of Gul'dan cycling, and steady-state fallback phases.
- Removed the temporary Dreadstalkers debug print from the rotation path.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-06-01

### Require Demon Core for Demonbolt

- Updated the Demonology Warlock Terminal rotation so `恶魔之箭` is only cast while `恶魔之核` has at least one stack.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-06-01

### Fix DejaVu global enable cell refresh

- Rewrote `DejaVu_Common/Enable.lua` so the `x=83,y=0` global enable cell initializes and refreshes every 0.1 seconds instead of being trapped behind a malformed comment line.

Verification:

- `luacheck DejaVu_Common` -> 0 errors; 3 pre-existing warnings in `AssistedCombat.lua` and `Burst.lua`
- `git diff --check` -> no whitespace errors

## 2026-06-01

### Fix Demonology Warlock rotation names

- Replaced mojibake spell, macro, buff, and UI strings in `WarlockDemonology.py` with normal Chinese names.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-06-01

### Add Demonology Warlock Terminal rotation

- Added a `WarlockDemonology` Terminal rotation for Demonology Warlock Soul Harvester play, following the provided guide's priorities around soul shard spending, Dreadstalkers, Implosion, Demonbolt, Tyrant, and Doomguard windows.
- Registered the new rotation in the Terminal rotation list.

Verification:

- `uv run python -m py_compile terminal\rotation\WarlockDemonology.py` -> passed
- `git diff --check` -> no whitespace errors

## 2026-05-31

### Add Demonology Warlock macros

- Added Demonology Warlock secure macro buttons for the spells registered in `Spell.lua`, mapped from `ALT-NUMPAD1` through `ALT-NUMPAD8` with `CTRL-F12` kept for reload.

Verification:

- `luacheck DejaVu_Warlock` -> 0 warnings / 0 errors
- `git diff --check` -> no whitespace errors

## 2026-05-31

### Add Demonology Warlock DejaVu plugin

- Added `DejaVu_Warlock` with a Demonology spec module that displays soul shards from `Enum.PowerType.SoulShards`, matching SenseiClassResourceBar's warlock resource source.
- Wired the loader to load the warlock class addon and documented the new class/spec module in the DejaVu overview.

Verification:

- `luacheck DejaVu_Warlock DejaVu_Loader` -> 0 warnings / 0 errors
- `git diff --check` -> no whitespace errors

## 2026-05-17

### Route item cooldowns through spell output

- Added `item` and `inventory` cooldown entry support to DejaVu spell cooldown output, so Terminal can keep using `ctx.spell_cooldown_ready()` for registered items.
- Changed Devourer Demon Hunter 鲁莽药水, 治疗石, 强效治疗药水, and 虚无之眼 registrations to use item/equipment cooldown sources instead of spell IDs.

Verification:

- `luacheck DejaVu_Spell DejaVu_DemonHunter` -> 0 errors; 6 pre-existing whitespace warnings in Devourer/Vengeance `Spec.lua`
- `git diff --check` -> no whitespace errors

## 2026-05-17

### Reset Devourer burst potion toggle out of combat

- Reset Devourer Demon Hunter `use_burst_potion` to off on `PLAYER_REGEN_ENABLED`, matching the existing lying-flat mode reset behavior.

Verification:

- `luacheck DejaVu_DemonHunter` -> 0 errors; 6 pre-existing whitespace warnings in Devourer/Vengeance `Spec.lua`

## 2026-05-17

### Default Demon Hunter burst potion toggle off

- Changed Devourer Demon Hunter `使用爆发药` to default off in DejaVu.
- Updated Terminal decoding so a missing or dim setting cell also means the burst potion toggle is off.

Verification:

- `uv run python -m py_compile terminal/rotation/DemonHunterDevourer.py` -> passed with escalated cache access
- `luacheck DejaVu_DemonHunter` -> 0 errors; 6 pre-existing whitespace warnings in Devourer/Vengeance `Spec.lua`

## 2026-05-17

### Add Demon Hunter burst potion toggle

- Added a Devourer Demon Hunter `使用爆发药` checkbox, mirrored through setting cell `x=61,y=12` / `ctx.setting.cell(6)`.
- Wired the Terminal Devourer rotation so closing the toggle skips the automatic `鲁莽药水` cast after `虚空变形`; the default remains enabled.

Verification:

- `uv run python -m py_compile terminal/rotation/DemonHunterDevourer.py` -> passed with escalated cache access
- `git diff --check` -> no whitespace errors
- `luacheck DejaVu_DemonHunter` -> not run: `luacheck` is not installed or not in PATH in this environment

## 2026-05-17

### Expand DejaVu checkbox click area

- Updated DejaVu panel checkbox rows so the whole rectangular control, including the on/off status text, toggles the bound setting.
- Kept the inner checkbox as a visual state indicator to avoid double toggles.

Verification:

- `git diff --check` -> no whitespace errors
- `luacheck DejaVu_DemonHunter DejaVu_Panel` -> not run: `luacheck` is not installed or not in PATH in this environment

## 2026-05-17

### Fix Beast Mastery Hunter Chinese spell names

- Replaced mojibake spell names in Beast Mastery Hunter `Macro.lua`, `Spell.lua`, and Terminal `HunterBeastMastery.py` with real Chinese spell names.
- Kept macro titles, DejaVu cooldown spell names, and Terminal rotation checks aligned for Counter Shot, Tranquilizing Shot, and assisted-combat output.

Verification:

- `uv run python -m py_compile terminal\rotation\HunterBeastMastery.py` -> passed with escalated cache access
- `git diff --check` -> no whitespace errors
- `rg "鍙|鏉|鐙|瀹|閸|鐎|閻|妞|鎬|寤|姝|楠|褰" DejaVu/DejaVu_Hunter/BeastMastery Terminal/terminal/rotation/HunterBeastMastery.py` -> no matches
- `luacheck DejaVu_Hunter` -> not run: `luacheck` is not installed or not in PATH in this environment

## 2026-05-17

### Add Beast Mastery Hunter Terminal rotation

- Added a Terminal Beast Mastery Hunter rotation that handles Counter Shot interrupts, Tranquilizing Shot enemy dispels, and target output through the in-game assisted-combat recommendation.
- Registered the rotation in the Terminal rotation list.
- Repaired and expanded Beast Mastery Hunter macro bindings for target output, focus/target Counter Shot, and focus/target Tranquilizing Shot.

Verification:

- `uv run python -m py_compile terminal\rotation\HunterBeastMastery.py` -> passed with escalated cache access
- `git diff --check` -> no whitespace errors
- `luacheck DejaVu_Hunter` -> not run: `luacheck` is not installed or not in PATH in this environment

## 2026-04-27

### Refresh DejaVu context and agent docs

- Updated DejaVu context docs to match the current class/spec directory structure, loader order, matrix facts, and first-party luacheck target list.
- Replaced old flattened spec paths and stale absolute skill paths in DejaVu-related `.agents` skill docs.
- Removed the stale `DejaVu.Outdated` reference from the archived DejaVu context entry.

Verification:

- `rg -n "DejaVu_DeathKnightBlood|DejaVu_DruidGuardian|DejaVu_DruidRestoration|E:\\Documents\\GitHub\\MIDNIGHT|DejaVu\\.Outdated" .context .agents` -> no matches
- `git diff --check` -> no whitespace errors

## 2026-04-15

### Build `dejavu-coder` skill

- Added the repo-local skill at `.agents/skills/dejavu-coder` for MIDNIGHT DejaVu planning, coding, review, and commit workflow.
- Added a DejaVu context router and four bundled role prompts: `plan writer`, `coder`, `review`, and `commiter`.
- Established repo-root `changelog.md` for future task handoff entries.

Verification:

- `py -3 C:\Users\liantian\.codex\skills\.system\skill-creator\scripts\quick_validate.py .agents\skills\dejavu-coder` -> `Skill is valid!`
- `git status --short` -> only expected additions before final commit: `?? .agents/` and `?? changelog.md`
- Forward-test -> compared a baseline subagent response against a `$dejavu-coder`-guided subagent response; the skill-guided run added `.context` loading, `secret values` handling, DejaVu scope control, and `luacheck`/commit workflow guidance

## 2026-05-17

### Add DejaVu Beast Mastery Hunter plugin

- Added `DejaVu_Hunter` as a load-on-demand DejaVu class plugin and wired hunter loading through `DejaVu_Loader`.
- Added Beast Mastery files for global range defaults, focus/frenzy display cells, cooldown spell registration, interrupt-mode config display, and a minimal reload macro binding.
- Added `UnitPowerMax` to the DejaVu luacheck read globals for the hunter focus display path.

Verification:

- `luacheck DejaVu_Common DejaVu_Core DejaVu_Matrix DejaVu_Panel DejaVu_Player DejaVu_Party DejaVu_Enemy DejaVu_Spell DejaVu_Aura DejaVu_DeathKnight DejaVu_DemonHunter DejaVu_Druid DejaVu_Priest DejaVu_Hunter` -> not run: `luacheck` is not installed or not in PATH in this environment
- `git diff --check` -> no whitespace errors
