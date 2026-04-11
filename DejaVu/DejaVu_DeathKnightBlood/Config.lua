local addonName, addonTable             = ... -- 插件入口固定写法

-- Lua 原生函数
local insert                            = table.insert
local After                             = C_Timer.After
local random                            = math.random

-- WoW 官方 API
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEATHKNIGHT" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是死亡骑士则停止
if currentSpec ~= 1 then return end -- 不是鲜血专精则停止

local DejaVu = _G["DejaVu"]
local Config = DejaVu.Config
local ConfigRows = DejaVu.ConfigRows
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell


do
    -- x:55 y:12
    -- 最大符文能量 min:100 max:140 default:125 step:5
    -- 设置最大符文能量值
    local runic_power_max = Config("runic_power_max")
    insert(ConfigRows, {
        type = "slider",
        key = "runic_power_max",
        name = "最大符文能量",
        tooltip = "设置最大符文能量值",
        min_value = 100,
        max_value = 140,
        step = 5,
        default_value = 125,
        bind_config = runic_power_max,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local runic_power_max_cell = Cell:New(55, 12)
        local function set_runic_power_max(value)
            runic_power_max_cell:setCellRGBA(value / 255)
        end
        set_runic_power_max(runic_power_max:get_value())
        runic_power_max:register_callback(set_runic_power_max)
    end)
end

do
    -- x:56 y:12
    -- 打断模式 blacklist=使用黑名单 all=任意打断, default:blacklist
    local dk_interrupt_mode = Config("dk_interrupt_mode")
    insert(ConfigRows, {
        type = "combo",
        key = "dk_interrupt_mode",
        name = "打断模式",
        tooltip = "选择打断模式",
        default_value = "blacklist",
        options = {
            { k = "blacklist", v = "使用黑名单" },
            { k = "all", v = "任意打断" }
        },
        bind_config = dk_interrupt_mode,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local dk_interrupt_mode_cell = Cell:New(56, 12)
        local function set_dk_interrupt_mode(value)
            if value == "blacklist" then
                dk_interrupt_mode_cell:setCellRGBA(255 / 255)
            else
                dk_interrupt_mode_cell:setCellRGBA(127 / 255)
            end
        end
        set_dk_interrupt_mode(dk_interrupt_mode:get_value())
        dk_interrupt_mode:register_callback(set_dk_interrupt_mode)
    end)
end

do
    -- x:57 y:12
    -- 死亡打击生命值阈值 min:40 max:70 default:55 step:5
    -- 当前生命值低于该百分比时, 使用死亡打击
    local blood_death_strike_health_threshold = Config("blood_death_strike_health_threshold")
    insert(ConfigRows, {
        type = "slider",
        key = "blood_death_strike_health_threshold",
        name = "死亡打击生命值阈值",
        tooltip = "当前生命值低于该百分比时, 使用死亡打击",
        min_value = 40,
        max_value = 70,
        step = 5,
        default_value = 55,
        bind_config = blood_death_strike_health_threshold,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local blood_death_strike_health_threshold_cell = Cell:New(57, 12)
        local function set_blood_death_strike_health_threshold(value)
            blood_death_strike_health_threshold_cell:setCellRGBA(value / 255)
        end
        set_blood_death_strike_health_threshold(blood_death_strike_health_threshold:get_value())
        blood_death_strike_health_threshold:register_callback(set_blood_death_strike_health_threshold)
    end)
end

do
    -- x:58 y:12
    -- 死亡打击泄能阈值 min:80 max:120 default:100 step:10
    -- 当前符文能量高于该值时, 使用死亡打击避免浪费
    local blood_death_strike_runic_power_overflow_threshold = Config("blood_death_strike_runic_power_overflow_threshold")
    insert(ConfigRows, {
        type = "slider",
        key = "blood_death_strike_runic_power_overflow_threshold",
        name = "死亡打击泄能阈值",
        tooltip = "当前符文能量高于该值时, 使用死亡打击避免浪费",
        min_value = 80,
        max_value = 120,
        step = 10,
        default_value = 100,
        bind_config = blood_death_strike_runic_power_overflow_threshold,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local blood_death_strike_runic_power_overflow_threshold_cell = Cell:New(58, 12)
        local function set_blood_death_strike_runic_power_overflow_threshold(value)
            blood_death_strike_runic_power_overflow_threshold_cell:setCellRGBA(value / 255)
        end
        set_blood_death_strike_runic_power_overflow_threshold(blood_death_strike_runic_power_overflow_threshold:get_value())
        blood_death_strike_runic_power_overflow_threshold:register_callback(set_blood_death_strike_runic_power_overflow_threshold)
    end)
end

do
    -- x:59 y:12
    -- 死神印记血量阈值 min:10 max:60 default:30 step:10
    -- 当敌人生命值低于此值时, 就不会再使用死神印记
    local reaper_mark_health_threshold = Config("reaper_mark_health_threshold")
    insert(ConfigRows, {
        type = "slider",
        key = "reaper_mark_health_threshold",
        name = "死神印记血量阈值",
        tooltip = "当敌人生命值低于此值时, 就不会再使用死神印记",
        min_value = 10,
        max_value = 60,
        step = 10,
        default_value = 30,
        bind_config = reaper_mark_health_threshold,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local reaper_mark_health_threshold_cell = Cell:New(59, 12)
        local function set_reaper_mark_health_threshold(value)
            reaper_mark_health_threshold_cell:setCellRGBA(value / 255)
        end
        set_reaper_mark_health_threshold(reaper_mark_health_threshold:get_value())
        reaper_mark_health_threshold:register_callback(set_reaper_mark_health_threshold)
    end)
end

do
    -- x:60 y:12
    -- 符文刃舞模式 manual=手动 burst_mode=爆发模式 combat_mode=战斗时间模式 default:manual
    -- 手动模式: 完全不施放符文刃舞\n爆发模式: 仅在爆发阶段施放符文刃舞\n战斗时间模式: 根据战斗时间，开开怪期间自动施放符文刃舞。
    local dancing_rune_mode = Config("dancing_rune_mode")
    insert(ConfigRows, {
        type = "combo",
        key = "dancing_rune_mode",
        name = "符文刃舞模式",
        tooltip = "手动模式: 完全不施放符文刃舞\n爆发模式: 仅在爆发阶段施放符文刃舞\n战斗时间模式: 根据战斗时间，开开怪期间自动施放符文刃舞。",
        default_value = "manual",
        options = {
            { k = "manual", v = "手动" },
            { k = "burst_mode", v = "爆发模式" },
            { k = "combat_mode", v = "战斗时间模式" }
        },
        bind_config = dancing_rune_mode,
    })

    After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
        local dancing_rune_mode_cell = Cell:New(60, 12)
        local function set_dancing_rune_mode(value)
            if value == "manual" then
                dancing_rune_mode_cell:setCellRGBA(255 / 255)
            elseif value == "burst_mode" then
                dancing_rune_mode_cell:setCellRGBA(127 / 255)
            else
                dancing_rune_mode_cell:setCellRGBA(0 / 255)
            end
        end
        set_dancing_rune_mode(dancing_rune_mode:get_value())
        dancing_rune_mode:register_callback(set_dancing_rune_mode)
    end)
end
