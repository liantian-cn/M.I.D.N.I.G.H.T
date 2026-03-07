---
alwaysApply: false
globs: *.lua
---
# Lua 注释要求

## 基本规范

使用 **EmmyLua/LuaCATS** 风格文档注释，以 `---` 开头。

### 常用注解速查

| 注解 | 用途 | 示例 |
|------|------|------|
| `@param` | 参数说明 | `---@param name string 用户名` |
| `@return` | 返回值 | `---@return number 结果值` |
| `@class` | 定义类 | `---@class Car: Vehicle` |
| `@field` | 类字段 | `---@field name string` |
| `@type` | 变量类型 | `---@type string\|number` |
| `@alias` | 类型别名 | `---@alias modes "r" \| "w"` |
| `@enum` | 枚举 | `---@enum colors` |

### 类型系统

**基础类型**: `nil`, `any`, `boolean`, `string`, `number`, `integer`, `function`, `table`, `thread`, `userdata`

**复合类型**:

- `type?` - 可选（等同于 `type\|nil`）
- `type1\|type2` - 联合类型
- `TYPE[]` - 数组
- `{ [string]: VALUE }` - 字典
- `table<K, V>` - 键值表
- `fun(p: T): R` - 函数类型

## 完整示例

```lua
--- 获取单位增益效果层数
---@param spell number|string 法术ID或名称
---@param fromPlayer? boolean 是否来自玩家
---@return number 层数，不存在返回0
function Unit:BuffStacks(spell, fromPlayer)
    fromPlayer = fromPlayer or false
    local aura = findAura(self.Buffs, spell, fromPlayer)
    return aura and aura.applications or 0
end
```

## 强制要求

**必须注释**: 公有方法、API接口、模块导出函数

**可选简化**: 私有方法(`_`开头)、简单getter/setter、内部函数、回调

## 完整注解参考

### 类与面向对象

```lua
---@class ClassName[: Parent]
---@field fieldName type [描述]
---@field private fieldName type  -- 私有字段
---@field protected fieldName type  -- 受保护字段

---@class Array<T>: { [integer]: T }
---@class Dictionary<T>: { [string]: T }
```

### 函数相关

```lua
---@param name type [描述]           -- 普通参数
---@param name? type [描述]          -- 可选参数
---@param ... type                   -- 可变参数
---@return type [name] [描述]        -- 返回值
---@return type ...                  -- 多返回值
---@nodiscard                        -- 返回值不可忽略
---@deprecated                       -- 已弃用
---@async                           -- 异步函数
---@overload fun(params): returns    -- 函数重载
```

### 访问控制

```lua
---@private      -- 仅类内可访问
---@protected    -- 类及子类可访问
---@package      -- 仅当前文件可访问
```

### 类型工具

```lua
---@alias NewName Type              -- 类型别名
---@alias NewName
---| '"value1"' # 描述
---| '"value2"' # 描述

---@enum EnumName
local ENUM = { A = 1, B = 2 }

---@type Type                       -- 标记变量类型
---@cast var [+\|-]Type             -- 类型转换
---@as Type                         -- 强制类型 (--[=[@as T]=])

---@generic T [:Parent]             -- 泛型
---@param arg `T`                   -- 捕获类型
---@return `T`                      -- 返回泛型
```

### 其他

```lua
---@meta [name]                     -- 元定义文件
---@module 'moduleName'             -- 模拟require
---@see reference                   -- 参考
---@source path                     -- 源码引用
---@version [<\|>]ver [, ...]       -- Lua版本 (5.1/5.2/5.3/5.4/JIT)
---@diagnostic state:diagnostic     -- 诊断控制 (disable/enable/next-line/line)
---@operator op[(input)]:output     -- 运算符元方法
```

### 完整类示例

```lua
---@class Animal
---@field protected legs integer
---@field eyes integer
local Animal = {}

---@protected
function Animal:eyesCount()
    return self.eyes
end

---@class Dog: Animal
local Dog = {}

---@param name string 狗的名字
---@return Dog
function Dog:New(name)
    local obj = setmetatable({}, { __index = self })
    obj.name = name
    return obj
end
```
