---
name: adding-rotation-config
description: Use when adding or extending MIDNIGHT DejaVu and Terminal rotation configuration that must stay mirrored across a DejaVu spec plugin and Terminal/terminal/rotation script, especially when the task mentions spec cells, setting cells, macros, cooldown or charge spell registration, brightness or color decoding, or shared Lua/Python rotation behavior.
---

# Adding Rotation Config

## Overview

Use this skill for MIDNIGHT tasks that add or expand mirrored rotation configuration between a DejaVu class/spec directory such as `DejaVu/DejaVu_Druid/Restoration` and `Terminal/terminal/rotation/<Spec>.py`.

Treat `spec` and `setting` as protocol cells, not local implementation details. DejaVu writes brightness or color into cells; Terminal decodes those same cells back into business values.

## Hard Gates

- Stay on `draft`.
- Run `git status --short` before coding.
- Create a `backup` commit before any file edits. If the tree is clean, an empty `backup` commit is acceptable.
- Use PowerShell for shell commands.
- Use `luacheck` for Lua verification.
- Use `uv run` for Python commands.
- If the task is a rotation script task, only edit `Terminal/terminal/rotation/`.
- If the task is a DejaVu plugin task, only edit the target class/spec directory under `DejaVu/`, for example `DejaVu/DejaVu_DeathKnight/Blood/`.
- Only touch `.context/` or decode-layer files if the protocol meaning really changes.
- One class/spec can have only one DejaVu plugin. Multiple Terminal rotation scripts are allowed, but they share the same DejaVu-side settings.
- If the DejaVu plugin class is wrong, disable the addon. If the class is correct but spec is wrong, return immediately.
- Keep logic business-first. Stack `if` blocks when that matches the rotation intent. Do not collapse repeated logic just to look cleaner.
- If a needed macro is missing, add it. If an existing macro text looks wrong, stop at a warning and tell the user to fix the text manually.

## Required Reading

Always read:

- `AGENTS.md`
- `.context/README.md`
- `.context/Common/01_shared_protocol.md`
- `.context/Common/03_color_conventions.md`
- `.context/DejaVu/README.md`
- `.context/Terminal/README.md`
- `.context/DejaVu/05_dejavu_quick_reference.md`
- `.context/DejaVu/06_wow_api_query_playbook.md`
- `.context/DejaVu/08_display_first_patterns.md`
- `.context/DejaVu/09_personal_style_cell_event_comments.md`
- `.context/Terminal/01_terminal_decode_contract.md`
- `.context/Terminal/21_terminal_architecture.md`
- `.context/Terminal/22_terminal_dev_rules.md`

Study these repo examples before writing code:

- `DejaVu/DejaVu_Druid/Restoration`
- `DejaVu/DejaVu_Druid/Guardian`
- `DejaVu/DejaVu_DeathKnight/Blood`
- `DejaVu/DejaVu_Priest/Discipline`
- `DejaVu/DejaVu_DemonHunter/Devourer`
- `Terminal/terminal/rotation/DruidRestoration.py`
- `Terminal/terminal/rotation/DruidGuardian.py`
- `Terminal/terminal/rotation/DeathKnightBlood.py`

Then load [references/rotation-config-patterns.md](./references/rotation-config-patterns.md) for the mirrored file layout, cell map, and encode/decode patterns.

## Quick Reference

| Area | DejaVu cells | Terminal access | Notes |
| --- | --- | --- | --- |
| `spec` | `x=55..68`, `y=13`, 14 `Cell` slots | `ctx.spec.cell(index)` | Spec-only business attributes such as combo points or ready runes |
| `setting` | `x=55..68`, `y=12`, 14 `Cell` slots | `ctx.setting.cell(index)` | User-tunable settings mirrored from `Config.lua` |

- Do not use `MegaCell` or `BadgeCell` for `spec` or `setting`.
- `spec` and `setting` are the same protocol shape. If one area is full, you may borrow slots from the other area, but document the mapping clearly.
- `burst_time`, `delay`, `enable`, `interrupt_blacklist`, and `dispel_blacklist` are shared protocol fields and do not consume `setting` slots.
- Keep one authoritative index map. Once a cell index is assigned, mirror that exact index on both sides.

## Workflow

## 1. Preflight

- Confirm the target spec and exact write scope first.
- If the user asked for a new spec plugin, create or update only the relevant class/spec directory under `DejaVu/`.
- If the user asked for a new rotation, create or update only `Terminal/terminal/rotation/<Spec>.py`.
- If the task mentions spells, charges, or WoW API uncertainty, query `wow-api-mcp` first, then fall back to wiki guidance from `.context/DejaVu/06_wow_api_query_playbook.md`.

