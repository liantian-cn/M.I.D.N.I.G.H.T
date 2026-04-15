# Terminal 项目总览

`Terminal` 是一个运行在游戏外部的 Windows Python 小程序。

它做的事不是“理解游戏内部状态”，而是：

1. 捕获 `DejaVu` 画出来的屏幕矩阵
2. 把像素矩阵还原成结构化数据
3. 把结构化数据包装成 rotation 更容易调用的上下文对象
4. 根据 rotation 决策发送按键到游戏窗口

当前仓库已经不是纯草图阶段，主流程是可运行的。根 `.context/` 的职责不是讨论愿景，而是帮助 agent 快速理解当前代码已经实现了什么、哪些边界不能乱跨。

运行链路按当前代码是：

1. `capture`: 截图并锁定矩阵区域
2. `pixelcalc`: 解析截图，得到 `decoded_data`
3. `context`: 把 `decoded_data` 包装成 `Context` / `Unit` / `Spell` / `Aura`
4. `rotation`: 根据 `Context` 返回 `cast` / `wait` / `idle`
5. `ui`: 主线程、主窗口、日志、调度、可视化
6. `workers`: UI 的辅助线程，负责 capture / decode / rotation 三段后台执行
7. `keyboard`: 把宏名映射成热键并发给目标窗口

目录定位：

- `terminal/capture/`: 截图和矩阵区域定位
- `terminal/pixelcalc/`: 像素矩阵解码、颜色映射、标题识别、结构化提取
- `terminal/context/`: 对 `decoded_data` 的轻量封装
- `terminal/rotation/`: 作战逻辑
- `terminal/ui/`: 主界面和调度界面
- `terminal/workers/`: 后台线程工作对象
- `notes/`: 实验、探针、基准，不是正式实现

非目标：

- 不在这里改 `DejaVu` 插件内部逻辑
- 不把游戏内 API 或猜测状态当成 Terminal 的输入来源
- 不把 `notes/` 里的脚本当正式模块继续扩写
