local addonName, addonTable             = ... -- luacheck: ignore addonTable

local insert                            = table.insert

local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization

local className, classFilename, classId = UnitClass("player") -- luacheck: ignore className classId
local currentSpec                       = GetSpecialization()
if classFilename ~= "WARLOCK" then
    C_AddOns.DisableAddOn(addonName)
    return
end
if currentSpec ~= 2 then return end

local DejaVu = _G["DejaVu"]
local Config = DejaVu.Config
local ConfigRows = DejaVu.ConfigRows
local Cell = DejaVu.Cell
local MartixInitFuncs = DejaVu.MartixInitFuncs

do
    local warlock_burst_mode = Config("warlock_burst_mode")
    insert(ConfigRows, {
        type = "checkbox",
        key = "warlock_burst_mode",
        name = "爆发许可",
        tooltip = "开启后在恶魔暴君冷却就绪时进入预铺阶段",
        default_value = false,
        on_text = "开",
        off_text = "关",
        bind_config = warlock_burst_mode,
    })

    local function InitFrame()
        -- x:55 y:12
        -- Purpose: display Demonology Warlock burst permission config.
        local warlock_burst_mode_cell = Cell:New(55, 12)

        local function set_warlock_burst_mode(value)
            if value then
                warlock_burst_mode_cell:setCellRGBA(127 / 255)
            else
                warlock_burst_mode_cell:setCellRGBA(255 / 255)
            end
        end

        warlock_burst_mode:register_callback(set_warlock_burst_mode)
        set_warlock_burst_mode(warlock_burst_mode:get_value())
    end
    insert(MartixInitFuncs, InitFrame)
end
