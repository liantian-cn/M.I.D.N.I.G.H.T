---
alwaysApply: false
globs: *.lua
---
# 命名规则

## 函数

- 使用小驼峰式命名法（camelCase），例如 local userName, function getUserInfo()。

## 类名/表名

- 使用帕斯卡命名法（PascalCase/大驼峰），即首字母大写，如 PlayerManager。

## 全局常量

- 全大写，单词间用下划线分隔，如 MAX_HEALTH, DEFAULT_SPEED。

## 文件命名

- 通常全小写，建议使用下划线或连字符分隔（视具体项目而定，例如 player_manager.lua）。
- 使用序号，代表文件的加载顺序。

## 布尔变量

- 使用 is 或 has 作为前缀，例如 isFinished, hasItems。

## 局部变量

- 使用 local 声明，且变量名尽量有意义，避免使用匈牙利命名法（添加类型前缀）。

### 简单计数与索引

- 不推荐（匈牙利命名）：local iCount = 10
- 推荐（有意义命名）：local totalUsers = 10 或 local retryLimit = 10

### 字符串处理

- 不推荐（匈牙利命名）：local strName = "Lua"
- 推荐（有意义命名）：local playerName = "Lua" 或 local errorMessage = "file not found"

### 布尔逻辑（状态描述）

- 不推荐（匈牙利命名）：local bIsActive = true
- 推荐（自然语言描述）：local isActive = true 或 local hasPermission = true

### 复杂对象/表

- 不推荐（匈牙利命名）：local tConfig = {}
- 推荐（业务导向）：local userConfig = {} 或 local enemySettings = {}

### 函数返回值（利用上下文）

- 不推荐：local fValue = math.sin(x)
- 推荐：local sineValue = math.sin(x)
