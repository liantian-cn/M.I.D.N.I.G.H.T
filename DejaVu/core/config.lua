--[[
文件说明：




状态：
  draft
]]

local addonName, addonTable = ...

local Profile = addonTable.Profile

-- 缓存所有config对象，相同key返回同一对象
local config_cache = {}

-- Config对象
local ConfigObj = {}
ConfigObj.__index = ConfigObj

-- 创建新的config对象
function ConfigObj:new(key)
    local obj = {
        key = key,
        default_value = nil,
        callbacks = {}
    }
    setmetatable(obj, self)
    return obj
end

-- 设置默认值
function ConfigObj:set_default(value)
    self.default_value = value
end

-- 获取当前值（优先从profile读取，没有则返回默认值）
function ConfigObj:get_value()
    local data = Profile._get_current_data()
    if data[self.key] ~= nil then
        return data[self.key]
    end
    return self.default_value
end

-- 设置值（写入当前profile，触发回调）
function ConfigObj:set_value(value)
    local data = Profile._get_current_data()
    data[self.key] = value
    self:_notify()
end

-- 注册回调函数（值改变或profile切换时触发）
function ConfigObj:register_callback(func)
    table.insert(self.callbacks, func)
end

-- 内部：触发所有回调
function ConfigObj:_notify()
    local value = self:get_value()
    for _, callback in ipairs(self.callbacks) do
        callback(value)
    end
end

-- 工厂函数：获取或创建config对象
local function Config(key)
    if not config_cache[key] then
        config_cache[key] = ConfigObj:new(key)
        Profile._register_config(config_cache[key])
    end
    return config_cache[key]
end

addonTable.Config = Config
