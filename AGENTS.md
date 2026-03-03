# 规则

## 全局规则

1. Shell：在 Windows 上默认使用 PowerShell。
2. Python：使用 `uv` 作为包管理器，Python 命令通过 `uv run` 执行。
3. Lua：使用 `D:\luacheck\luacheck.exe` 进行检查。
4. 开始任何编码任务前，如果当前 git 工作区存在未提交改动，必须先创建一次备份提交。该规则适用于每个任务。

## 项目规则

1. 协议文档更新优先于实现变更。
2. `docs/protocol.md`、`docs/matrix_spec.md`、`docs/cell_spec.md` 是 DejaVu 与 Terminal 对齐的事实来源。
3. 在脚手架阶段，不实现游戏自动化或决策逻辑。
4. 所有协议相关变更必须在文档中显式标注 `draft` 或 `stable` 状态。
5. 提交应保持小而可审查，文档变更与行为变更尽量分开提交。
6. 保留 `README.md` 中的风险声明与合规边界描述。
