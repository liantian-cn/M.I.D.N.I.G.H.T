# Changelog

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
