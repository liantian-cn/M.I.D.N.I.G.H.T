---
alwaysApply: true
---
# Lua 命名规则

## 函数

### 普通函数

- 使用小驼峰式命名法（camelCase）
- 例如：`function getUserInfo()`, `function applyBorder(frame)`

### 类/模块方法

- **构造函数**：使用帕斯卡命名法（PascalCase），与类名一致
  - 例如：`function Cell:New()`, `function PlayerManager:Create()`
- **普通方法**：使用小驼峰式命名法（camelCase）
  - 例如：`function cell:setColor()`, `function player:getName()`
- **私有方法**：以下划线开头 + 小驼峰
  - 例如：`function cell:_updateInternal()`, `function obj:_notifyListeners()`

## 类名/模块名

- 使用帕斯卡命名法（PascalCase/大驼峰），即首字母大写
- 例如：`Cell`, `PlayerManager`, `ConfigObj`, `UI`, `Profile`
- 单例模块或命名空间也使用帕斯卡命名

## 全局常量

- 全大写，单词间用下划线分隔（UPPER_SNAKE_CASE）
- 例如：`MAX_HEALTH`, `DEFAULT_SPEED`, `COLOR_RED`

## 局部常量

- 与全局常量相同：全大写 + 下划线分隔
- 例如：`local CELL_SIZE = 16`

## 变量

### 局部变量

- 使用 `local` 声明
- 使用小驼峰式命名法（camelCase）
- 变量名要有意义，避免使用匈牙利命名法（添加类型前缀）

**不推荐（匈牙利命名）：**

```lua
local iCount = 10
local strName = "Lua"
local bIsActive = true
local tConfig = {}
local fValue = math.sin(x)
```

**推荐：**

```lua
local totalUsers = 10
local playerName = "Lua"
local isActive = true
local userConfig = {}
local sineValue = math.sin(x)
```

### 布尔变量

- 使用 `is`、`has`、`can`、`should` 作为前缀
- 例如：`isFinished`, `hasItems`, `canMove`, `shouldUpdate`

### 循环变量

- 简单循环可使用单字符：`i`, `j`, `k`
- 迭代器变量使用有意义的名称：`key`, `value`, `index`, `item`

## 文件命名

- 通常全小写
- 使用下划线分隔单词
- 使用序号前缀表示加载顺序
- 例如：`01_frame.lua`, `02_cell.lua`, `player_manager.lua`

## 元表相关

### __index 设置

- 类定义时设置：`Class.__index = Class`

### 方法调用符

- 使用冒号 `:` 定义和调用方法（自动传入 self）
- 使用点 `.` 访问属性或静态成员

## 完整示例

```lua
-- 类定义
local Player = {}
Player.__index = Player

-- 常量
local MAX_LEVEL = 100
local DEFAULT_NAME = "Unknown"

-- 构造函数（帕斯卡）
function Player:New(name)
    local instance = setmetatable({}, self)
    instance:_initialize(name or DEFAULT_NAME)
    return instance
end

-- 私有方法（下划线前缀）
function Player:_initialize(name)
    self.name = name      -- 属性：小驼峰
    self.level = 1
    self.isActive = true  -- 布尔：is前缀
end

-- 公有方法（小驼峰）
function Player:getName()
    return self.name
end

function Player:setLevel(level)
    if level > 0 and level <= MAX_LEVEL then
        self.level = level
    end
end

-- 普通函数（小驼峰）
local function createDefaultPlayer()
    return Player:New()
end
```
