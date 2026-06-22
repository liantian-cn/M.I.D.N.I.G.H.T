# M.I.D.N.I.G.H.T

Private Matrix of Infinite Death Nightfall Iteration Generation Host Terminal

## 12.1 转型期

本仓库正在从 WoW 12.0 方案转向 WoW 12.1 `Curse of Ula'tek`。

- `DejaVu/`: 旧游戏内插件侧，冻结。
- `Terminal/`: 旧 Python 外部程序侧，冻结。
- `Phantom/`: 新游戏内插件侧，接替 DejaVu。
- `Copilot/`: 新 Python 外部程序侧，接替 Terminal。
- `wow-ui-source-12.1.0/`: 本地 12.1 游戏框架源码参考。

12.1 的重点变化来自官方 API 和安全模型，尤其是 Aura、secret values、Forbidden Aspects 和相关 FrameXML 变化。当前事实入口见 `Phantom/.context/README.md` 和 `Phantom/.context/api-changes/`。

## 新项目原则

- 旧项目只作为冻结参考，不作为新结构模板。
- Phantom 和 Copilot 的代码解构可以大幅改变。
- 未来仍会从一个矩阵开始，但矩阵尺寸、颜色、Cell 语义和解码协议都未定。
- 文档只保留和游戏 API 有关的长期事实；旧颜色定义、旧协议和旧线程链路不再作为新项目约束。

## 安装

转型期安装文档暂停维护。

## 版权

MIT License
