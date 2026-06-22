# WoW API 查询流程

## 先问的问题

- 这个 API 在 12.1 是否还存在？
- 返回值是否可能是 secret？
- 是否有新的 `C_*` namespace 替代？
- 是否应该改用 AuraContainer / AuraButton 等显示对象？
- 是否涉及 Forbidden Aspects 或 Forbidden Partition？

## 推荐流程

1. 先查本地 `.context/WoW/api-changes/`，新版本优先；12.1.0 仍是 PTR / beta 时先考虑刷新。
2. 用 `wow-api-mcp` 查 API 名称、参数、返回结构和废弃信息。
3. 查 `warcraft.wiki.gg` 的 API 页面确认限制说明。
4. 只有 patch 和 API 文档不足时，再读 `wow-ui-source-12.1.0/` 的对应文件。

## 不再保留的旧结论

- 不保留 DejaVu 的模块拆法作为未来设计。
- 不保留 Terminal 的解码结构作为未来设计。
- 不保留旧颜色表作为未来设计。
- 不保留旧矩阵尺寸作为未来设计。

未来新文档必须从 API 事实和 12.1 限制出发。
