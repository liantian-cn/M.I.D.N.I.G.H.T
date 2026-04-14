# Terminal 开发规则

这份文档只写和当前仓库强相关的规则。

## 基本规则

- 永远在 `draft` 分支工作。
- 开始任务前先看 `git status --short`。
- 无论工作区是否干净，都先做一次 `backup` 提交。
- 完成修改后，再提交一次这次任务的简要提交。
- Python 命令统一使用 `uv run`。

## AI 侧规则

- 这里是给 agent 看的，不是给最终用户看的。
- 以代码为准，但如果代码已经和 `.context/` 不一致，应在同一任务里把 `.context/` 补齐。
- 不主动“优化”用户代码；只有用户明确要求，或已经指出实际异常，才处理。
- 处理异常时，只改异常相关部分，不顺手扩散。

## 文档优先级

下面这些改动，先改 `.context/`，再决定是否继续动代码：

- 协议语义
- 矩阵尺寸
- Cell / BadgeCell / CharCell 语义
- 颜色分类
- 解码输出结构
- 线程链路和 worker 协作规则
- 模块边界

其中：

- 共享协议、矩阵基础语义：先改 `.context/Common/01_shared_protocol.md`
- 共享颜色、锚点、颜色分类：先改 `.context/Common/03_color_conventions.md`
- Terminal 专属解码输出、线程链路、架构边界：再改 `.context/Terminal/` 下对应文档

## 层间约束

- `capture` 只负责截图和定位，不负责业务解码。
- `pixelcalc` 只负责协议还原，不负责 Qt 调度。
- `context` 只负责包装解码结果，不负责截图和发键。
- `rotation` 只负责决策，不负责界面。
- `workers` 是后台执行层，不直接改 UI。
- `notes/` 只放实验脚本，不作为正式模块依赖。

## 修改 `ui/main_window.py` 时的额外注意

- 当前 decode 和 rotation 都采用“单飞行 + 只保留最新待处理项”的实时策略。
- 如果改了这套调度，必须同步检查 `workers/`、`02_runtime_pipeline.md` 和日志行为。
- `wait` 动作的效果是在主线程暂缓 rotation，不是暂停 capture / decode。
