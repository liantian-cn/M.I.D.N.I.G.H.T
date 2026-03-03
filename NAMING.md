# 命名法典

## 版本状态

- 当前文档基线：`12.0.1.66198`
- 约定：
  - `draft`：可调整，不承诺兼容。
  - `stable`：已冻结语义，变更需显式迁移说明。

## 核心术语命名

- 项目名：`M.I.D.N.I.G.H.T`
- 游戏内插件：`DejaVu`
- 外部解析端：`Terminal`
- 像素矩阵区域：`Matrix`
- 基础单元：`Cell`（4x4）
- 图标单元：`MegaCell`（8x8）
- 带角标单元：`BadgeCell`

## 文件与目录命名

1. 文档文件统一使用小写蛇形命名：`protocol.md`、`matrix_spec.md`。
2. 顶层治理文档使用明确命名：`README.md`、`Warning.md` 等。
3. Python 包路径使用小写：`terminal/`。
4. Lua 入口文件统一为 `main.lua`，避免多入口歧义。

## 代码标识符命名

1. Python：
   - 函数/变量：`snake_case`
   - 类：`PascalCase`
   - 常量：`UPPER_SNAKE_CASE`
2. Lua：
   - 函数/局部变量：`snake_case`
   - 模块表：`PascalCase` 或项目既有风格
3. 协议字段：
   - 统一 `snake_case`，例如：`frame_type`、`protocol_version`。

## 分支与标签命名

1. 分支：
   - 功能：`feat/<topic>`
   - 文档：`docs/<topic>`
   - 修复：`fix/<topic>`
2. 版本标签：
   - 游戏版本：`X.Y.Z.BUILD`（示例：`12.0.1.66198`）
   - 草案后缀：`X.Y.Z.BUILD-draft`

## 变更命名建议

1. 提交信息建议采用简洁前缀：
   - `docs:` 文档变更
   - `chore:` 维护与脚手架
   - `feat:` 新能力
   - `fix:` 缺陷修复
