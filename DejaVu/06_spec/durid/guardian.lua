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
if classFilename ~= "DRUID" then return end        -- 不是德鲁伊则停止
if currentSpec ~= 3 then return end                -- 不是守护专精则停止
local logging        = addonTable.Logging
local InitUI         = addonTable.Listeners.InitUI -- 初始化入口列表
local Cell           = addonTable.Cell             -- 基础色块单元
local Config         = addonTable.Config           -- 配置对象工厂
local Slots          = addonTable.Slots

local chargeSpells   = Slots.chargeSpells                         -- 充能技能列表
local cooldownSpells = Slots.cooldownSpells                       -- 普通冷却技能列表

insert(cooldownSpells, { spellID = 102793, cdType = "cooldown" }) --  [乌索尔旋风]
insert(cooldownSpells, { spellID = 6795, cdType = "cooldown" })   --  [低吼]
insert(cooldownSpells, { spellID = 132469, cdType = "cooldown" }) --  [台风]
insert(cooldownSpells, { spellID = 210053, cdType = "cooldown" }) --  [坐骑形态]
insert(cooldownSpells, { spellID = 20484, cdType = "cooldown" })  --  [复生]
insert(cooldownSpells, { spellID = 99, cdType = "cooldown" })     --  [夺魂咆哮]
insert(cooldownSpells, { spellID = 2908, cdType = "cooldown" })   --  [安抚]
insert(cooldownSpells, { spellID = 8936, cdType = "cooldown" })   --  [愈合]
insert(cooldownSpells, { spellID = 783, cdType = "cooldown" })    --  [旅行形态]
insert(cooldownSpells, { spellID = 8921, cdType = "cooldown" })   --  [月火术]
insert(cooldownSpells, { spellID = 22812, cdType = "cooldown" })  --  [树皮术]
insert(cooldownSpells, { spellID = 213771, cdType = "cooldown" }) --  [横扫]
insert(cooldownSpells, { spellID = 2782, cdType = "cooldown" })   --  [清除腐蚀]
insert(cooldownSpells, { spellID = 5487, cdType = "cooldown" })   --  [熊形态]
insert(cooldownSpells, { spellID = 77761, cdType = "cooldown" })  --  [狂奔怒吼]
insert(cooldownSpells, { spellID = 77758, cdType = "cooldown" })  --  [痛击]
insert(cooldownSpells, { spellID = 16979, cdType = "cooldown" })  --  [野性冲锋]
insert(cooldownSpells, { spellID = 1126, cdType = "cooldown" })   --  [野性印记]
insert(cooldownSpells, { spellID = 192081, cdType = "cooldown" }) --  [铁鬃]
insert(cooldownSpells, { spellID = 102558, cdType = "cooldown" }) --  [化身：乌索克的守护者]
insert(cooldownSpells, { spellID = 204066, cdType = "cooldown" }) --  [明月普照]
insert(cooldownSpells, { spellID = 106839, cdType = "cooldown" }) --  [迎头痛击]
insert(cooldownSpells, { spellID = 6807, cdType = "cooldown" })   --  [重殴]


insert(chargeSpells, { spellID = 22842, cdType = "charges" }) --  [狂暴回复]
insert(chargeSpells, { spellID = 33917, cdType = "charges" }) --  [裂伤]
insert(chargeSpells, { spellID = 61336, cdType = "charges" }) --  [生存本能]



