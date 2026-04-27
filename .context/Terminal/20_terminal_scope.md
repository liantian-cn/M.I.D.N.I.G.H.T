# Terminal 范围

`Terminal` 负责的是游戏外部这一侧的完整链路：

- 截图
- 解码
- 上下文抽象
- rotation 决策
- 向游戏窗口发送按键
- GUI 展示和主线程调度

## 属于 Terminal 的事

- 通过 Windows 截图拿到屏幕像素
- 在截图里锁定 `DejaVu` 矩阵区域
- 把矩阵像素还原成结构化数据
- 给 rotation 提供稳定的 `Context` 访问方式
- 根据当前 `BaseRotation` 约定执行 `cast` / `wait` / `idle`
- 在 UI 中展示当前解码结果和运行日志
- 把 rotation 结果发成热键给目标窗口
- 维护 Terminal 侧标题识别数据库和标题编辑器
- 维护 Terminal 单项目 `.agents` skill 和 `.context/Terminal/` 文档

## 不属于 Terminal 的事

- 改 `DejaVu` 插件内部绘制逻辑
- 把游戏内部 API 当作 Terminal 的直接输入
- 把 `notes/` 实验脚本并入正式运行链路
- 顺手做与当前问题无关的 GUI 大改或架构大改
- 在 Terminal 文档里替 DejaVu 重新定义共享协议
- 根据职业经验猜测 combat 业务值

## 文档同步规则

- 改协议、矩阵、颜色、解码输出结构：先改 `01` / `03`
- 改线程链路、执行顺序、worker 调度：先改 `02`
- 改模块边界或代码落点判断：改 `21`
- 改仓库内开发约束：改 `22`
- 改 `.agents` Terminal 工作入口：改 `.agents/skills/terminal-coder/`

如果某个需求必须先改 `DejaVu` 才能继续，不要在这个仓库里硬推，先停下并拆任务。
