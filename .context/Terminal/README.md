# Terminal 文档入口

这里是根 `.context/Terminal/` 下的 Terminal 专属文档入口，不是面向最终用户的说明书。

原则：

- 这里优先写项目边界、模块职责、运行链路、解码输出结构、开发约束。
- 共享协议和颜色已经迁到根 `.context/Common/`。
- 以当前仓库代码为准；如果代码已经变了，应该在同一任务里补这里。
- 只要改到协议、颜色、矩阵、解码数据结构、线程链路、模块边界，就要同步更新根 `.context/`。

建议阅读顺序：

1. `.context/Common/01_shared_protocol.md`
2. `.context/Common/03_color_conventions.md`
3. `00_project_overview.md`
4. `01_terminal_decode_contract.md`
5. `02_runtime_pipeline.md`
6. `20_terminal_scope.md`
7. `21_terminal_architecture.md`
8. `22_terminal_dev_rules.md`

按任务路由补读：

- 看整体定位、模块分层、项目现状：`00_project_overview.md`
- 改矩阵协议、Cell 语义：`.context/Common/01_shared_protocol.md`
- 改解码输出结构、`decoded_data`、帧有效性校验：`01_terminal_decode_contract.md`
- 改实际执行顺序、线程协作、丢帧 / 排队策略：`02_runtime_pipeline.md`
- 改颜色分类、锚点颜色、脚标颜色语义：`.context/Common/03_color_conventions.md`
- 判断某个需求是否属于 Terminal 边界：`20_terminal_scope.md`
- 判断某个改动应该落在哪个包：`21_terminal_architecture.md`
- 做具体开发时的仓库内规则：`22_terminal_dev_rules.md`
