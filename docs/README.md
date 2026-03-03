# 文档导航

当前文档基线：`12.0.1.66198`

## 建议阅读顺序

1. `glossary.md`：先统一术语。
2. `protocol.md`：理解通信模型与生命周期。
3. `matrix_spec.md`：确认矩阵布局规则。
4. `cell_spec.md`：确认像素单元结构规则。
5. `color_palette.md`：颜色定义与语义映射。
6. `api_reference.md`：接口章节占位（待实现）。
7. `faq.md`：常见问题与设计理由。
8. `../Warning.md`：风险与合规声明。

## 文档职责边界

1. `protocol.md`：定义“传什么、怎么分帧、如何校验”的概念模型。
2. `matrix_spec.md`：定义“画在哪里、按什么坐标系”。
3. `cell_spec.md`：定义“每个单元长什么样、角标如何放置”。
4. `color_palette.md`：定义“颜色代表什么语义”。

## 版本规则

1. 标记为 `draft`（草案）的内容可能发生破坏性调整。
2. 标记为 `stable`（稳定）的内容需提供兼容说明与迁移路径。

## 项目总览（由原 README 迁入）

# M.I.D.N.I.G.H.T

Matrix of Infinite Death Nightfall Iteration Generation Host Terminal

Current Status: `12.0.1.66198`

## 项目概述

**M.I.D.N.I.G.H.T** 是一个面向《魔兽世界》场景的数据桥接辅助项目，核心思想是将游戏内数据以像素矩阵形式输出，再由游戏外程序进行识别与解析。

> 注：本项目为独立开发，当前不接受 Pull Request（PR）。

项目由两端组成：

1. **DejaVu（游戏内插件）**：负责在屏幕右上角绘制矩阵数据。
2. **Terminal（外部程序）**：负责截图读取像素并恢复结构化数据。

## 架构说明

由于新版本环境对游戏内计算能力存在限制，复杂计算会转移到游戏外执行：

1. DejaVu 将状态编码为固定像素单元并绘制到 Matrix 区域。
2. Terminal 使用 Python + OpenCV 读取截图中的 Matrix。
3. Terminal 按协议解码并交由后续分析/展示层处理。

协议设计目标：

1. 两端解耦：绘制端和读取端可独立迭代。
2. 可版本化：协议以文档形式维护并显式标注 Draft/Stable 状态。
3. 可追踪：关键协议变更进入 `CHANGELOG.md`。

## 仓库结构

```text
M.I.D.N.I.G.H.T/
├── DejaVu/         # WoW 插件端（像素绘制）
├── Terminal/       # Python 解析端（像素读取）
├── docs/           # 协议与契约文档
├── tools/          # 开发辅助工具骨架
└── *.md            # 根目录治理与项目文档
```

## 快速开始（草案）

1. 先阅读 `docs/README.md`，按顺序理解协议文档。
2. DejaVu 端先以占位结构完成加载与矩阵定位。
3. Terminal 端先以占位结构确认 Python 运行链路。
4. 在协议稳定前，不承诺跨版本兼容。

## 文档入口

1. `docs/README.md`：文档导航
2. `docs/protocol.md`：通信协议（Draft）
3. `docs/matrix_spec.md`：矩阵布局规范（Draft）
4. `docs/cell_spec.md`：Cell/MegaCell/BadgeCell 结构规范（Draft）
5. `docs/color_palette.md`：颜色定义（来自外部项目）
6. `../Warning.md`：风险与合规声明
