# Terminal 参考工作指引

这份文档是原 `Terminal/AGENTS.md` 的归档版。

真正自动生效的规则在仓库根 `AGENTS.md`；当任务工作目录选在 `Terminal/` 时，可以把这里当作 Terminal 侧的补充说明。

## 先读

1. `.context/Common/01_shared_protocol.md`
2. `.context/Common/03_color_conventions.md`
3. `.context/Terminal/README.md`
4. `.context/Terminal/20_terminal_scope.md`
5. `.context/Terminal/22_terminal_dev_rules.md`

## 按任务路由补读

- 看项目现状、模块总览、主流程顺序：
  - `.context/Terminal/00_project_overview.md`
- 改矩阵协议、Cell 语义：
  - `.context/Common/01_shared_protocol.md`
- 改解码输出结构、`decoded_data`、帧校验：
  - `.context/Terminal/01_terminal_decode_contract.md`
- 改截图到发键的执行顺序、线程关系、worker 协作、丢帧策略、热重载：
  - `.context/Terminal/02_runtime_pipeline.md`
- 改颜色、脚标类型、锚点颜色、颜色分类：
  - `.context/Common/03_color_conventions.md`
- 判断改动应该落在哪个包，或要不要跨层：
  - `.context/Terminal/21_terminal_architecture.md`

## 模块路由

- `capture/`、显示器、截图、矩阵定位：
  - `.context/Common/01_shared_protocol.md`
  - `.context/Terminal/02_runtime_pipeline.md`
  - `.context/Terminal/21_terminal_architecture.md`
- `pixelcalc/`、矩阵切块、颜色、标题识别、提取结构：
  - `.context/Terminal/00_project_overview.md`
  - `.context/Terminal/01_terminal_decode_contract.md`
  - `.context/Common/03_color_conventions.md`
  - `.context/Terminal/21_terminal_architecture.md`
- `context/`、`rotation/`、按键发送：
  - `.context/Terminal/00_project_overview.md`
  - `.context/Terminal/01_terminal_decode_contract.md`
  - `.context/Terminal/02_runtime_pipeline.md`
  - `.context/Terminal/21_terminal_architecture.md`
- `ui/`、`workers/`、开始停止、日志、线程调度：
  - `.context/Terminal/02_runtime_pipeline.md`
  - `.context/Terminal/21_terminal_architecture.md`
- `notes/`：
  - `.context/Terminal/22_terminal_dev_rules.md`
  - 只把它当实验区，不当正式实现来源

## 开发边界

- 如果只是协议、颜色、矩阵语义、线程链路要改，先改根 `.context/` 里的对应文档，再决定是否继续动代码。

## 开发规则

- Python 命令统一用 `python main.py`（`main.py` 是项目入口文件，测试命令可以按任务调整）。
- 修改前先看 `git status --short`；无论是否脏工作区，都先按项目规则提交一次 `backup`。