local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target月火术", key = "ALT-NUMPAD1", text = "/cast [@target] 月火术" })
insert(macroList, { title = "focus月火术", key = "ALT-NUMPAD2", text = "/cast [@focus] 月火术" })
insert(macroList, { title = "target裂伤", key = "ALT-NUMPAD3", text = "/cast [@target] 裂伤" })
insert(macroList, { title = "focus裂伤", key = "ALT-NUMPAD4", text = "/cast [@focus] 裂伤" })
insert(macroList, { title = "target毁灭", key = "ALT-NUMPAD5", text = "/cast [@target] 毁灭" })
insert(macroList, { title = "focus毁灭", key = "ALT-NUMPAD6", text = "/cast [@focus] 毁灭" })
insert(macroList, { title = "target摧折", key = "ALT-NUMPAD7", text = "/cast [@target] 摧折" })
insert(macroList, { title = "focus摧折", key = "ALT-NUMPAD8", text = "/cast [@focus] 摧折" })
insert(macroList, { title = "target重殴", key = "ALT-NUMPAD9", text = "/cast [@target] 重殴" })
insert(macroList, { title = "focus重殴", key = "ALT-NUMPAD0", text = "/cast [@focus] 重殴" })
insert(macroList, { title = "target赤红之月", key = "ALT-F1", text = "/cast [@target] 赤红之月" })
insert(macroList, { title = "focus赤红之月", key = "ALT-F2", text = "/cast [@focus] 赤红之月" })
insert(macroList, { title = "target明月普照", key = "ALT-F3", text = "/cast [@target] 明月普照" })
insert(macroList, { title = "focus明月普照", key = "ALT-F5", text = "/cast [@focus] 明月普照" })
insert(macroList, { title = "enemy痛击", key = "ALT-F6", text = "/cast 痛击" })
insert(macroList, { title = "enemy横扫", key = "ALT-F7", text = "/cast 横扫" })
insert(macroList, { title = "any切换目标", key = "ALT-F8", text = "/targetenemy\n/focus\n/targetlasttarget" })
insert(macroList, { title = "player狂暴", key = "ALT-F9", text = "/cast 狂暴" })
insert(macroList, { title = "player化身：乌索克的守护者", key = "SHIFT-NUMPAD1", text = "/cast 化身：乌索克的守护者" })
insert(macroList, { title = "player铁鬃", key = "SHIFT-NUMPAD2", text = "/cast 铁鬃" })
insert(macroList, { title = "player狂暴回复", key = "SHIFT-NUMPAD3", text = "/cast 狂暴回复" })
insert(macroList, { title = "player树皮术", key = "SHIFT-NUMPAD4", text = "/cast 树皮术" })
insert(macroList, { title = "player生存本能", key = "SHIFT-NUMPAD5", text = "/cast 生存本能" })
insert(macroList, { title = "target迎头痛击", key = "SHIFT-NUMPAD6", text = "/cast [@target] 迎头痛击" })
insert(macroList, { title = "focus迎头痛击", key = "SHIFT-NUMPAD7", text = "/cast [@focus] 迎头痛击" })
insert(macroList, { title = "any熊形态", key = "SHIFT-NUMPAD8", text = "/cast [noform:1] 熊形态" })
insert(macroList,
       { title = "nearest裂伤", key = "SHIFT-NUMPAD9", text = "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n/cast [nocombat] 裂伤 \n/stopmacro [channeling] \n/startattack \n/cast [harm]裂伤 \n/targetlasttarget" })
insert(macroList,
       { title = "nearest毁灭", key = "SHIFT-NUMPAD0", text = "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n/cast [nocombat] 毁灭 \n/stopmacro [channeling] \n/startattack \n/cast [harm]毁灭 \n/targetlasttarget" })
