# MIDNIGHT 12.1 API 上下文

根 `.context/` 只保存和 WoW 游戏 API、12.1 迁移风险有关的资料。

## 必读顺序

1. `.context/WoW/api-changes/README.md`
2. `.context/WoW/api-changes/INDEX.md`
3. `.context/WoW/api-changes/12.1.0.md`
4. `.context/WoW/12_1_api_transition.md`
5. `.context/WoW/secret_values.md`
6. `.context/WoW/api_query_playbook.md`

## 当前转型判断

- WoW 12.1 TOC 是 `120100`。
- 12.1.0 仍是 beta / PTR；依赖 API 细节前，先提醒用户官方记录可能需要刷新。
- API 记录冲突时，按 `.context/WoW/api-changes/` 的新版本优先。
- Aura 相关 API 是本轮重构最高风险点。
- `UnitAura` / `C_UnitAuras` 在战斗、地下城、PvP 等场景可能返回 secret 或 nil。
- 新方向应优先研究 AuraContainer、AuraButton、Private Script Objects、Forbidden Aspects。
- `[Bootstrap]`、`Frame:SetOnUpdateMode`、VectorGraphics、Roleset 等变化按需求再查。

## 非目标

- 不保存旧 DejaVu/Terminal 架构说明。
- 不保存旧颜色定义。
- 不保存旧矩阵尺寸、Cell 类型和解码协议。
- 不把 `wow-ui-source-12.1.0/` 当作每次任务都要通读的入口。

唯一保留的产品前提：未来仍会从一个矩阵开始。
