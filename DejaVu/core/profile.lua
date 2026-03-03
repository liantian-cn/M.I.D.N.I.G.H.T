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
