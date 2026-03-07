--[[
文件定位：




状态：
  draft
]]

local addonName, addonTable = ...
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local wipe = wipe

addonTable.Event = {}
addonTable.Event.Func = {}

addonTable.Event.Func.InitUI = {}

addonTable.Event.Func.OnUpdateHigh = {}
addonTable.Event.Func.OnUpdateLow = {}


addonTable.Event.Func.SPELLS_CHANGED = {}
addonTable.Event.Func.SPELL_UPDATE_ICON = {}
addonTable.Event.Func.PLAYER_TALENT_UPDATE = {}
addonTable.Event.Func.TRAIT_CONFIG_UPDATED = {}
addonTable.Event.Func.UPDATE_MOUSEOVER_UNIT = {}
addonTable.Event.Func.UNIT_AURA = {}


local eventFrame = CreateFrame("EventFrame", addonName .. "Frame")
addonTable.Event.Frame = eventFrame

function eventFrame:PLAYER_ENTERING_WORLD()
    C_Timer.After(0, function()
        wipe(addonTable.Event.Func.OnUpdateHigh)
        wipe(addonTable.Event.Func.OnUpdateLow)


        for funcIndex = 1, #addonTable.Event.Func.InitUI do
            local func = addonTable.Event.Func.InitUI[funcIndex]
            func()
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function eventFrame:SPELLS_CHANGED()
    for funcIndex = 1, #addonTable.Event.Func.SPELLS_CHANGED do
        local func = addonTable.Event.Func.SPELLS_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:SPELL_UPDATE_ICON()
    for funcIndex = 1, #addonTable.Event.Func.SPELL_UPDATE_ICON do
        local func = addonTable.Event.Func.SPELL_UPDATE_ICON[funcIndex]
        func()
    end
end

function eventFrame:PLAYER_TALENT_UPDATE()
    for funcIndex = 1, #addonTable.Event.Func.PLAYER_TALENT_UPDATE do
        local func = addonTable.Event.Func.PLAYER_TALENT_UPDATE[funcIndex]
        func()
    end
end

function eventFrame:TRAIT_CONFIG_UPDATED()
    for funcIndex = 1, #addonTable.Event.Func.TRAIT_CONFIG_UPDATED do
        local func = addonTable.Event.Func.TRAIT_CONFIG_UPDATED[funcIndex]
        func()
    end
end

function eventFrame:UPDATE_MOUSEOVER_UNIT()
    for funcIndex = 1, #addonTable.Event.Func.UPDATE_MOUSEOVER_UNIT do
        local func = addonTable.Event.Func.UPDATE_MOUSEOVER_UNIT[funcIndex]
        func()
    end
end

function eventFrame:UNIT_AURA(unitTarget)
    for funcIndex = 1, #addonTable.Event.Func.UNIT_AURA do
        local updaterInfo = addonTable.Event.Func.UNIT_AURA[funcIndex]
        if updaterInfo.unit == unitTarget then
            updaterInfo.func()
        end
    end
end

-- 注册事件
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
-- eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
-- eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)


-- 时间流逝变量
local timeElapsed = 0
local lowFrequencyTimeElapsed = 0
-- 钩子OnUpdate脚本，用于定时更新
eventFrame:HookScript("OnUpdate", function(self, elapsed)
    local tickOffset             = 1.0 / 10;
    local lowFrequencyTickOffset = 1.0 / 2;
    timeElapsed                  = timeElapsed + elapsed
    lowFrequencyTimeElapsed      = lowFrequencyTimeElapsed + elapsed
    if timeElapsed > tickOffset then
        timeElapsed = 0
        for updaterIndex = 1, #addonTable.Event.Func.OnUpdateHigh do
            local updater = addonTable.Event.Func.OnUpdateHigh[updaterIndex]
            updater()
        end
    end
    if lowFrequencyTimeElapsed > lowFrequencyTickOffset then
        lowFrequencyTimeElapsed = 0
        for updaterIndex = 1, #addonTable.Event.Func.OnUpdateLow do
            local updater = addonTable.Event.Func.OnUpdateLow[updaterIndex]
            updater()
        end
    end
end)
