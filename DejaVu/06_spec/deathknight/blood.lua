--[[
文件定位:
  DejaVu 德鲁伊职业特色Cell组配置模块, 定义德鲁伊形态相关的Cell布局。



状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable



-- Lua 原生函数
local insert                            = table.insert
local pairs                             = pairs

-- WoW 官方 API
local CreateFrame                       = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEATHKNIGHT" then return end -- 不是死亡骑士则停止
if currentSpec ~= 1 then return end               -- 不是鲜血专精则停止
-- 插件内引用
local logging = addonTable.Logging
local InitUI  = addonTable.Listeners.InitUI -- 初始化入口列表
local Cell    = addonTable.Cell             -- 基础色块单元
local Config  = addonTable.Config           -- 配置对象工厂









local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target灵界打击", key = "ALT-NUMPAD1", text = "/cast [@target] 灵界打击" })
insert(macroList, { title = "focus灵界打击", key = "ALT-NUMPAD2", text = "/cast [@focus] 灵界打击" })
insert(macroList, { title = "target精髓分裂", key = "ALT-NUMPAD3", text = "/cast [@target] 精髓分裂" })
insert(macroList, { title = "focus精髓分裂", key = "ALT-NUMPAD4", text = "/cast [@focus] 精髓分裂" })
insert(macroList, { title = "target死神印记", key = "ALT-NUMPAD5", text = "/cast [@target] 死神印记" })
insert(macroList, { title = "focus死神印记", key = "ALT-NUMPAD6", text = "/cast [@focus] 死神印记" })
insert(macroList, { title = "target心脏打击", key = "ALT-NUMPAD7", text = "/cast [@target] 心脏打击" })
insert(macroList, { title = "focus心脏打击", key = "ALT-NUMPAD8", text = "/cast [@focus] 心脏打击" })
insert(macroList, { title = "target心灵冰冻", key = "ALT-NUMPAD9", text = "/cast [@target] 心灵冰冻" })
insert(macroList, { title = "focus心灵冰冻", key = "ALT-NUMPAD0", text = "/cast [@focus] 心灵冰冻" })
insert(macroList,
       {
           title = "就近灵界打击",
           key = "SHIFT-NUMPAD1",
           text =
               "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n" ..
               "/cast [nocombat] 灵界打击 \n/stopmacro [channeling] \n/startattack \n" ..
               "/cast [harm]灵界打击 \n/targetlasttarget"
       })
insert(macroList,
       {
           title = "就近心脏打击",
           key = "SHIFT-NUMPAD2",
           text =
               "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n" ..
               "/cast [nocombat] 心脏打击 \n/stopmacro [channeling] \n/startattack \n" ..
               "/cast [harm]心脏打击 \n/targetlasttarget"
       })
insert(macroList, { title = "死神的抚摩", key = "SHIFT-NUMPAD3", text = "/cast 死神的抚摩" })
insert(macroList, { title = "player枯萎凋零", key = "SHIFT-NUMPAD4", text = "/cast [@player] 枯萎凋零" })
insert(macroList, { title = "血液沸腾", key = "SHIFT-NUMPAD5", text = "/cast 血液沸腾" })
insert(macroList, { title = "亡者复生", key = "SHIFT-NUMPAD6", text = "/cast 亡者复生" })
insert(macroList, { title = "cursor枯萎凋零", key = "SHIFT-NUMPAD7", text = "/cast [@cursor] 枯萎凋零" })
insert(macroList, { title = "target符文刃舞", key = "SHIFT-NUMPAD8", text = "/cast [@target] 符文刃舞" })
insert(macroList, { title = "focus符文刃舞", key = "SHIFT-NUMPAD9", text = "/cast [@focus] 符文刃舞" })


for _, macro in pairs(macroList) do --输出2 test2, 6 test3, 4 test1
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    logging("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end





do
    local blood_death_strike_health_threshold = Config("blood_death_strike_health_threshold")                             -- 死亡打击生命值阈值
    local blood_death_strike_runic_power_overflow_threshold = Config("blood_death_strike_runic_power_overflow_threshold") -- 死亡打击泄能阈值
    local reaper_mark_health_threshold = Config("reaper_mark_health_threshold")                                           -- 死亡打击泄能阈值
    local dancing_rune_mode = Config("dancing_rune_mode")                                                                 -- 符文刃舞模式

    insert(addonTable.Panel.Rows, {
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

    insert(addonTable.Panel.Rows, {
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

    insert(addonTable.Panel.Rows, {
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


    table.insert(addonTable.Panel.Rows, {
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
        bind_config = dancing_rune_mode
    })
    local function InitializeBloodSettingCell() -- 符文能量 Cell 初始化函数
        local blood_death_strike_health_threshold_cell = Cell:New(57, 12)
        local blood_death_strike_runic_power_overflow_threshold_cell = Cell:New(58, 12)
        local reaper_mark_health_threshold_cell = Cell:New(59, 12)
        local dancing_rune_mode_cell = Cell:New(60, 12)


        local function set_blood_death_strike_health_threshold(value)
            blood_death_strike_health_threshold_cell:setCellRGBA(value / 255)
        end
        set_blood_death_strike_health_threshold(blood_death_strike_health_threshold:get_value()) -- 初始化时设置一次颜色
        blood_death_strike_health_threshold:register_callback(set_blood_death_strike_health_threshold)

        local function set_blood_death_strike_runic_power_overflow_threshold(value)
            blood_death_strike_runic_power_overflow_threshold_cell:setCellRGBA(value / 255)
        end
        set_blood_death_strike_runic_power_overflow_threshold(blood_death_strike_runic_power_overflow_threshold:get_value()) -- 初始化时设置一次颜色
        blood_death_strike_runic_power_overflow_threshold:register_callback(set_blood_death_strike_runic_power_overflow_threshold)

        local function set_reaper_mark_health_threshold(value)
            reaper_mark_health_threshold_cell:setCellRGBA(value / 255)
        end
        set_reaper_mark_health_threshold(reaper_mark_health_threshold:get_value()) -- 初始化时设置一次颜色
        reaper_mark_health_threshold:register_callback(set_reaper_mark_health_threshold)

        local function set_dancing_rune_mode(value)
            if value == "manual" then
                dancing_rune_mode_cell:setCellRGBA(255 / 255) -- 绿色表示手动模式
            elseif value == "burst_mode" then
                dancing_rune_mode_cell:setCellRGBA(127 / 255) -- 黄色表示爆发模式
            else
                dancing_rune_mode_cell:setCellRGBA(0 / 255)   -- 红色表示战斗时间模式
            end
        end
        set_dancing_rune_mode(dancing_rune_mode:get_value()) -- 初始化时设置一次颜色
        dancing_rune_mode:register_callback(set_dancing_rune_mode)
    end
    insert(InitUI, InitializeBloodSettingCell) -- 注册 aura 序列初始化入口
end
