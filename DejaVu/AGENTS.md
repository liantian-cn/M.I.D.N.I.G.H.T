# Repository Guidelines

## Project Structure & Module Organization
`DejaVu.toc` defines load order for the addon. Core Lua code is split by responsibility: `01_utils/` for helpers, `02_core/` for shared state and events, `03_matrix/` for matrix and cell UI, `04_panel/` for settings UI, `05_slots/` for reusable slot behaviors, and `06_spec/` for role/spec-specific wiring. `100_main.lua` is the entry point. `Libs/` stores embedded dependencies, and `fonts/` stores shipped font assets.

## Build, Test, and Development Commands
- `git status --short` — check for local changes before editing.
- `D:\luacheck\luacheck.exe 100_main.lua 01_utils 02_core 03_matrix 04_panel 05_slots 06_spec` — run Lua linting.
- `uv run <script>.py` — run Python helpers if you add or maintain any; do not call `python` directly.
- In WoW, enable the addon and use the files wired in `DejaVu.toc` for smoke testing. Current debug hooks include `05_slots/99_test.lua`, `06_spec/99_test.lua`, and `999_test.lua`.

## Coding Style & Naming Conventions
Use Lua 5.1 / WoW API-compatible code. Follow the existing layout: module files are numerically prefixed (`00_init.lua`, `01_frame.lua`) to make load order obvious. Use 4-space indentation, `local` by default, and `PascalCase` for constructor-like objects (`BadgeCell`, `MegaCell`) with `snake_case` for file names and config keys. Keep modules focused and update `DejaVu.toc` when adding or reordering files.

## Testing Guidelines
There is no formal automated test framework yet. Validate changes with `luacheck` first, then perform an in-game smoke test for the affected module. Keep temporary test code in the existing `99_test.lua` pattern and remove or disable one-off probes before merging.

## Commit & Pull Request Guidelines
Recent history contains very short messages such as `Update 05_char_cell.lua` and `Create 使用git实现快照.md`. Prefer clearer, reviewable commits in imperative form, for example `panel: add slider factory` or `slots: split cooldown and charge cells`. Before starting work, if the tree is dirty, create one backup commit first. PRs should explain player-visible impact, list touched directories, and include screenshots or short recordings for panel or matrix UI changes.

## Workflow Notes
Use PowerShell on Windows. Keep changes small and scoped. Preserve `Warning.md` risk language if that file is present, and avoid mixing unrelated refactors with feature work.
