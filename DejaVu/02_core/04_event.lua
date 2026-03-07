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
addonTable.UpdateFunc = {}

addonTable.UpdateFunc.InitUI = {}

addonTable.UpdateFunc.OnUpdateHigh = {}
addonTable.UpdateFunc.OnUpdateLow = {}


addonTable.UpdateFunc.SPELLS_CHANGED = {}
addonTable.UpdateFunc.PLAYER_TALENT_CHANGED = {} -- 所有涉及天赋变化的事件
addonTable.UpdateFunc.UNIT_AURA = {}
addonTable.UpdateFunc.TARGET_CHANGED = {}        -- 目标改变时触发，并不存在这个事件，多个事件会触发这个事件
addonTable.UpdateFunc.FOCUS_CHANGED = {}         -- 焦点改变时触发，并不存在这个事件，多个事件会触发这个事件
addonTable.UpdateFunc.MOUSEOVER_CHANGED = {}     -- 鼠标悬停改变时触发，并不存在这个事件，多个事件会触发这个事件



local eventThisFrame = {} -- 帧内放重复

local eventFrame = CreateFrame("EventFrame", addonName .. "Frame")
addonTable.Event.Frame = eventFrame

function eventFrame:PLAYER_ENTERING_WORLD()
    C_Timer.After(0, function()
        wipe(addonTable.UpdateFunc.OnUpdateHigh)
        wipe(addonTable.UpdateFunc.OnUpdateLow)


        for funcIndex = 1, #addonTable.UpdateFunc.InitUI do
            local func = addonTable.UpdateFunc.InitUI[funcIndex]
            func()
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function eventFrame:SPELLS_CHANGED()
    if eventThisFrame["SPELLS_CHANGED"] then
        return
    end
    eventThisFrame["SPELLS_CHANGED"] = true
    for funcIndex = 1, #addonTable.UpdateFunc.SPELLS_CHANGED do
        local func = addonTable.UpdateFunc.SPELLS_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:SPELL_UPDATE_ICON()
    self:SPELLS_CHANGED()
end

function eventFrame:PLAYER_TALENT_CHANGED()
    if eventThisFrame["PLAYER_TALENT_CHANGED"] then
        return
    end
    eventThisFrame["PLAYER_TALENT_CHANGED"] = true
    for funcIndex = 1, #addonTable.UpdateFunc.PLAYER_TALENT_CHANGED do
        local func = addonTable.UpdateFunc.PLAYER_TALENT_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:PLAYER_TALENT_UPDATE()
    self:PLAYER_TALENT_CHANGED()
end

function eventFrame:TRAIT_CONFIG_UPDATED()
    self:PLAYER_TALENT_CHANGED()
end

function eventFrame:PLAYER_TARGET_CHANGED()
    if eventThisFrame["PLAYER_TARGET_CHANGED"] then
        return
    end
    eventThisFrame["PLAYER_TARGET_CHANGED"] = true
    for funcIndex = 1, #addonTable.UpdateFunc.TARGET_CHANGED do
        local func = addonTable.UpdateFunc.TARGET_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:PLAYER_FOCUS_CHANGED()
    if eventThisFrame["PLAYER_FOCUS_CHANGED"] then
        return
    end
    eventThisFrame["PLAYER_FOCUS_CHANGED"] = true
    for funcIndex = 1, #addonTable.UpdateFunc.FOCUS_CHANGED do
        local func = addonTable.UpdateFunc.FOCUS_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:MOUSEOVER_CHANGED()
    if eventThisFrame["MOUSEOVER_CHANGED"] then
        return
    end
    eventThisFrame["MOUSEOVER_CHANGED"] = true
    for funcIndex = 1, #addonTable.UpdateFunc.MOUSEOVER_CHANGED do
        local func = addonTable.UpdateFunc.MOUSEOVER_CHANGED[funcIndex]
        func()
    end
end

function eventFrame:UPDATE_MOUSEOVER_UNIT()
    self:MOUSEOVER_CHANGED()
end

function eventFrame:UNIT_AURA(unitTarget)
    for funcIndex = 1, #addonTable.UpdateFunc.UNIT_AURA do
        local updaterInfo = addonTable.UpdateFunc.UNIT_AURA[funcIndex]
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
eventFrame:RegisterEvent("TRAIT_NODE_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)


-- 时间流逝变量
local timeElapsed = 0
local lowFrequencyTimeElapsed = 0
-- 钩子OnUpdate脚本，用于定时更新
eventFrame:HookScript("OnUpdate", function(self, elapsed)
    wipe(eventThisFrame)
    local tickOffset             = 1.0 / 10;
    local lowFrequencyTickOffset = 1.0 / 2;
    timeElapsed                  = timeElapsed + elapsed
    lowFrequencyTimeElapsed      = lowFrequencyTimeElapsed + elapsed
    if timeElapsed > tickOffset then
        timeElapsed = 0
        for updaterIndex = 1, #addonTable.UpdateFunc.OnUpdateHigh do
            local updater = addonTable.UpdateFunc.OnUpdateHigh[updaterIndex]
            updater()
        end
    end
    if lowFrequencyTimeElapsed > lowFrequencyTickOffset then
        lowFrequencyTimeElapsed = 0
        for updaterIndex = 1, #addonTable.UpdateFunc.OnUpdateLow do
            local updater = addonTable.UpdateFunc.OnUpdateLow[updaterIndex]
            updater()
        end
    end
end)
