# MIDNIGHT 工作指引

## 当前状态

- 仓库进入 WoW 12.1 `Curse of Ula'tek` 转型期。
- `DejaVu/` 和 `Terminal/` 是 12.0 冻结项目；除非用户明确要求维护冻结版本，不修改这两个目录。
- `Phantom/` 接替 `DejaVu/`，负责未来游戏内插件侧。
- `Copilot/` 接替 `Terminal/`，负责未来 Python 外部程序侧。
- 未来实现可能大幅调整旧代码解构；不要把 DejaVu/Terminal 的模块、颜色、协议、线程结构照搬到新项目。

## 任务路由

- 每次任务开始前，先选定唯一工作目录：`Phantom/`、`Copilot/`、根文档，或明确的冻结维护目录。
- 处理 12.1 游戏 API、secret values、Aura、FrameXML 变化时，先读 `.context/README.md`。
- 官方 API 变化记录保存在 `.context/WoW/api-changes/`；冲突时新版本优先，12.1.0 仍是 beta / PTR，依赖细节前提醒用户刷新。
- 处理 `Phantom/` 或 `Copilot/` 时，再读对应目录内的 `AGENTS.md` 和 `.context/README.md`。
- `wow-ui-source-12.1.0/` 是本地游戏框架源码参考，只有用户要求或 API 事实必须核实时才深入读取。

## 开发规则

- 9 月新版本前，Git 工作在小写 `dev` 分支；如果不在 `dev`，先切过去。
- 动手前先看 `git status --short`。
- 任何修改文件前，先提交一次 `backup`。
- 修改完成后，再提交一次这次任务的简要信息。
- Shell: On Windows, use PowerShell as the default shell.
- Lua: Use `luacheck` for Lua checking.
- 不主动“优化”用户代码；只有用户明确要求，或用户先指出实际异常，才处理。
- 处理异常时，只改异常相关部分，不顺手扩散修改。
- 补注释时，不要强行套主流规范；函数中间注释和行尾注释都允许。
- 不要顺手帮用户做额外操作，除非用户明确要求。

## 文档入口

- 根 `.context/` 只保留和 WoW 游戏 API / 12.1 迁移风险有关的内容。
- 除了“未来仍会开始一个矩阵”这个最低前提，不继承旧矩阵尺寸、颜色定义、Cell 语义和解码协议。
