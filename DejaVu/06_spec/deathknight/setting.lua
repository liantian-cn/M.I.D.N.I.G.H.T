-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable


-- Lua 原生函数
local insert                            = table.insert

-- WoW 官方 API
local UnitPower                         = UnitPower
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEATHKNIGHT" then return end
-- 插件内引用
local InitUI = addonTable.Listeners.InitUI -- 初始化入口列表
local Cell   = addonTable.Cell             -- 基础色块单元
local Config = addonTable.Config           -- 配置对象工厂


addonTable.RangedRange = 30 -- 远程范围阈值, 单位为码


do
    local runic_power_max = Config("runic_power_max") -- 最大符文能量

    table.insert(addonTable.Panel.Rows, {             -- 滑块示例行
        type = "slider",
        key = "runic_power_max",
        name = "最大符文能量",
        tooltip = "设置最大符文能量值",
        min_value = 100,
        max_value = 140,
        step = 5,
        default_value = 125,           -- 默认值
        bind_config = runic_power_max, -- 绑定的配置对象
        -- callback = callback, -- 回调函数
    })

    local dk_interrupt_mode = Config("dk_interrupt_mode") -- 打断模式

    table.insert(addonTable.Panel.Rows, {
        type = "combo",
        key = "dk_interrupt_mode",
        name = "打断模式",
        tooltip = "选择打断模式",
        default_value = "blacklist",
        options = {
            { k = "blacklist", v = "使用黑名单" },
            { k = "all", v = "任意打断" }
        },
        bind_config = dk_interrupt_mode
    })

    local function InitializeDKSetting() -- 符文能量 Cell 初始化函数
        local runic_power_max_cell = Cell:New(55, 12)

        local function set_runic_power_max(value)
            runic_power_max_cell:setCellRGBA(value / 255)
        end
        set_runic_power_max(runic_power_max:get_value()) -- 初始化时设置一次颜色
        runic_power_max:register_callback(set_runic_power_max)


        local dk_interrupt_mode_cell = Cell:New(56, 12)

        local function set_dk_interrupt_mode(value)
            if value == "blacklist" then
                dk_interrupt_mode_cell:setCellRGBA(255 / 255) -- 绿色表示黑名单模式
            else
                dk_interrupt_mode_cell:setCellRGBA(127 / 255) -- 红色表示任意打断模式
            end
        end
        set_dk_interrupt_mode(dk_interrupt_mode:get_value()) -- 初始化时设置一次颜色
        dk_interrupt_mode:register_callback(set_dk_interrupt_mode)
    end


    insert(InitUI, InitializeDKSetting) -- 注册 aura 序列初始化入口
end
