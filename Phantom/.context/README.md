# Phantom 上下文

Phantom 是未来独立仓库根；不要依赖上级根目录的 `.context/`。

## 必读顺序

1. `.context/api-changes/README.md`
2. `.context/api-changes/INDEX.md`
3. `.context/api-changes/12.1.0.md`
4. `.context/12_1_api_transition.md`
5. `.context/secret_values.md`
6. `.context/api_query_playbook.md`

## 当前转型判断

- WoW 12.1 TOC 是 `120100`。
- 12.1.0 仍是 beta / PTR；依赖 API 细节前，先提醒用户官方记录可能需要刷新。
- API 记录冲突时，按 `.context/api-changes/` 的新版本优先。
- Aura、secret values、Forbidden Aspects 是首要风险。
- 旧 DejaVu 只作为冻结版本参考，不作为新结构模板。
- 未来会从一个矩阵开始；矩阵尺寸、颜色、Cell 和区域语义都未定。