## 2. Freeze the Cell Map Before Coding

- Write down the intended `spec` and `setting` slot map before implementing.
- For each slot, define:
  - cell index
  - DejaVu coordinate
  - config key or business attribute name
  - DejaVu encoding rule
  - Terminal decode rule
  - default value
- Do not start coding until the mirrored map is complete enough that Lua and Python will agree.

## 3. Update the DejaVu Plugin

- `Global.lua`
  - enforce class/spec guard
  - set `DejaVu.RangedRange` and `DejaVu.MeleeRange` if the spec examples do
- `Spell.lua`
  - enumerate every skill the rotation will read through Terminal
  - add charge-based skills to `DejaVu.chargeSpells`
  - add non-charge skills to `DejaVu.cooldownSpells`
- `Spec.lua`
  - use `y=13`
  - create only plain `Cell` instances
  - follow the local comment style for cell creation and update functions
  - convert business state into brightness or color that Terminal can decode back deterministically
- `Config.lua`
  - use `y=12`
  - add each setting as its own `do ... end` block
  - add `ConfigRows` entry, callback registration, and initial callback execution
  - keep comments and ordering aligned with existing examples
- `Macro.lua`
  - add needed macro bindings
  - keep macro titles stable because Terminal uses those titles as `macroTable` keys
- `.toc`
  - if this is a new plugin, list files in the existing order:
    - `Global.lua`
    - `Spec.lua`
    - `Spell.lua`
    - `Config.lua`
    - `Macro.lua`

## 4. Update the Terminal Rotation

- Edit only `Terminal/terminal/rotation/<Spec>.py`.
- Subclass `BaseRotation` and keep the existing repo style.
- Mirror every DejaVu macro title in `self.macroTable`.
- Read `ctx.spec.cell(index)` and `ctx.setting.cell(index)` using the same slot map frozen earlier.
- Decode brightness or color back into business values with explicit default fallbacks.
- Keep shared protocol fields separate:
  - `ctx.enable`
  - `ctx.delay`
  - `ctx.burst_time`
  - `ctx.interrupt_blacklist`
  - `ctx.dispel_blacklist`
- Use `Context` or `decoded_data` only through the existing `Context` APIs. Do not redefine protocol meaning from inside `rotation/`.

## 5. Encode and Decode Carefully

- Use grayscale or color intentionally.
- If encoding with grayscale, define the exact math and inverse math.
- If encoding with 2-state or 3-state combo logic, define explicit threshold bands on the Python side.
- Prefer stable, obvious mappings over dense encodings.
- If a value is not deterministic to decode back, redesign the mapping before continuing.

## 6. Verify

- For DejaVu changes, run `luacheck` from `DejaVu/`.
- For Terminal rotation changes, run at least a syntax-level check with `uv run python -m py_compile Terminal/terminal/rotation/<Spec>.py`.
- If you changed protocol meaning, update `.context/` in the same task and run the broader verification that task requires.
- Re-read the diff and confirm:
  - macro titles match on both sides
  - charge spells were registered when needed
  - class/spec guard exists
  - cell indices line up
  - defaults line up

## Common Mistakes

- Adding a skill in `Spell.lua` but forgetting `chargeSpells` for charge-based logic.
- Writing a DejaVu macro but forgetting to mirror the same title in `self.macroTable`.
- Reusing a `setting` index on the Lua side without updating the Python decode order.
- Encoding with `value * 10 / 255` or `value * 20 / 255` and then decoding as raw `mean`.
- Touching `Terminal/context` or `pixelcalc` even though the task only asked for a new rotation config.
- Using `BadgeCell` or `MegaCell` in the `spec` or `setting` areas.
- Replacing business-first `if` chains with abstract helpers that hide the actual rotation intent.
- Assuming the macro text must equal the spell name. If the macro key is missing, add it. If the macro text is suspicious, warn the user instead of silently rewriting it.

## Red Flags

- "I can just pick any free cell and remember it later."
- "The DejaVu side is enough; Terminal can infer the rest."
- "This charge spell is basically a cooldown spell."
- "The macro titles do not need to match because the hotkey is the same."
- "The plugin can stay enabled on the wrong class; it will just do nothing."
- "I can refactor the existing rotation style while I am here."

All of these mean the mirrored contract is about to drift. Stop and realign the mapping before coding further.
