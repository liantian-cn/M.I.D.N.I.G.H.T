# MIDNIGHT `.context` 入口

这里是合并后的唯一上下文目录。

根目录 `AGENTS.md` 是唯一自动生效的工作指引；本目录负责提供共享协议、项目边界和子项目专属说明。

## 目录结构

- `Common/`
  - 两个子项目共同依赖的协议、颜色和跨项目约束。
- `DejaVu/`
  - WoW 插件侧专属文档。
- `Terminal/`
  - Python / PySide6 侧专属文档。

## 建议阅读顺序

1. 根 `AGENTS.md`
2. `Common/01_shared_protocol.md`
3. `Common/03_color_conventions.md`
4. 再按任务进入 `DejaVu/README.md` 或 `Terminal/README.md`

## 使用原则

- 公共协议、颜色、跨项目边界先改 `Common/`，再决定是否继续动代码。
- DejaVu 专属规则、WoW API 风险、模块落点放 `DejaVu/`。
- Terminal 专属运行链路、解码结构、线程约束放 `Terminal/`。
- `.context/DejaVu/AGENTS.md` 和 `.context/Terminal/AGENTS.md` 是历史入口的归档版，方便查项目习惯，不会自动生效。
