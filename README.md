# M.I.D.N.I.G.H.T

Matrix of Infinite Death Nightfall Iteration Generation Host Terminal

Current Status: `12.0.1.66198`

## 项目概述

**M.I.D.N.I.G.H.T** 是一个面向《魔兽世界》场景的数据桥接辅助项目，核心思想是将游戏内数据以像素矩阵形式输出，再由游戏外程序进行识别与解析。

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

## ⚠️ 免责声明⚠️

1. **切勿直接使用**：本项目的代码特征明显，如果大量用户使用完全相同的代码，极易被游戏反作弊系统检测并导致**账号封禁**。  
2. **必须个性化修改**：强烈建议您根据自身需求对代码进行修改和定制。调整像素布局、数据结构或通信方式，使其具备独特性。  
3. **抛砖引玉，非开箱即用**：本项目旨在展示"将游戏数据转换为像素块并通过外部程序解析"的技术思路，而非提供可直接投入使用的产品。  
4. **自行承担全部风险**：任何基于本项目的二次开发、修改或使用行为，均由您自行承担一切后果（包括但不限于账号封禁、数据损失等）。  
5. **禁止商用与损害公平**：不得将本项目用于任何商业用途，或开发损害游戏公平性的外挂/自动化工具。  

---

## ⚠️ Disclaimer⚠️

1. **Do Not Use Directly**: This project's code has distinctive characteristics; if a large number of users use exactly the same code, it is highly likely to be detected by the game's anti‑cheat system and result in **account suspension**.
2. **Personalization Required**: It is strongly recommended that you modify and customize the code according to your own needs. Adjust pixel layouts, data structures, or communication methods to make it unique.
3. **A Spark for Ideas, Not Out‑of‑the‑Box**: This project aims to demonstrate the technical concept of "converting game data into pixel blocks and parsing them via external programs," not to provide a ready‑to‑use product.
4. **Assume All Risks**: Any secondary development, modification, or use based on this project is entirely at your own risk (including but not limited to account suspension, data loss, etc.).
5. **No Commercial Use or Fair‑Play Harm**: This project must not be used for any commercial purposes, nor for developing cheats/automation tools that undermine game fairness.

---

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

## 合规与安全

请结合 `SECURITY.md` 一起阅读，明确项目边界、风险声明与报告流程。