insert(macroList, { title = "target安抚", key = "SHIFT-F1", text = "/cast [@target] 安抚" })
insert(macroList, { title = "focus安抚", key = "SHIFT-F2", text = "/cast [@focus] 安抚" })

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
    -- x:55 y:12
    -- AOE敌人数量 min:2 max:10 default:4 step:1
    -- 设置判定为AOE条件的敌人数量
    local guardian_aoe_enemy_count = Config("guardian_aoe_enemy_count")

    -- x:56 y:12
    -- 起手时间判定 min:5 max:45 default:10 step:5
    -- 即脱离战斗后多长时间内再次进入战斗时认为是起手阶段
    local guardian_opener_time = Config("guardian_opener_time")

    -- x:57 y:12
    -- 狂暴回复阈值 min:30 max:70 default:50 step:2
    -- 当玩家生命值低于该值时优先使用狂暴回复
    local guardian_frenzied_regeneration_threshold = Config("guardian_frenzied_regeneration_threshold")

    -- x:58 y:12
    -- 树皮阈值 min:20 max:60 default:40 step:2
    -- 当玩家生命值低于该值时优先使用树皮术
    local guardian_barkskin_threshold = Config("guardian_barkskin_threshold")

    -- x:59 y:12
    -- 生存本能阈值 min:10 max:50 default:30 step:2
    -- 当玩家生命值低于该值时优先使用生存本能
    local guardian_survival_instincts_threshold = Config("guardian_survival_instincts_threshold")

    -- x:60 y:12
    -- 怒气溢出阈值 min:60 max:120 default:100 step:5
    -- 高于该怒气时，不再使用攒怒技能。
    local guardian_rage_overflow_threshold = Config("guardian_rage_overflow_threshold")

    -- x:61 y:12
    -- 重殴怒气下限 min:90 max:130 default:120 step:5
    -- 当玩家怒气高于该值时，才会使用重殴泄怒
    local guardian_rage_maul_threshold = Config("guardian_rage_maul_threshold")

    -- x:62 y:12
    -- 打断逻辑  blacklist=使用黑名单 all=任意打断, default:blacklist
    local guardian_interrupt_logic = Config("guardian_interrupt_logic")

    -- x:63 y:12
    -- 化身逻辑  manual=手动 burst_mode=爆发模式 combat_mode = 战斗时间模式 default:burst_mode
    local guardian_incarnation_logic = Config("guardian_incarnation_logic")

    -- x:64 y:12
    -- 铁鬃逻辑  one=保持1层 two=保持2层 more=无线堆叠 default:two
    -- 会在铁宗持续时间过低时间使用铁宗。
    -- 保持1层时，实际铁鬃覆盖1-2层。
    -- 保持2层时，实际铁鬃覆盖1-3层。
    -- 无限堆叠，除了保留狂暴恢复德怒气外，全部打铁鬃。
    local guardian_ironfur_logic = Config("guardian_ironfur_logic")

    -- x:65 y:12
    -- 怒气上限
    local guardian_rage_limit = Config("guardian_rage_limit")

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_aoe_enemy_count",
        name = "AOE敌人数量",
        tooltip = "设置判定为AOE条件的敌人数量",
        min_value = 2,
        max_value = 10,
        step = 1,
        default_value = 4,
        bind_config = guardian_aoe_enemy_count,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_opener_time",
        name = "起手时间判定",
        tooltip = "即脱离战斗后多长时间内再次进入战斗时认为是起手阶段",
        min_value = 5,
        max_value = 45,
        step = 5,
        default_value = 10,
        bind_config = guardian_opener_time,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_frenzied_regeneration_threshold",
        name = "狂暴回复阈值",
        tooltip = "当玩家生命值低于该值时优先使用狂暴回复",
        min_value = 30,
        max_value = 70,
        step = 2,
        default_value = 50,
        bind_config = guardian_frenzied_regeneration_threshold,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_barkskin_threshold",
        name = "树皮阈值",
        tooltip = "当玩家生命值低于该值时优先使用树皮术",
        min_value = 20,
        max_value = 60,
        step = 2,
        default_value = 40,
        bind_config = guardian_barkskin_threshold,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_survival_instincts_threshold",
        name = "生存本能阈值",
        tooltip = "当玩家生命值低于该值时优先使用生存本能",
        min_value = 10,
        max_value = 50,
        step = 2,
        default_value = 30,
        bind_config = guardian_survival_instincts_threshold,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_rage_overflow_threshold",
        name = "怒气溢出阈值",
        tooltip = "高于该怒气时，不再使用攒怒技能。",
        min_value = 60,
        max_value = 120,
        step = 5,
        default_value = 100,
        bind_config = guardian_rage_overflow_threshold,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_rage_maul_threshold",
        name = "重殴怒气下限",
        tooltip = "当玩家怒气高于该值时，才会使用重殴泄怒",
        min_value = 90,
        max_value = 130,
        step = 5,
        default_value = 120,
        bind_config = guardian_rage_maul_threshold,
    })

    insert(addonTable.Panel.Rows, {
        type = "combo",
        key = "guardian_interrupt_logic",
        name = "打断逻辑",
        tooltip = "选择打断逻辑",
        default_value = "blacklist",
        options = {
            { k = "blacklist", v = "使用黑名单" },
            { k = "all", v = "任意打断" }
        },
        bind_config = guardian_interrupt_logic,
    })

    insert(addonTable.Panel.Rows, {
        type = "combo",
        key = "guardian_incarnation_logic",
        name = "化身逻辑",
        tooltip = "手动模式: 完全不施放化身：乌索克的守护者\n爆发模式: 仅在爆发阶段施放化身：乌索克的守护者\n战斗时间模式: 根据战斗时间，在开怪期间自动施放化身：乌索克的守护者。",
        default_value = "burst_mode",
        options = {
            { k = "manual", v = "手动" },
            { k = "burst_mode", v = "爆发模式" },
            { k = "combat_mode", v = "战斗时间模式" }
        },
        bind_config = guardian_incarnation_logic,
    })

    insert(addonTable.Panel.Rows, {
        type = "combo",
        key = "guardian_ironfur_logic",
        name = "铁鬃逻辑",
        tooltip = "保持1层: 实际铁鬃覆盖1-2层\n保持2层: 实际铁鬃覆盖1-3层\n无限堆叠: 除了保留狂暴回复的怒气外，全部打铁鬃。",
        default_value = "two",
        options = {
            { k = "one", v = "保持1层" },
            { k = "two", v = "保持2层" },
            { k = "more", v = "无限堆叠" }
        },
        bind_config = guardian_ironfur_logic,
    })

    insert(addonTable.Panel.Rows, {
        type = "slider",
        key = "guardian_rage_limit",
        name = "怒气上限",
        tooltip = "当前的怒气上限, 这点将影响Terminal的计算",
        min_value = 100,
        max_value = 140,
        step = 5,
        default_value = 120,
        bind_config = guardian_rage_limit,
    })

    local function InitializeGuardianSettingCell()
        local guardian_aoe_enemy_count_cell = Cell:New(55, 12)
        local guardian_opener_time_cell = Cell:New(56, 12)
        local guardian_frenzied_regeneration_threshold_cell = Cell:New(57, 12)
        local guardian_barkskin_threshold_cell = Cell:New(58, 12)
        local guardian_survival_instincts_threshold_cell = Cell:New(59, 12)
        local guardian_rage_overflow_threshold_cell = Cell:New(60, 12)
        local guardian_rage_maul_threshold_cell = Cell:New(61, 12)
        local guardian_interrupt_logic_cell = Cell:New(62, 12)
        local guardian_incarnation_logic_cell = Cell:New(63, 12)
        local guardian_ironfur_logic_cell = Cell:New(64, 12)
        local guardian_rage_limit_cell = Cell:New(65, 12)

        local function set_guardian_aoe_enemy_count(value)
            guardian_aoe_enemy_count_cell:setCellRGBA(value * 10 / 255)
        end
        set_guardian_aoe_enemy_count(guardian_aoe_enemy_count:get_value())
        guardian_aoe_enemy_count:register_callback(set_guardian_aoe_enemy_count)

        local function set_guardian_opener_time(value)
            guardian_opener_time_cell:setCellRGBA(value / 255)
        end
        set_guardian_opener_time(guardian_opener_time:get_value())
        guardian_opener_time:register_callback(set_guardian_opener_time)

        local function set_guardian_frenzied_regeneration_threshold(value)
            guardian_frenzied_regeneration_threshold_cell:setCellRGBA(value / 255)
        end
        set_guardian_frenzied_regeneration_threshold(guardian_frenzied_regeneration_threshold:get_value())
        guardian_frenzied_regeneration_threshold:register_callback(set_guardian_frenzied_regeneration_threshold)

        local function set_guardian_barkskin_threshold(value)
            guardian_barkskin_threshold_cell:setCellRGBA(value / 255)
        end
        set_guardian_barkskin_threshold(guardian_barkskin_threshold:get_value())
        guardian_barkskin_threshold:register_callback(set_guardian_barkskin_threshold)

        local function set_guardian_survival_instincts_threshold(value)
            guardian_survival_instincts_threshold_cell:setCellRGBA(value / 255)
        end
        set_guardian_survival_instincts_threshold(guardian_survival_instincts_threshold:get_value())
        guardian_survival_instincts_threshold:register_callback(set_guardian_survival_instincts_threshold)

        local function set_guardian_rage_overflow_threshold(value)
            guardian_rage_overflow_threshold_cell:setCellRGBA(value / 255)
        end
        set_guardian_rage_overflow_threshold(guardian_rage_overflow_threshold:get_value())
        guardian_rage_overflow_threshold:register_callback(set_guardian_rage_overflow_threshold)

        local function set_guardian_rage_maul_threshold(value)
            guardian_rage_maul_threshold_cell:setCellRGBA(value / 255)
        end
        set_guardian_rage_maul_threshold(guardian_rage_maul_threshold:get_value())
        guardian_rage_maul_threshold:register_callback(set_guardian_rage_maul_threshold)

        local function set_guardian_interrupt_logic(value)
            if value == "blacklist" then
                guardian_interrupt_logic_cell:setCellRGBA(255 / 255)
            else
                guardian_interrupt_logic_cell:setCellRGBA(127 / 255)
            end
        end
        set_guardian_interrupt_logic(guardian_interrupt_logic:get_value())
        guardian_interrupt_logic:register_callback(set_guardian_interrupt_logic)

        local function set_guardian_incarnation_logic(value)
            if value == "manual" then
                guardian_incarnation_logic_cell:setCellRGBA(255 / 255)
            elseif value == "burst_mode" then
                guardian_incarnation_logic_cell:setCellRGBA(127 / 255)
            else
                guardian_incarnation_logic_cell:setCellRGBA(0 / 255)
            end
        end
        set_guardian_incarnation_logic(guardian_incarnation_logic:get_value())
        guardian_incarnation_logic:register_callback(set_guardian_incarnation_logic)

        local function set_guardian_ironfur_logic(value)
            if value == "one" then
                guardian_ironfur_logic_cell:setCellRGBA(255 / 255)
            elseif value == "two" then
                guardian_ironfur_logic_cell:setCellRGBA(127 / 255)
            else
                guardian_ironfur_logic_cell:setCellRGBA(0 / 255)
            end
        end
        set_guardian_ironfur_logic(guardian_ironfur_logic:get_value())
        guardian_ironfur_logic:register_callback(set_guardian_ironfur_logic)


        local function set_guardian_rage_limit(value)
            guardian_rage_limit_cell:setCellRGBA(value / 255)
        end
        set_guardian_rage_limit(guardian_rage_limit:get_value())
        guardian_rage_limit:register_callback(set_guardian_rage_limit)
    end

    insert(InitUI, InitializeGuardianSettingCell)
end
