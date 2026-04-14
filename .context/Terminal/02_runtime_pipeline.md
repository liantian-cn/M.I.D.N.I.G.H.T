# Terminal 运行链路

这份文档描述“程序现在实际上怎么跑”，不是理想化分层图。

## 主流程

1. `ui/main_window.py` 读取用户在首页选择的显示器、rotation、游戏窗口句柄。
2. `CaptureWorker` 先对整块显示器截图，再用 `find_template_bounds()` 在整屏里找两个固定 `MARK_POINT` 模板。
3. 找到边界后，`CaptureWorker` 只循环截取这个小区域，并通过 `capture_ready(frame)` 把帧发回主线程。
4. 主线程给每帧分配 `frame_id`，把帧送到 `FrameDecodeWorker`。
5. `FrameDecodeWorker` 先做协议校验，再构造 `MatrixDecoder`，最后调用 `extract_all_data()` 产出 `decoded_data`。
6. 主线程保存最近一次成功解码结果，并把 `decoded_data` 送到 `RotationWorker`。
7. `RotationWorker` 实例化当前 rotation，执行 `handle(decoded_data)`，返回 `cast` / `wait` / `idle`。
8. 如果动作是 `cast`，主线程把宏名映射到热键，并通过 `send_hot_key()` 发给用户选中的游戏窗口。

## 线程分工

- `MainWindow` 在 Qt 主线程里，只做调度、状态保存、日志、界面刷新。
- `CaptureWorker` 在独立 `QThread` 里，只做截图和区域锁定。
- `FrameDecodeWorker` 在独立 `QThread` 里，只做矩阵校验和解码。
- `RotationWorker` 在独立 `QThread` 里，只做 rotation 决策。
- worker 不直接碰 UI 控件。

## 排队策略

当前不是“每帧都必须处理”的严格流水线，而是“单飞行 + 只保留最新待处理项”的策略：

- decode 忙的时候，新来的帧会覆盖 `_pending_decode_frame`，旧待解码帧直接丢掉。
- rotation 忙的时候，新来的 `decoded_data` 会覆盖 `_pending_rotation_data`，旧待决策数据直接丢掉。
- 这样做的目标是保证实时性，不让旧帧在队列里越积越多。

如果改这里，必须一起检查 `ui/main_window.py` 和 `workers/`，并同步更新这份文档。

## 校验和失败行为

- capture 阶段如果整屏截图失败，或找不到矩阵边界，整个运行流程会停下。
- decode 阶段如果帧校验失败，不会停机，只会把当前解码状态标记为 `invalid_frame`，并保留上一份成功结果为 stale。
- decode 阶段如果抛异常，会记录 `error`，但下一帧仍然可以继续处理。
- rotation 阶段如果抛异常，只记录日志，不终止 capture / decode。

## rotation 热重载

- 热重载逻辑在 `rotation/hot_reload.py`。
- 主线程在每次提交 rotation 前检查 rotation 源文件内容是否变化。
- 重载成功就切到新类继续跑。
- 重载失败就记录日志，继续使用上一版已成功加载的 rotation。

## 标题识别链路

- 图标标题识别属于 `pixelcalc`，核心是 `TitleManager`。
- `BadgeCell.title` / `MegaCell.title` 会走 `TitleManager.get_title()`。
- 持久化数据在 `database.sqlite`。
- UI 的标题编辑器只是编辑这个数据库，不改变 `pixelcalc` 的协议层职责。

## 等待动作

- rotation 返回 `wait` 时，主线程会把 `_wait_until_monotonic` 设到未来。
- 等待窗口结束前，新的 `decoded_data` 不会再送进 rotation。
- capture 和 decode 仍然继续跑，UI 仍然刷新。
