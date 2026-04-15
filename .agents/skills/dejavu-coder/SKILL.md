---
name: dejavu-coder
description: Use when working on MIDNIGHT DejaVu tasks in this repository, especially WoW Lua changes that must follow the DejaVu context docs, secret-values safety rules, display-first patterns, project git workflow, luacheck verification, and the bundled role prompts for planning, coding, review, and commit handoff.
---

# DejaVu Coder

## Overview

Use this skill for `E:\Documents\GitHub\MIDNIGHT` tasks that are scoped to `DejaVu/` and its shared `.context` docs. This skill does not duplicate the project knowledge base; it tells you exactly which docs to load, which repo rules to enforce, and how to run the four-role workflow: `plan writer`, `coder`, `review`, `commiter`.

## Hard Gates

- Work inside `DejaVu/` unless the task explicitly requires shared `.context/Common/` updates.
- Do not modify `Terminal/` unless the user explicitly asks for cross-project work.
- Keep the git branch on `draft`. If it is not `draft`, switch before editing.
- Read `git status --short` before starting code work.
- Make a `backup` commit before any file modification. If the tree is clean, an empty `backup` commit is acceptable.
- Use PowerShell for shell commands.
- Run `luacheck` for Lua verification.
- Treat uncertain combat values as `secret values` until verified.
- Do not add automation that makes combat decisions for the player.

## Required Reading

Always read these before planning or coding:

- `AGENTS.md`
- `.context/README.md`
- `.context/Common/01_shared_protocol.md`
- `.context/Common/03_color_conventions.md`
- `.context/DejaVu/README.md`
- `.context/DejaVu/00_project_overview.md`
- `.context/DejaVu/04_dev_rules.md`

Load additional references from [dejavu-context-map.md](./references/dejavu-context-map.md) based on the task:

- `00_secret_values.md` for combat-state data
- `01_api_migration.md` for API replacements
- `02_ui_events.md` for event, frame, widget, and layout work
- `03_architecture_and_data.md` for module placement and SavedVariables
- `05_dejavu_quick_reference.md` for fast routing
- `06_wow_api_query_playbook.md` for `wow-api-mcp` and wiki workflow
- `07_secret_values_api_checklist.md` for high-risk APIs
- `08_display_first_patterns.md` for display-first implementations
- `09_personal_style_cell_event_comments.md` for comment and event ordering style

## Workflow

### 1. Preflight

- Confirm the repo root is `E:\Documents\GitHub\MIDNIGHT`.
- Confirm the task belongs to `DejaVu/`.
- Check `git branch --show-current` and `git status --short`.
- Create the required `backup` commit before any file edits or new files.
- Decide whether the task needs only text planning or full implementation.

### 2. Plan Writer

Use [plan-writer.md](./references/agents/plan-writer.md) when the task needs a plan.

- This role has a hard gate: the current session must already be in platform Plan Mode.
- If Plan Mode is not active, stop and tell the user how to re-enter Plan Mode.
- Do not simulate execution. Produce only a complete `<proposed_plan>` block.
- A finished plan must be approved before code work starts.

### 3. Coder

Use [coder.md](./references/agents/coder.md) to execute an approved plan.

- Edit only the minimum DejaVu area required by the task.
- Use `wow-api-mcp` first for WoW API facts.
- If an API or field might be combat-sensitive, verify against the wiki flow and keep the implementation conservative.
- Prefer display-first solutions over Lua-side derived logic when working with combat data.
- Preserve the user’s existing structure unless the requested change requires more.

### 4. Review

Use [review.md](./references/agents/review.md) after the coder finishes.

- Review findings first. Prioritize incorrect behavior, missed requirements, regressions, secret-values misuse, and repo-rule violations.
- Small, local fixes may be applied directly by the reviewer.
- Large fixes, requirement mismatches, or structural rework must go back to the coder.
- Do not proceed to commit while review findings remain open.

### 5. Commiter

Use [commiter.md](./references/agents/commiter.md) only after review is clear.

- Update the repo-root `changelog.md`.
- Record task date, summary, touched areas, and verification evidence.
- Create a final task commit.
- Do not amend previous commits unless the user explicitly asks.

## Role Files

The bundled role prompts live here:

- `references/agents/plan-writer.md`
- `references/agents/coder.md`
- `references/agents/review.md`
- `references/agents/commiter.md`

When dispatching those roles on Codex, read the prompt file, wrap it as task instructions, and send it to a spawned agent. If multi-agent support is unavailable, follow the same role contract inline in the main session.

## Verification

Before claiming completion:

- Run the relevant `luacheck` command from `DejaVu/` when Lua files changed.
- Run any task-specific verification required by the approved plan.
- Re-read the final diff for cross-project leakage and style-rule violations.
- Confirm `changelog.md` was updated before the final task commit.

## Invocation

Use this skill explicitly by path:

`Use $dejavu-coder at E:\Documents\GitHub\MIDNIGHT\.agents\skills\dejavu-coder ...`
