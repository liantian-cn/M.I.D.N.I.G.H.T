--[[
文件用途：
  Profile 模块负责管理配置分组（profile）。
  它只做三件事：
  1) 记录当前 profile 名称（DejaVuSave.current_profile）
  2) 切换 profile（不存在就自动创建空表）
  3) 切换后通知所有 Config 对象刷新值并触发回调

持久化结构：
  DejaVuSave.current_profile = "default"
  DejaVuSave.profiles = {
      ["default"] = { fps = 45 },
      ["profile_1"] = { fps = 60 },
  }

对外接口：
  Profile.current_profile() -> string
  Profile.switch_profile(name) -> nil

内部接口（给 config.lua 使用）：
  Profile._register_config(config_obj) -> nil
  Profile._get_current_data() -> table

用例：
  local Profile = addonTable.Profile
  print(Profile.current_profile())       -- default
  Profile.switch_profile("profile_1")    -- 不存在则自动创建
  print(Profile.current_profile())       -- profile_1

状态：
  draft
]]
local addonName, addonTable = ...

-- 确保保存表存在
DejaVuSave = DejaVuSave or {}
DejaVuSave.profiles = DejaVuSave.profiles or {}
DejaVuSave.profiles["default"] = DejaVuSave.profiles["default"] or {}
DejaVuSave.current_profile = DejaVuSave.current_profile or "default"

-- 所有config对象的注册表，用于切换profile时通知
local all_configs = {}

local Profile = {}

-- 获取当前profile名称
function Profile.current_profile()
    return DejaVuSave.current_profile
end

-- 切换profile（不存在则创建，所有值恢复默认）
function Profile.switch_profile(name)
    -- 如果profile不存在，创建一个空表
    if not DejaVuSave.profiles[name] then
        DejaVuSave.profiles[name] = {}
    end

    -- 切换当前profile
    DejaVuSave.current_profile = name

    -- 通知所有config回调
    for _, config in ipairs(all_configs) do
        config:_notify()
    end
end

-- 内部函数：注册config对象
function Profile._register_config(config)
    table.insert(all_configs, config)
end

-- 获取当前profile的数据表（内部使用）
function Profile._get_current_data()
    return DejaVuSave.profiles[DejaVuSave.current_profile]
end

addonTable.Profile = Profile
