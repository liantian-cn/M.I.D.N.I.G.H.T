# DejaVu 文档入口

这里是根 `.context/DejaVu/` 下的 DejaVu 专属文档入口。

共享协议和颜色已经迁到根 `.context/Common/`；这里主要保留 WoW 插件侧的结构、API 风险和实现边界。

## 建议阅读顺序

1. `.context/Common/01_shared_protocol.md`
2. `.context/Common/03_color_conventions.md`
3. `00_project_overview.md`
4. 遇到战斗相关判断时优先读 `00_secret_values.md`
5. 需要具体开发细节时，再按下面主题继续读

## 先看哪里

- 碰到血量、能量、冷却、光环、施法、威胁、战斗状态：先看 `00_secret_values.md`
- 想确认某个 API 现在还在不在、怎么迁移：看 `01_api_migration.md`
- 想写事件、Frame、Widget、布局、Scroll、Mixin：看 `02_ui_events.md`
- 想整理模块、SavedVariables、库、版本兼容：看 `03_architecture_and_data.md`
- 想对齐项目编码习惯、注释、检查流程：看 `04_dev_rules.md`
- 想直接看本项目最常见的开发场景：看 `05_dejavu_quick_reference.md`
- 想学会怎么查 WoW 12.x API：看 `06_wow_api_query_playbook.md`
- 想快速避开高风险 secret API：看 `07_secret_values_api_checklist.md`
- 想看“少计算、多显示”的界面模式：看 `08_display_first_patterns.md`
- 想对齐当前个人的 cell / update / event 注释与结构风格：看 `09_personal_style_cell_event_comments.md`

## 推荐查询流程

1. 先用 `wow-api-mcp` 查 API 名称、参数、返回结构、是否废弃。
2. 如果问题是“这个返回值是不是秘密值”“这个字段战斗中能不能判断”，继续查 `warcraft.wiki.gg`。
3. 只要判断不清，就先按“秘密值”处理，写保守代码。

## 现在最重要的变化

WoW 12.0 之后最大的坑不是“函数改名”，而是 `secret values`。

很多 API 不是直接没了，而是还能返回值，但这些值在插件 Lua 里可能不能比较、不能算术、不能拿来做 `if` 判断。

所以这套文档把 `00_secret_values.md` 放在最前面。

## 使用原则

- 文档用于快速定方向，最终 API 事实以最新 `wow-api-mcp` + `warcraft.wiki.gg` 为准。
- 只要涉及战斗信息，优先考虑 secret values 风险。
- 本项目仍以 WoW Lua 5.1 兼容写法为基础。
- 协议、颜色、矩阵语义先看 `.context/Common/01_shared_protocol.md` 和 `.context/Common/03_color_conventions.md`。
