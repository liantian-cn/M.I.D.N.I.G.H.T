--[[
文件用途：
  Config 模块提供“按 key 获取配置对象”的能力。
  相同 key 只会创建一个对象，并缓存复用。
  每个配置对象支持：
  1) 设置默认值：set_default(value)
  2) 读取当前值：get_value()
  3) 写入当前值：set_value(value)
  4) 注册回调：register_callback(func)

读取与写入规则：
  - 数据写入 DejaVuSave.profiles[当前profile][key]
  - 当前 profile 没有这个 key 时，get_value() 返回默认值
  - set_value() 会触发回调
  - Profile.switch_profile() 时也会触发回调（由 Profile 模块调用 _notify）

基础用例：
  local Config = addonTable.Config
  local Profile = addonTable.Profile

  local fps = Config("fps")
  fps:set_default(30)
  print(fps:get_value()) -- 30（未设置时返回默认值）

  fps:set_value(45)
  print(fps:get_value()) -- 45（已写入当前 profile）

  Profile.switch_profile("profile_1")
  print(fps:get_value()) -- 30（新 profile 还没写入 fps）

回调用例（同步滑块）：
  local function slider_set_value(v)
      slider:set_value(v)
  end
  fps:register_callback(slider_set_value)
  fps:set_value(60) -- 会触发 slider_set_value(60)

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
