---
name: building-full-rotation
description: Use when building or rewriting a complete MIDNIGHT rotation from scratch for both DejaVu and Terminal, especially when the task must produce a full DejaVu spec plugin plus a Terminal rotation script, and only after the user has supplied a detailed skill list, macro requirements, settings, slot mappings, rotation rules, default values, and acceptance examples.
---

# Building Full Rotation

## Overview

Use this skill for MIDNIGHT tasks that create or rewrite an entire spec rotation, not just mirrored config. A complete output includes the DejaVu plugin files and the Terminal rotation file that consumes the same business contract.

This is an interactive gatekeeper skill. If the user has not supplied the full business spec, do not start implementation. Stop, list the missing sections, and return the fixed Markdown template from [references/full-rotation-input-template.md](./references/full-rotation-input-template.md).

## Hard Gates

- Stay on `draft`.
- Run `git status --short` before coding.
- Create a `backup` commit before any file edits. If the tree is clean, an empty `backup` commit is acceptable.
- Use PowerShell for shell commands.
- Use `luacheck` for Lua verification.
- Use `uv run` for Python commands.
- Do not begin implementation until every required input section is present.
- Do not infer missing business logic from class knowledge, common WoW practice, or existing examples.
- If any required section is missing, respond with:
  - a flat list of missing sections
  - the full Markdown template
  - no code edits
- Always build both sides together:
  - `DejaVu/DejaVu_<Class>/<Spec>/Global.lua`
  - `DejaVu/DejaVu_<Class>/<Spec>/Spec.lua`
  - `DejaVu/DejaVu_<Class>/<Spec>/Spell.lua`
  - `DejaVu/DejaVu_<Class>/<Spec>/Config.lua`
  - `DejaVu/DejaVu_<Class>/<Spec>/Macro.lua`
  - `Terminal/terminal/rotation/<Spec>.py`
- One class/spec can have only one DejaVu plugin.
- Terminal may have multiple rotations, but this skill still writes exactly one target rotation file per task.
- If the DejaVu plugin class is wrong, disable the addon. If the class is correct but spec is wrong, return immediately.
- Keep logic business-first. Stack `if` blocks when they make the rotation easier to read as a combat policy.
- Do not rewrite existing repo style into abstract helpers unless the user explicitly asked for that change.

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

Study these examples before implementation:

- `DejaVu/DejaVu_Druid/Restoration`
- `DejaVu/DejaVu_Druid/Guardian`
- `DejaVu/DejaVu_DeathKnight/Blood`
- `DejaVu/DejaVu_Priest/Discipline`
- `DejaVu/DejaVu_DemonHunter/Devourer`
- `Terminal/terminal/rotation/DruidRestoration.py`
- `Terminal/terminal/rotation/DruidGuardian.py`
- `Terminal/terminal/rotation/DeathKnightBlood.py`
- `Terminal/terminal/rotation/base.py`

Then load:

- [references/full-rotation-input-template.md](./references/full-rotation-input-template.md)
- [references/full-rotation-patterns.md](./references/full-rotation-patterns.md)

## Required Input

All of these are mandatory. Missing any one means stop and return the template.

- spec base info
- skill list
- spell registration split
- macro requirements
- settings
- `spec/setting` slot mapping
- encode/decode rules
- target selection rules
- guard and idle rules
- movement and form limits
- rotation phase order
- rotation rules
- priority and trigger conditions
- buff/debuff/aura rules
- derived business formulas
- defaults
- acceptance examples

## Workflow

## 1. Validate Input First

- Compare the user input against every section in [references/full-rotation-input-template.md](./references/full-rotation-input-template.md).
- If any section is incomplete:
  - name the missing sections
  - return the full template
  - stop
- Do not partially implement.

## 2. Freeze the Contract

- Convert the user input into one authoritative mirrored contract:
  - DejaVu output files
  - Terminal rotation file
  - skill registration list
  - macro title list
  - `spec/setting` slot map
  - defaults
  - phase order
- Do not start code until the contract is coherent end-to-end.

## 3. Call Existing Skills

- **REQUIRED REPO SKILL:** Use `$adding-rotation-config` at `.agents\skills\adding-rotation-config` once the input is complete.
- Use it to lock:
  - mirrored `spec/setting` slots
  - DejaVu `Config.lua` and `Spec.lua` encoding rules
  - `Spell.lua` cooldown and charge registration
  - `Macro.lua` and `macroTable` alignment
- If another existing skill is relevant, call it explicitly by path. Do not assume it is auto-loaded.

## 4. Build the DejaVu Side

- `Global.lua`
  - class/spec guard
  - default ranges if needed
- `Spell.lua`
  - every spell Terminal reads
  - split between `cooldownSpells` and `chargeSpells`
- `Spec.lua`
  - spec-only attributes in `y=13`
- `Config.lua`
  - user settings in `y=12`
- `Macro.lua`
  - macro bindings that Terminal will call by title
- `.toc`
  - ensure the file order matches the repo pattern for new plugins

## 5. Build the Terminal Side

- Edit only `Terminal/terminal/rotation/<Spec>.py`.
- Subclass `BaseRotation`.
- Mirror every DejaVu macro title in `self.macroTable`.
- Decode all `spec` and `setting` cells with explicit defaults.
- Read shared protocol fields separately:
  - `ctx.enable`
  - `ctx.delay`
  - `ctx.burst_time`
  - `ctx.combat_time`
  - `ctx.interrupt_blacklist`
  - `ctx.dispel_blacklist`
  - `ctx.spell_queue_window`
- Implement the full guard chain, target selection, phase order, business formulas, and fill actions described by the user input.

## 6. Keep the Rotation Readable as Policy

- The reader must be able to answer:
  - why the rotation idles
  - how it picks a main target
  - what counts as opener, burst, interrupt, survival, filler
  - which settings and spec cells influence each decision
- Prefer explicit sections and stacked `if` chains over clever indirection.

## 7. Verify

- Run the relevant `luacheck` command from `DejaVu/`.
- Run at least a syntax-level Python check with:
  - `uv run python -m py_compile Terminal/terminal/rotation/<Spec>.py`
- If protocol meaning changed, update `.context/` in the same task.
- Re-read the final diff and confirm:
  - macro titles align
  - cooldown and charge registration align
  - `spec/setting` indices align
  - defaults align
  - the Terminal guard chain matches the user rules
  - the rotation phases match the user rules

## Common Mistakes

- Starting implementation from partial notes instead of the complete template.
- Letting DejaVu and Terminal drift on slot indices or mode thresholds.
- Writing `Macro.lua` keys that do not appear in `self.macroTable`.
- Forgetting to classify charge-based skills in `Spell.lua`.
- Hiding business rules inside generic helpers so the rotation no longer reads like combat policy.
- Reusing old example formulas without the user explicitly supplying them.
- Treating acceptance examples as optional. They are required because they prove the intended behavior.

## Red Flags

- "I know this class, I can fill the missing rules."
- "The examples imply what the user probably wants."
- "I can start the plugin now and ask about the formulas later."
- "The DejaVu side is enough; Terminal can be inferred."
- "The target model can be copied from another spec."
- "The user did not give acceptance examples, but the rotation is obvious."

All of these mean stop and ask the user to fill the missing template sections first.
