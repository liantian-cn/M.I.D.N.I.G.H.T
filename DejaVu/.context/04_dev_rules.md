# 开发约定与工作流

## 第一原则

- 积极使用 `wow-api-mcp`
- 判断不清的值，先按 `secret values` 处理
- 最终事实以最新 `wow-api-mcp` + `warcraft.wiki.gg` 为准

## 代码风格

以仓库现有风格优先，结合整理出来的通用规则：

- Lua 版本按 5.1 / WoW 兼容写法
- 文件名用小写加下划线，保留数字前缀表示加载顺序
- 构造式对象、类型名用 `PascalCase`
- 局部变量默认 `local`
- 布尔变量尽量用 `is` / `has` / `can` / `should` 开头
- 不要依赖过新的 Lua 特性

## 注释约定

需要写文档注释时，优先用 EmmyLua / LuaCATS 风格：

- 公有方法、模块导出函数、对外接口：建议写 `---@param` / `---@return`
- 私有小函数、简单 getter/setter：可以从简

## 性能小原则

- `local addonName, addonTable = ...` 之后尽早本地化常用全局函数
- 少创建短命表
- 高频路径里避免重复查全局
- 事件刷新优先，少写常驻轮询

## git 工作流

- 动手前先看 `git status --short`
- 如果当前工作区已经脏，先做一次备份提交
- 小步修改，方便回看

## 检查与验证

- Shell 默认用 PowerShell
- Python 命令用 `uv run`
- Lua 检查命令：

```powershell
D:\luacheck\luacheck.exe 100_main.lua 01_utils 02_core 03_matrix 04_panel 05_slots 06_spec
```

- 自动检查过后，还要结合游戏内实际表现做 smoke test

## 给 DejaVu 的落地提醒

- 这是 UI/显示导向项目，优先做“看得见但不替玩家判断”的能力
- 不要实现自动战斗、自动决策或绕过 Blizzard 限制的逻辑
- 任何战斗态数据，只要有一点怀疑，就回到 `00_secret_values.md`

