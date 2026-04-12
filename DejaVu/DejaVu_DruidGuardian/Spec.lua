local addonName, addonTable             = ... -- luacheck: ignore addonName

-- Lua 原生函数
local After                             = C_Timer.After
local random                            = math.random
local insert                            = table.insert -- 表插入

-- WoW 官方 API
local CreateFrame                       = CreateFrame
local UnitPower                         = UnitPower
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DRUID" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是德鲁伊则停止
if currentSpec ~= 3 then return end -- 不是守护专精则停止
-- DejaVu Core
local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell


After(2, function()                    -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local cells = {
        ComboPoints = Cell:New(55, 13) -- 能量点数
    }


    local function UpdateComboPoints()
        local power = UnitPower("player", Enum.PowerType.ComboPoints)
        local mean = power * 51 / 255
        cells.ComboPoints:setCellRGBA(mean)
    end



    local eventFrame = CreateFrame("Frame")
    -- local fastTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    local lowTimeElapsed = -random() -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        -- fastTimeElapsed = fastTimeElapsed + elapsed
        -- if fastTimeElapsed > 0.1 then
        --     fastTimeElapsed = fastTimeElapsed - 0.1
        --     UpdateComboPoints()
        -- end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
            UpdateComboPoints()
        end
        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        --     UpdateComboPoints()
        -- end
    end)
end)
