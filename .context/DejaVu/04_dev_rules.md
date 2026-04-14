# 开发约定与工作流

## 第一原则

- 积极使用 `wow-api-mcp`
- 判断不清的值，先按 `secret values` 处理
- 最终事实以最新 `wow-api-mcp` + `warcraft.wiki.gg` 为准
- 协议和颜色语义先看 `.context/Common/01_shared_protocol.md` 与 `.context/Common/03_color_conventions.md`

## 代码风格

以仓库现有风格优先，结合整理出来的通用规则：

- Lua 版本按 5.1 / WoW 兼容写法
- 构造式对象、类型名用 `PascalCase`
- 局部变量默认 `local`
- 布尔变量尽量用 `is` / `has` / `can` / `should` 开头
- 不要依赖过新的 Lua 特性

## 注释约定

需要写文档注释时，优先用 EmmyLua / LuaCATS 风格：

- 公有方法、模块导出函数、对外接口：建议写 `---@param` / `---@return`
- 私有小函数、简单 getter / setter：可以从简

## 性能小原则

- `local addonName, addonTable = ...` 之后，立刻本地化当前文件会用到的全局函数
- 不要把全局函数本地化拖到后面的逻辑段里
- 少创建短命表
- 高频路径里避免重复查全局
- 事件刷新优先，少写常驻轮询

## Lua 文件头整理规则

- `local addonName, addonTable = ...` 仍然优先放在文件头最前面的 `local` 入口位置
- 文件头整理不能机械按“固定前 60 行”或其他固定行数处理，必须先把整份文件读完，再判断头部声明实际延伸到哪里
- 只要文件头后面紧跟模块表定义、工厂函数、保护性 `if not ... then return end`、文档注释、局部辅助函数，就要按该文件自己的结构单独判断，不要套批处理模板
- 头部整理优先保留原文件的阅读路径，不为了凑整齐或追求统一长度，硬拆原本连在一起的保护逻辑或模块初始化语句
- 如果需要补本地化、删未使用引用、补注释，必须逐文件人工修改；不要对项目 Lua 文件做整仓机械重排
- 修改文件头时，目标是“更清楚、可读、可维护”，不是“形式上完全一致”

## `_` 占位禁用

- 禁止用 `_` 当返回值占位符，尤其不要写 `local _, value = ...`
- 原因不是代码风格，而是 secret values 可能污染全局 `_`，进而把插件大面积带崩
- `local addonName, addonTable = ...` 这种固定入口，没用到的名字保留即可，再用 `-- luacheck: ignore addonName` 处理
- 如果多返回值里只想拿后面的值，优先用 `select(...)`

## git 工作流

- 动手前先看 `git status --short`
- 如果当前工作区已经脏，先做一次备份提交
- 小步修改，方便回看

## 检查与验证

- Shell 默认用 PowerShell
- Lua 检查命令示例：

```powershell
luacheck DejaVu_Common DejaVu_Core DejaVu_Matrix DejaVu_Panel DejaVu_Player DejaVu_Party DejaVu_Enemy DejaVu_Spell DejaVu_Aura DejaVu_DeathKnightBlood DejaVu_DruidGuardian DejaVu_DruidRestoration
```

- `DejaVu/.luacheckrc` 会被 `luacheck` 自动加载；一般不用额外写 `--config`
- 自动检查过后，还要结合游戏内实际表现做 smoke test

## 给 DejaVu 的落地提醒

- 这是 UI / 显示导向项目，优先做“看得见但不替玩家判断”的能力
- 不要实现自动战斗、自动决策或绕过 Blizzard 限制的逻辑
- 任何战斗态数据，只要有一点怀疑，就回到 `00_secret_values.md`
- 重构或整理代码时，优先保留原作者的阅读路径；除非逻辑确实更清晰，否则不要为了美化、对称或省代码而大幅改写用户原有结构
