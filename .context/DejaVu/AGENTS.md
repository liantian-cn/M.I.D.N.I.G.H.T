# DejaVu 参考工作指引

这份文档是原 `DejaVu/AGENTS.md` 的归档版。

真正自动生效的规则在仓库根 `AGENTS.md`；当任务工作目录选在 `DejaVu/` 时，可以把这里当作 DejaVu 侧的补充说明。

## 必读文档

1. `.context/Common/01_shared_protocol.md`
2. `.context/Common/03_color_conventions.md`
3. `.context/DejaVu/README.md`
4. `.context/DejaVu/00_secret_values.md`

## 项目提醒

- 当前实现由 `DejaVu_Core` 和多个 `DejaVu_*` 模块组成。
- 专精实现现在放在职业模块子目录下，例如 `DejaVu_Druid/Restoration` 和 `DejaVu_DeathKnight/Blood`。
- 这次重构主要目标是解决旧插件的性能问题。
- 性能瓶颈主要来自 Cell 刷新，即颜色、图标等显示内容的频繁重绘；Lua 数值计算通常不是主要矛盾。
- 重构时优先保留用户现有写法，不为了“更漂亮”而顺手优化、精简或重排。

## 开发规则

- API 问题先用 `wow-api-mcp`。
- 当前已知游戏内 bug：`UNIT_AURA` 相关信息暂时无法可靠区分 `isHarmful` / `isHelpful`，预计到 `2026年6月` 才会修复；在此之前，Aura 模块保留全量刷新或轮询方案是允许的。
- 如果返回值是否属于 `secret values` 判断不清，继续查 `https://warcraft.wiki.gg/`。
- 只要涉及血量、能量、冷却、光环、施法、威胁、单位身份、战斗中判断，先读 `.context/DejaVu/00_secret_values.md`。
- 改代码前先看 `git status --short`；无论是否脏工作区，都先按项目规则提交一次 `backup`。
- `local addonName, addonTable = ...` 之后，马上做当前文件会用到的全局函数本地化。
- 禁止用 `_` 当返回值占位符。
- 不实现自动战斗或代替玩家决策的逻辑。
- 不同速度的刷新档位，即便当前没有实际刷新内容，也不要删除对应的刷新结构。
- 用户写入的任何占位代码、空执行循环、空壳结构，都不要因为“没用”而删除。

## 检查命令

- 在 `DejaVu/` 目录下运行 `luacheck DejaVu_Common DejaVu_Core DejaVu_Matrix DejaVu_Panel DejaVu_Player DejaVu_Party DejaVu_Enemy DejaVu_Spell DejaVu_Aura DejaVu_DeathKnight DejaVu_DemonHunter DejaVu_Druid DejaVu_Priest`

## 第三方

以下文件夹是第三方依赖插件，在repo中，但无需修改。

- !BugGrabber
- BugSack
- LibRangeCheck-3.0
