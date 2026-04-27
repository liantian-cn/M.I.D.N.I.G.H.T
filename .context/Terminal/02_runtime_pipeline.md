# Terminal 运行链路

这份文档描述程序当前实际怎么跑，不画理想化分层图。

## 启动流程

1. `MainWindow` 从首页读取显示器、rotation 类和游戏窗口句柄。
2. 如果任一项缺失，主线程只记录日志并拒绝启动。
3. 启动成功后，主线程重置 capture / decode / rotation 状态，创建或复用 worker 线程。
4. `CaptureWorker.start_capture()` 先整屏截图，再调用 `find_template_bounds()` 找两个固定 `MARK_POINT` 模板。
5. 找到边界后，`CaptureWorker` 保存相对显示器的小区域，并立即截第一帧；之后由 `QTimer` 按 FPS 循环截图。

## 每帧流程

1. `CaptureWorker` 通过 `capture_ready(frame)` 把截图帧发回主线程。
2. 主线程递增 `frame_id`，调用 `_submit_frame_to_decode_worker()`。
3. `FrameDecodeWorker` 做帧校验，构造 `MatrixDecoder`，调用 `extract_all_data()`。
4. 解码成功后，主线程处理 `_pending_utf_title_record`，保存 `decoded_matrix` 和 `decoded_data`，刷新状态。
5. 主线程在提交 rotation 前检查热重载，然后把 `decoded_data`、`frame_id` 和当前 runtime rotation class 送到 `RotationWorker`。
6. `RotationWorker` 实例化 rotation，执行 `handle(decoded_data)`。
7. rotation 返回 `cast` 时，worker 用实例的 `macroTable` 找热键；主线程调用 `send_hot_key()` 发给用户选中的游戏窗口。
8. rotation 返回 `wait` 时，主线程设置 `_wait_until_monotonic`；返回 `idle` 时只做去重日志。

## 线程分工

- `MainWindow`: Qt 主线程，负责状态保存、信号连接、日志、UI 刷新、队列策略、发键调用。
- `CaptureWorker`: 独立 `QThread`，只做截图和矩阵区域锁定。
- `FrameDecodeWorker`: 独立 `QThread`，只做帧校验和解码。
- `RotationWorker`: 独立 `QThread`，只做 rotation 执行和宏名到热键的查询。
- worker 不直接操作 UI widget。

## 排队策略

当前是“单飞行 + 只保留最新待处理项”，不是每帧都必须完整处理的严格流水线。

- decode 忙时，新帧覆盖 `_pending_decode_frame`，旧待解码帧直接丢掉。
- rotation 忙时，新 `decoded_data` 覆盖 `_pending_rotation_data`，旧待决策数据直接丢掉。
- decode 完成后，如果存在 pending 帧，会立刻继续送下一帧；否则清空 `_decode_in_flight`。
- rotation 完成后，如果存在 pending 数据，会通过 `_submit_data_to_rotation_worker()` 再走一次等待窗口和热重载检查。

目标是保证实时性，不让旧帧在队列中积压。修改这里必须同时检查 `ui/main_window.py` 和 `terminal/workers/`。

## 失败行为

- capture 整屏截图失败、小区域截图失败、找不到矩阵边界，都会触发 `capture_failed` 并停机。
- decode 帧校验失败不会停机，状态变成 `invalid_frame`，上一份成功结果标记为 stale。
- decode 提取异常不会停机，状态变成 `error`，下一帧继续处理。
- rotation 异常只记录日志，不终止 capture / decode。
- 无效帧日志会按原因去重，避免同一类校验失败刷屏。

## rotation 热重载

- 热重载逻辑在 `terminal/rotation/hot_reload.py`。
- 主线程每次提交 rotation 前读取当前 rotation 源文件内容。
- 源码变化且加载成功时，切到新 class。
- 加载失败时，记录日志，并继续使用上一版已成功加载的 class。
- 同一份失败源码不会在未再次变化前反复尝试加载。

## 标题识别和 UTF 回填

- 图标标题识别属于 `pixelcalc`，核心是 `TitleManager`。
- `BadgeCell.title` / `MegaCell.title` 通过 `TitleManager.get_title()` 查标题。
- 持久化数据在 `database.sqlite`。
- `extract_all_data()` 发现 UTF 标题测试数据时，会产出 `_pending_utf_title_record`。
- 主线程把该记录写入 `TitleManager` 后再保存 `decoded_data`，UI 标题编辑器只是编辑和展示数据库。

## 等待动作

- rotation 返回 `wait` 时，主线程把 `_wait_until_monotonic` 设到未来。
- 等待窗口结束前，新的 `decoded_data` 不会送进 rotation，也不会排入 pending rotation。
- capture 和 decode 仍然继续运行，UI 仍然刷新。
