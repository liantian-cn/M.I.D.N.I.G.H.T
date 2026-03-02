# Rules

## Global Rules

1. Shell: On Windows, use PowerShell as the default shell.
2. Python: Use `uv` as the package manager; run Python commands with `uv run`.
3. Lua: Use `D:\luacheck\luacheck.exe` for Lua checking.
4. Before starting any coding task, if the current git working tree has uncommitted changes, create one backup commit first. Apply this to every task.

## Project Rules

1. Keep protocol documentation ahead of implementation changes.
2. Treat `docs/protocol.md`, `docs/matrix_spec.md`, and `docs/cell_spec.md` as the source of truth for DejaVu and Terminal alignment.
3. During scaffold stages, do not implement gameplay automation or decision logic.
4. Mark protocol-facing changes as `draft` or `stable` explicitly in docs.
5. Keep commits small and reviewable; separate doc updates from behavior changes when possible.
6. Preserve compliance boundaries and risk disclosures in `README.md` and `SECURITY.md`.
