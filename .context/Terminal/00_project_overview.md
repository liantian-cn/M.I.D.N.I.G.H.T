# Terminal 项目总览

`Terminal` 是运行在游戏外部的 Windows Python / PySide6 程序。

它不直接理解 WoW 内部状态，也不调用游戏 API。它只消费 `DejaVu` 画在屏幕上的矩阵，把像素协议还原成结构化数据，再交给 rotation 决策并向游戏窗口发送热键。

## 当前主链路

1. `capture` 枚举显示器，整屏截图，并用两个 `MARK_POINT` 模板锁定矩阵区域。
2. `workers/CaptureWorker` 按 FPS 循环截取锁定后的小区域。
3. `workers/FrameDecodeWorker` 对帧做有效性校验，构造 `MatrixDecoder`，调用 `extract_all_data()` 得到 `decoded_data`。
4. `context` 把 `decoded_data` 包装成 `Context` / `Unit` / `Spell` / `Aura` / `CellDict`。
5. `rotation` 通过 `BaseRotation.handle(decoded_data)` 创建 `Context`，由具体 rotation 返回 `cast` / `wait` / `idle`。
6. `workers/RotationWorker` 执行 rotation，并把 `cast` 的宏名映射为 `macroTable` 里的热键。
7. `ui/MainWindow` 保存状态、刷新 tab、记录日志、处理单飞行队列和等待窗口。
8. `keyboard` 枚举标题包含 `魔兽世界` 的窗口，并用 Win32 消息发送热键。

## 目录定位

- `terminal/application.py` / `main.py`: Qt 应用入口、窗口图标和主窗口启动。
- `terminal/capture/`: 显示器枚举、GDI BitBlt 截图、矩阵边界定位。
- `terminal/pixelcalc/`: Cell / BadgeCell / MegaCell / CharCell 解码、颜色映射、标题识别、结构化提取。
- `terminal/context/`: 对 `decoded_data` 的轻量访问包装。
- `terminal/rotation/`: `BaseRotation`、具体职业 rotation、热重载。
- `terminal/ui/`: 主窗口、tab、标题编辑器、用户交互和主线程调度。
- `terminal/workers/`: capture / decode / rotation 后台 worker。
- `terminal/keyboard.py`: 游戏窗口枚举和热键发送。
- `terminal/embedded_assets.py`: 内嵌 UI 资源。
- `tests/`: pytest 测试。
- `docs/`: rotation 编写说明。
- `notes/`: 实验、探针、基准，不是正式运行链路。

## 当前边界

- Terminal 的事实来源是屏幕矩阵和本仓库代码，不是 WoW API。
- Terminal 可以包装和消费协议，但不反向定义 DejaVu 应该输出什么。
- rotation 只返回动作，不直接碰 UI、截图或 Win32 发键。
- `notes/` 里的脚本只作为实验材料，不当正式模块扩写。
