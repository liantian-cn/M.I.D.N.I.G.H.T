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

addonTable.Event.Func.OnEvent_Aura = {}
addonTable.Event.Func.OnEvent_Spell = {}
addonTable.Event.Func.SPELLS_CHANGED = {}
addonTable.Event.Func.SPELL_UPDATE_ICON = {}
addonTable.Event.Func.PLAYER_TALENT_UPDATE = {}
addonTable.Event.Func.TRAIT_CONFIG_UPDATED = {}


local eventFrame = CreateFrame("EventFrame", addonName .. "Frame")
addonTable.Event.Frame = eventFrame

function eventFrame:PLAYER_ENTERING_WORLD()
    C_Timer.After(0, function()
        wipe(addonTable.Event.Func.OnUpdateHigh)
        wipe(addonTable.Event.Func.OnUpdateLow)

        wipe(addonTable.Event.Func.OnEvent_Aura)
        wipe(addonTable.Event.Func.OnEvent_Spell)

        for _, func in ipairs(addonTable.Event.Func.InitUI) do
            func()
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function eventFrame:SPELLS_CHANGED()
    for _, func in ipairs(addonTable.Event.Func.SPELLS_CHANGED) do
        func()
    end
end

function eventFrame:SPELL_UPDATE_ICON()
    for _, func in ipairs(addonTable.Event.Func.SPELL_UPDATE_ICON) do
        func()
    end
end

function eventFrame:PLAYER_TALENT_UPDATE()
    for _, func in ipairs(addonTable.Event.Func.PLAYER_TALENT_UPDATE) do
        func()
    end
end

function eventFrame:TRAIT_CONFIG_UPDATED()
    for _, func in ipairs(addonTable.Event.Func.TRAIT_CONFIG_UPDATED) do
        func()
    end
end

-- 注册事件
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- eventFrame:RegisterEvent("UNIT_AURA")
-- eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
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
        for _, updater in ipairs(addonTable.Event.Func.OnUpdateHigh) do
            updater()
        end
    end
    if lowFrequencyTimeElapsed > lowFrequencyTickOffset then
        lowFrequencyTimeElapsed = 0
        for _, updater in ipairs(addonTable.Event.Func.OnUpdateLow) do
            updater()
        end
    end
end)
