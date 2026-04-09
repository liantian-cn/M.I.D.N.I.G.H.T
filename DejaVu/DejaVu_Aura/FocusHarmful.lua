local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local After = C_Timer.After
local random = math.random
local CreateFrame = CreateFrame

-- 插件内引用
local CreateAuraController = addonTable.CreateAuraController

local MAX_AURA_COUNT = 10
local BASE_X = 1
local BASE_Y = 14
local UNIT_KEY = "focus"
local AURA_FILTER = "HARMFUL|PLAYER"
local SORT_RULE = Enum.UnitAuraSortRule.Default
local SORT_DIRECTION = Enum.UnitAuraSortDirection.Normal

After(2, function()
    local controller = CreateAuraController({
        unitKey = UNIT_KEY,
        auraFilter = AURA_FILTER,
        maxAuraCount = MAX_AURA_COUNT,
        baseX = BASE_X,
        baseY = BASE_Y,
        sortRule = SORT_RULE,
        sortDirection = SORT_DIRECTION,
        colorMode = "unitHarmful",
    })
    controller.refreshAll()

    local eventFrame = CreateFrame("eventFrame")
    local fastTimeElapsed = -random()
    local lowTimeElapsed = -random()
    local superLowTimeElapsed = -random()
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        if frame == nil then
            return
        end
        controller.beginFrame()
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            controller.updateRemainingAll()
        end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
        end
        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = superLowTimeElapsed - 2
            controller.refreshAll()
        end
    end)

    function eventFrame:UNIT_AURA(unitToken, info)
        if self == nil or unitToken ~= UNIT_KEY then
            return
        end
        if info.isFullUpdate then
            controller.refreshAll()
            return
        end
        if info.removedAuraInstanceIDs then
            for _, instanceID in ipairs(info.removedAuraInstanceIDs) do
                controller.removeAura(instanceID)
            end
        end
        if info.addedAuras then
            for _, aura in ipairs(info.addedAuras) do
                controller.addAura(aura.auraInstanceID)
            end
        end
        if info.updatedAuraInstanceIDs then
            for _, instanceID in ipairs(info.updatedAuraInstanceIDs) do
                controller.updateRemaining(instanceID)
            end
        end
    end

    function eventFrame:PLAYER_FOCUS_CHANGED()
        if self == nil then
            return
        end
        controller.refreshAll()
    end

    function eventFrame:UNIT_FLAGS(unitToken)
        if self == nil or unitToken ~= UNIT_KEY then
            return
        end
        controller.refreshAll()
    end

    eventFrame:RegisterUnitEvent("UNIT_AURA", UNIT_KEY)
    eventFrame:RegisterUnitEvent("UNIT_FLAGS", UNIT_KEY)
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
