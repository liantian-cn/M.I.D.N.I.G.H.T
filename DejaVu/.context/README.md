# DejaVu 文档入口

这套文档是把 `copilot_doc` 里的资料重新按“开发时怎么查”整理后的中文版本。目标不是逐段翻译，而是让你遇到问题时更快定位。

## 先看哪里

- 碰到血量、能量、冷却、光环、施法、威胁、单位名字、战斗状态：先看 `00_secret_values.md`
- 想确认某个 API 现在还在不在、怎么迁移：看 `01_api_migration.md`
- 想写事件、Frame、Widget、布局、Scroll、Mixin：看 `02_ui_events.md`
- 想整理模块、SavedVariables、库、版本兼容：看 `03_architecture_and_data.md`
- 想对齐项目编码习惯、注释、检查流程：看 `04_dev_rules.md`
- 想直接看本项目最常见的开发场景：看 `05_dejavu_quick_reference.md`

## 推荐查询流程

1. 先用 `wow-api-mcp` 查 API 名称、参数、返回结构、是否废弃。
2. 如果问题是“这个返回值是不是秘密值”“这个字段战斗中能不能判断”，继续查 `warcraft.wiki.gg`。
3. 只要判断不清，就先按“秘密值”处理，写保守代码。

## 现在最重要的变化

WoW 12.0 之后最大的坑不是“函数改名”，而是 **secret values**。

很多 API 不是直接没了，而是还能返回值，但这些值在插件 Lua 里可能不能比较、不能算术、不能拿来做 if 判断。也就是说：

- 旧代码表面上还能调用 API
- 真正出问题是在“你怎么使用返回值”这一步

所以这套文档把 `00_secret_values.md` 放在最前面。

## 原资料范围

已整理的原始资料包括：

- WoW API 参考、事件系统、UI 框架、插件结构、通用模式、存档、Blizzard UI 示例、社区模式、库指南、进阶技巧
- WoW 12 迁移、兼容、更新说明
- secret values 专题资料
- 项目里的 Lua 命名、注释、编写要求、性能与 git 快照约定

## 使用原则

- 文档用于快速定方向，最终 API 事实以最新 `wow-api-mcp` + `warcraft.wiki.gg` 为准。
- 只要涉及战斗信息，优先考虑 secret values 风险。
- 本项目仍以 WoW Lua 5.1 兼容写法为基础。
