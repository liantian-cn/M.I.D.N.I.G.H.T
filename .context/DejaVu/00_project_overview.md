# DejaVu 项目总览

`DejaVu` 是游戏内 WoW 插件，负责把战斗信息稳定地显示成一块可被外部程序读取的像素矩阵。

## 当前定位

- 在游戏内创建并维护右上角矩阵。
- 用多种像素块表达状态、数值、图标、脚标和文本。
- 让外部程序按共享协议读取矩阵，而不是猜 WoW UI 语义。
- DejaVu 侧只负责稳定输出，不负责外部截图、解码和键盘发送。

## 输出组成

- `Cell`: 4x4，用来表达布尔值或数值映射
- `MegaCell`: 8x8 纯色块，用来表达明显控制信息
- `BadgeCell`: 8x8 图标加脚标，用来表达技能、Buff、Debuff
- `CharCell`: 8x8 字符像素块，用来表达文本
- `Bar`: 用连续像素块表达进度或比例

## 当前代码结构

当前 DejaVu 目录按插件模块拆分：

- `DejaVu_Core`: 全局表 `_G["DejaVu"]`、版本、配置对象、Profile、颜色定义和基础 CVar。
- `DejaVu_Loader`: 随 `DejaVu_Core` 加载，负责顺序加载其他按需模块和当前职业模块。
- `DejaVu_Matrix`: 矩阵框体、`Cell` / `MegaCell` / `BadgeCell` / `CharCell` / `Bar` 和定位标记。
- `DejaVu_Panel`: 游戏内控制条、设置面板、设置行和技能列表编辑器。
- `DejaVu_Player` / `DejaVu_Party` / `DejaVu_Enemy`: 玩家、小队、敌对单位状态输出。
- `DejaVu_Spell` / `DejaVu_Aura`: 技能冷却/充能和 Aura 输出。
- `DejaVu_Common`: 通用显示单元、黑名单、爆发、鼠标、延迟更新等共享能力。
- `DejaVu_DeathKnight` / `DejaVu_DemonHunter` / `DejaVu_Druid` / `DejaVu_Priest`: 职业模块，专精代码放在职业目录下的子目录。

当前已有专精目录：

- `DejaVu_DeathKnight/Blood`
- `DejaVu_DemonHunter/Devourer`
- `DejaVu_Druid/Guardian`
- `DejaVu_Druid/Restoration`
- `DejaVu_Priest/Discipline`

第三方依赖目录：

- `!BugGrabber`
- `BugSack`
- `LibRangeCheck-3.0`

这些目录只在明确处理依赖问题时修改。

## 加载顺序

`DejaVu_Loader/DejaVu_Loader.lua` 当前先加载公共显示模块，再按玩家职业加载职业模块：

1. `DejaVu_Panel`
2. `DejaVu_Matrix`
3. `DejaVu_Aura`
4. `DejaVu_Player`
5. `DejaVu_Spell`
6. `DejaVu_Enemy`
7. `DejaVu_Party`
8. `DejaVu_Common`
9. `DejaVu_DeathKnight` / `DejaVu_Druid` / `DejaVu_Priest` / `DejaVu_DemonHunter`

矩阵初始化扩展点沿用代码里的既有拼写 `DejaVu.MartixInitFuncs`，整理文档时不要自行改成 `MatrixInitFuncs`。

## 矩阵契约

- 当前矩阵尺寸是 `84 x 28` 个 `Cell`。
- 矩阵框体创建在 `DejaVu_Matrix/Matrix.lua`。
- 字体路径由 Matrix 和 Panel 模块各自设置。
- 锚点颜色来自 `DejaVu_Core/Color.lua` 的 `MARK_POINT`。

共享协议和颜色事实仍以 `.context/Common/01_shared_protocol.md` 与 `.context/Common/03_color_conventions.md` 为准。

## 关键边界

- `DejaVu` 只负责“稳定输出”。
- 它输出的是显示协议，不是给玩家直接看的普通 UI。
- 如果共享协议要改，先更新 `.context/Common/01_shared_protocol.md`，再补当前目录文档，再安排代码改动。
- 如果颜色语义要改，先更新 `.context/Common/03_color_conventions.md`。
- 不把外部识别、截图、Python 还原逻辑写进这个项目。

## 当前状态

- 当前代码以 `## Interface: 120001`、插件版本 `12.0.1.66709` 为基准。
- 当前文档重点是帮助 agent 快速找到协议、API 风险、模块落点和开发禁区。
