# 插件结构、数据与库选择

## 先看项目自身结构

当前仓库已经按职责拆成下面这些目录：

- `DejaVu_Common`: 通用工具、共享小组件、辅助能力
- `DejaVu_Core`: 共享状态、事件、配置、基础设施、颜色定义
- `DejaVu_Loader`: 加载顺序和职业模块选择
- `DejaVu_Matrix`: 矩阵本体与基础布局
- `DejaVu_Panel`: 设置面板和配置 UI
- `DejaVu_Player` / `DejaVu_Party` / `DejaVu_Enemy`: 直接面向单位状态的显示输出
- `DejaVu_Spell` / `DejaVu_Aura`: 技能、Aura 一类显示模块
- `DejaVu_DeathKnight` / `DejaVu_DemonHunter` / `DejaVu_Druid` / `DejaVu_Priest`: 职业模块
- `DejaVu_DeathKnight/Blood`、`DejaVu_DemonHunter/Devourer`、`DejaVu_Druid/Guardian`、`DejaVu_Druid/Restoration`、`DejaVu_Priest/Discipline`: 当前已有专精接线层

写新功能时，优先顺着这个结构放，不要把临时逻辑塞进入口文件。

## 模块组织建议

- 先做小模块，再由对应模块注册到现有扩展点。
- 公共能力放 `DejaVu_Common` / `DejaVu_Core`。
- 矩阵本体和通用布局放 `DejaVu_Matrix`。
- 玩家可配置项放 `DejaVu_Panel`。
- 直接显示某类单位或某类信息的功能，放对应的 `DejaVu_Player` / `DejaVu_Party` / `DejaVu_Enemy` / `DejaVu_Spell` / `DejaVu_Aura`。
- 职业特化逻辑放职业目录下的专精目录，例如 `DejaVu_Druid/Restoration`。
- 需要矩阵初始化的显示块注册到代码现有的 `DejaVu.MartixInitFuncs`，不要为了修正拼写单独发明新入口。

如果一个功能同时碰 UI、数据、职业规则，尽量拆成几层，不要写成一个大文件。

## 当前加载与依赖关系

- `DejaVu_Core` 是基础插件，导出 `_G["DejaVu"]`。
- `DejaVu_Loader` 随 `DejaVu_Core` 加载，通过 `C_AddOns.LoadAddOn` 拉起其他 `LoadOnDemand` 模块。
- 通用显示模块当前加载顺序是 `Panel -> Matrix -> Aura -> Player -> Spell -> Enemy -> Party -> Common`。
- 职业模块按 `UnitClass("player")` 的 `classFilename` 选择加载。
- 职业模块 TOC 中直接列出专精子目录文件，常见顺序是 `Global.lua`、`Spec.lua`、`Spell.lua`、`Config.lua`、`Macro.lua`。

## SavedVariables 与数据持久化

整理原资料后，最值得保留的原则是：

- SavedVariables 只存必要状态
- 数据结构要能迁移，不要一开始就写死
- 给存档加版本号
- 默认值集中定义
- 迁移逻辑集中处理，不要散落在各模块里

当前核心存档入口是 `DejaVu_Core.toc` 里的 `DejaVu_CoreSave`，Profile 和 Config 逻辑分别在 `DejaVu_Core/Profile.lua` 与 `DejaVu_Core/Config.lua`。

如果只是 UI 状态、开关、布局位置，优先存轻量数据；不要把短期缓存和长期配置混在一起。

## 版本兼容思路

- 兼容判断优先放在边界层
- 尽量做“特性检测”，少做硬编码版本分支
- 真要跨多个客户端，先确认 TOC 共用值是否足够

对 12.x 来说，比“版本号判断”更重要的是“这个 API 返回值现在还能不能安全用”。

## 库的选择

原资料的结论很清楚：**新代码优先原生 API，库只在确实省事时再引入。**

优先考虑原生方案的场景：

- 编码 / 压缩 / JSON：先看 `C_EncodingUtil`
- 设置界面：先看 Blizzard Settings
- 常见 UI 控件：先看原生模板与控件

库依然有价值的场景：

- 需要 Ace3 的配置 / 数据库 / 事件封装
- 需要社区已约定的媒体、图标、数据桥接
- 需要兼容已有生态的数据格式

## Housing 文档怎么用

旧参考资料里有 Housing 指南。它说明 12.x 里 Blizzard 正在新增完整大系统和新命名空间。

对本项目的直接价值主要有两点：

- 遇到新资料时先想到“官方可能已经给了整套 namespace”
- 事件驱动、状态机、模式切换这类写法可以借鉴

如果当前功能和 Housing 无关，不必先读。
