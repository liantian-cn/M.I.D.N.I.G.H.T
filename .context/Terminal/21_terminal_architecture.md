# Terminal 架构落点

这份文档回答的是：看到一个需求，应该先去哪一层找代码，改动边界在哪里。

## 包职责

### `main.py` / `terminal/application.py`

- 程序入口
- Qt 应用启动
- 主窗口创建

### `terminal/capture/`

- 枚举显示器
- BitBlt 截图
- 根据 `MARK_POINT` 模板定位矩阵边界

这里只关心“拿到哪块图”，不关心图里每个格子代表什么。

### `terminal/pixelcalc/`

- `MatrixDecoder`
- `Cell` / `BadgeCell` / `MegaCell` / `CharCell`
- 颜色映射
- 图标标题识别
- `extract_all_data()` 输出结构化原始数据

这里只负责“从像素还原协议”，不负责 rotation 决策，也不碰 Qt。

### `terminal/context/`

- `Context`
- `Unit`
- `Spell`
- `Aura`
- `CellDict`

这是 `decoded_data` 的轻量包装层，主要给 `rotation/` 用。它不参与截图，也不应该偷偷发按键。

### `terminal/rotation/`

- `BaseRotation`
- 具体职业 rotation
- 热重载支持

rotation 只根据 `Context` 做决策，输出动作，不碰 UI 控件。

### `terminal/ui/`

- `MainWindow`
- 各种 tab
- 标题编辑器

这里负责用户交互、界面刷新、状态展示、主线程调度。

### `terminal/workers/`

- `CaptureWorker`
- `FrameDecodeWorker`
- `RotationWorker`

它们是 UI 的后台执行辅助层，不是新的业务层。

### `terminal/keyboard.py`

- 枚举游戏窗口
- 把热键发给目标窗口

### `notes/`

- 基准
- 探针
- 临时实验

不是正式实现来源。

## 常见改动落点

- 截图错误、显示器区域、模板定位：先看 `capture/` 和 `workers/capture_worker.py`
- Cell 语义、矩阵切块、颜色分类、提取字段：先看 `pixelcalc/`
- `decoded_data` 不好用、rotation 访问麻烦：先看 `context/`
- 技能逻辑、宏映射、热重载：先看 `rotation/`
- 线程调度、丢帧策略、开始停止按钮、日志：先看 `ui/main_window.py` 和 `workers/`
- 标题识别和标题编辑器联动：同时看 `pixelcalc/title_manager.py` 和 `ui/dialogs/title_editor_dialog.py`

## 边界提醒

- `capture` 不定义协议语义，只负责找图和截对图。
- `pixelcalc` 不依赖 Qt，不写作战逻辑。
- `context` 不应该反向改变 `pixelcalc` 的协议。
- `rotation` 不应该直接操作 UI。
- `workers` 不直接操作 widget。
- `ui` 不应该在主线程里重写一套解码逻辑。
