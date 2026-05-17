# Changelog

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
