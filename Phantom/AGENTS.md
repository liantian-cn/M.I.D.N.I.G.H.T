# Phantom 工作指引

## 定位

Phantom 是 12.1+ 游戏内插件侧新项目，接替 DejaVu。

## 当前规则

- 不照搬 DejaVu 的模块结构、颜色定义、Cell 语义或 Aura 读取方式。
- 先读根 `.context/README.md`，再读 `Phantom/.context/README.md`。
- 涉及 WoW API 时，以 `Patch-12-1-0-API-changes.md`、`wow-api-mcp` 和 `warcraft.wiki.gg` 为准。
- 当前只允许放骨架和文档；实现代码等后续明确任务。

## 最低前提

未来仍会从一个矩阵开始，但矩阵协议尚未定义。
