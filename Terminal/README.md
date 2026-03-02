# Terminal

`Terminal` 是 M.I.D.N.I.G.H.T 的外部解析端（Python）。

当前状态：`12.0.1.66198`（脚手架阶段）

## 目标

1. 截图读取 DejaVu 绘制的 Matrix 区域。
2. 按协议解码 Cell/MegaCell/BadgeCell。
3. 为后续分析或展示层提供结构化数据。

## 本阶段内容

1. 提供项目目录与占位入口。
2. 不包含实质性解码实现。

## 运行方式（占位）

```powershell
uv run python main.py
```

## 目录

```text
Terminal/
├── main.py
├── requirements.txt
├── pyproject.toml
├── terminal/
│   └── __init__.py
└── tests/
    ├── test_cell_decode.py
    └── fixtures/
```
