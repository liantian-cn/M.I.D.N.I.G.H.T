# Terminal 文档入口

这里是 `.context/Terminal/` 下的 Terminal 专属上下文，不是最终用户说明书。

Terminal 文档只描述 Python / PySide6 侧当前已经实现的事实：项目边界、模块职责、截图到发键的运行链路、解码输出结构、线程调度和开发约束。共享矩阵协议和颜色归属仍然放在 `.context/Common/`。

## 建议阅读顺序

1. 根 `AGENTS.md`
2. `.context/README.md`
3. `.context/Common/01_shared_protocol.md`
4. `.context/Common/03_color_conventions.md`
5. `.context/Terminal/00_project_overview.md`
6. `.context/Terminal/01_terminal_decode_contract.md`
7. `.context/Terminal/02_runtime_pipeline.md`
8. `.context/Terminal/20_terminal_scope.md`
9. `.context/Terminal/21_terminal_architecture.md`
10. `.context/Terminal/22_terminal_dev_rules.md`

## 按任务路由补读

- 看整体定位、模块分层、当前主流程：`00_project_overview.md`
- 改解码输出结构、`decoded_data`、帧校验：`01_terminal_decode_contract.md`
- 改实际执行顺序、线程协作、丢帧 / 排队策略：`02_runtime_pipeline.md`
- 判断需求是否属于 Terminal 边界：`20_terminal_scope.md`
- 判断改动应该落在哪个包：`21_terminal_architecture.md`
- 做具体开发时的仓库规则和验证命令：`22_terminal_dev_rules.md`
- 改矩阵基础语义或跨项目协议：`.context/Common/01_shared_protocol.md`
- 改颜色分类、锚点颜色、脚标颜色语义：`.context/Common/03_color_conventions.md`

## `.agents` 入口

- Terminal 单项目任务优先使用 `.agents/skills/terminal-coder/`。
- DejaVu 单项目任务使用 `.agents/skills/dejavu-coder/`。
- 同时修改 DejaVu 插件和 Terminal rotation 配置时，才使用 rotation 相关的跨项目 skill。

## 同步原则

- 以当前仓库代码为准；如果代码和 `.context/` 不一致，先把相关 `.context` 补齐。
- 只要改到协议、颜色、矩阵、解码数据结构、线程链路或模块边界，就同步更新对应文档。
- 不要把 `notes/` 实验脚本写成正式运行链路。
- 不要因为整理 Terminal 文档顺手修改 DejaVu 文档或代码。
