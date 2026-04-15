# MIDNIGHT 工作指引

## 生效范围

- 根目录这个 `AGENTS.md` 是仓库内唯一自动生效的工作指引。
- `.context/DejaVu/AGENTS.md` 和 `.context/Terminal/AGENTS.md` 只作为项目参考文档保存，不再作为独立入口。

## 任务路由

- 每次任务开始前，先选定唯一工作子目录：`DejaVu/` 或 `Terminal/`。
- 允许同时读取根 `.context/Common/` 和对应项目目录 `.context/DejaVu/` 或 `.context/Terminal/`。
- 除非用户明确要求跨项目任务，不要顺手修改另一个子项目目录。
- 公共协议、颜色、共享规则统一维护在根 `.context/`；修改这些公共文档不算跨项目越界。

## 开发规则

- Git 永远工作在小写的 `draft` 分支；如果不在 `draft`, 先切过去。
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

- 处理共享协议、颜色、跨项目约束：先读 `.context/README.md`、`.context/Common/01_shared_protocol.md`、`.context/Common/03_color_conventions.md`。
- 处理 DejaVu：再读 `.context/DejaVu/README.md`。
- 处理 Terminal：再读 `.context/Terminal/README.md`。
