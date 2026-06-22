# WoW 12.1 API 转型笔记

## 事实源

- 本地摘要：`Patch-12-1-0-API-changes.md`
- 本地框架源码：`wow-ui-source-12.1.0/`
- 官方/社区查询：`wow-api-mcp`、`warcraft.wiki.gg`

## 12.1 关键点

- TOC: `120100`
- 版本标题：`Curse of Ula'tek`
- Aura 是最高风险区域。
- `UnitAura` / `C_UnitAuras` 在 auras secret 时可能返回 full secret 或 nil。
- `C_UnitAuras.GetUnitAuras` 和 `C_UnitAuras.GetUnitAuraInstanceIDs` 可能返回不能计数、不能遍历的 secret vector。
- 非 secret aura 仍可能通过 UnitAura 系列返回，但不能默认所有 aura 都可读。

## 新系统优先级

- AuraContainer
- AuraButton
- Private Script Objects
- Forbidden Partition
- Forbidden Aspects

这些系统用于让插件显示 aura，而不是读取底层 aura 数据再自行推理。

## 其他变化

- Load-on-Demand TOC 支持 per-file `[Bootstrap]`。
- `UIParentLoadAddOn` 改名为 `LoadAddOnWithErrorHandling`。
- 新增 `Frame:SetOnUpdateMode(mode)`。
- 新增 VectorGraphics / SVG 支持。
- 新 interface texture filenames 不再发布到 ManifestInterfaceData DB。

## 项目落点

- Phantom 不能照搬 DejaVu 的 Aura 读取模型。
- Copilot 不能照搬 Terminal 的旧解码结构作为稳定协议。
- 除了未来会有一个矩阵起点，旧颜色、旧 Cell、旧区域分区都不是新项目约束。
