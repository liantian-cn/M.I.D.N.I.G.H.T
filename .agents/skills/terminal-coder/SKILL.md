---
name: terminal-coder
description: Use when working on MIDNIGHT Terminal tasks in this repository, especially Python, PySide6, pixel decoding, Context, rotation, worker scheduling, keyboard sending, Terminal docs, and Terminal-only agent workflow updates.
---

# Terminal Coder

## Overview

Use this skill for MIDNIGHT tasks scoped to `Terminal/`, `.context/Terminal/`, or Terminal-only `.agents` entries.

The code is the source of truth. `.context/Terminal/` is the compact map that keeps agents from rediscovering the same boundaries.

## Hard Gates

- Work in `Terminal/` unless the task explicitly asks for shared `.context/Common/` updates.
- Do not modify `DejaVu/` unless the user explicitly asks for a cross-project task.
- Keep git on the lowercase `draft` branch.
- Read `git status --short` before work.
- Create a `backup` commit before any file modification. If the tree is clean, an empty `backup` commit is acceptable.
- Use PowerShell on Windows.
- Run Python commands from `Terminal/` through `uv run`.
- Do not optimize unrelated user code.
- When the user says to assume code is correct, update docs or workflow files to match code; do not rewrite runtime code.

## Required Reading

Always read:

- `AGENTS.md`
- `.context/README.md`
- `.context/Common/01_shared_protocol.md`
- `.context/Common/03_color_conventions.md`
- `.context/Terminal/README.md`
- `.context/Terminal/00_project_overview.md`
- `.context/Terminal/22_terminal_dev_rules.md`

Load task-specific docs:

- `.context/Terminal/01_terminal_decode_contract.md` for `pixelcalc`, `decoded_data`, `Context`, `Unit`, `Spell`, `Aura`, `spec`, or `setting`.
- `.context/Terminal/02_runtime_pipeline.md` for capture, decode, rotation workers, queueing, wait behavior, hot reload, and failure behavior.
- `.context/Terminal/20_terminal_scope.md` for project boundary questions.
- `.context/Terminal/21_terminal_architecture.md` for package placement and layer boundaries.

## Workflow

### 1. Preflight

- Confirm the selected work direction is Terminal.
- Check branch and status.
- Make the required `backup` commit before editing.
- Identify whether the task is documentation-only, runtime code, tests, or `.agents` workflow.

### 2. Route the Change

- Screenshot, monitor, template bounds: `terminal/capture/` and `terminal/workers/capture_worker.py`.
- Matrix slicing, colors, title lookup, extraction fields: `terminal/pixelcalc/`.
- Rotation-facing accessors: `terminal/context/`.
- Concrete combat policy: `terminal/rotation/`.
- Main window scheduling, logs, stale state, start / stop: `terminal/ui/main_window.py`.
- Background execution objects: `terminal/workers/`.
- Game window enumeration and key sending: `terminal/keyboard.py`.
- UI tab display: `terminal/ui/tabs/`.
- Experimental probes: `notes/`, not formal runtime.

### 3. Keep Boundaries Stable

- `capture` finds and captures pixels; it does not define business meaning.
- `pixelcalc` decodes protocol; it does not decide combat actions.
- `context` wraps decoded data; it does not mutate protocol meaning.
- `rotation` returns `cast`, `wait`, or `idle`; it does not touch Qt widgets.
- `workers` execute background work; they do not edit UI controls directly.
- `ui` owns scheduling and display; it should not duplicate decoder logic.

### 4. Verification

Use the smallest command that proves the touched area:

- Start app manually when needed: `uv run .\main.py`
- All tests: `uv run python -m pytest`
- Targeted test: `uv run python -m pytest tests\path\to_test.py`
- Syntax check one file: `uv run python -m py_compile terminal\rotation\<Name>.py`

If only `.context` or `.agents` Markdown/YAML changed, inspect the diff and run no Python command unless the task needs it.

## Completion

- Re-read the diff for cross-project leakage.
- Confirm `.context/Terminal/` still matches current code facts.
- Create the final task commit with a concise message.
- In the final response, state what changed and what verification was or was not run.
