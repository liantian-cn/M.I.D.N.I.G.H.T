# Changelog

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
