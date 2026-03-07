# DejaVu 工作指引

先看 `.context/README.md`，再动手。

1. API 问题先用 `wow-api-mcp`。不要凭旧版本记忆写代码。
2. 如果 `wow-api-mcp` 只能看到签名，不能判断返回值或字段是不是 `secret values`，继续用 fetch / extract 查 `https://warcraft.wiki.gg/`。
3. 只要问题涉及血量、能量、冷却、光环、施法、威胁、单位身份、战斗中判断，先读 `.context/00_secret_values.md`。
4. 查 12.x API 废弃、替代、迁移，读 `.context/01_api_migration.md`。
5. 查事件、Frame、Widget、模板、布局，读 `.context/02_ui_events.md`。
6. 查插件结构、存档、库、开发约定，读 `.context/03_architecture_and_data.md` 与 `.context/04_dev_rules.md`。

开发规则：

- Windows 默认用 PowerShell。
- Python 一律用 `uv run`。
- Lua 按 5.1 / WoW API 兼容标准写。
- Lua 检查用 `D:\luacheck\luacheck.exe 100_main.lua 01_utils 02_core 03_matrix 04_panel 05_slots 06_spec`。
- 改代码前先看 `git status --short`；如果工作区有未提交改动，先做一次备份提交。
- `local addonName, addonTable = ...` 之后，马上做当前文件会用到的全局函数本地化，不要拖到后面。
- 禁止用 `_` 当返回值占位符，避免被 secret values 污染后引发整片代码崩溃。
- 如果多返回值里只想取后面的值，优先用 `select(...)`，不要靠 `_` 占位。
- 不实现自动战斗或代替玩家决策的逻辑。

关于 secret values：

- 判断不清时，先按“它是秘密值”处理。
- 优先把秘密值直接传给官方明确支持的显示接口，不要在 Lua 里比较、计算或分支判断。
