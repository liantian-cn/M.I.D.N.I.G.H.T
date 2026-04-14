local addonName, addonTable = ... -- 插件入口固定写法

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
    local eventFrame = CreateFrame("Frame")
    local controller = CreateAuraController({
        unitKey = UNIT_KEY,
        auraFilter = AURA_FILTER,
        maxAuraCount = MAX_AURA_COUNT,
        baseX = BASE_X,
        baseY = BASE_Y,
        sortRule = SORT_RULE,
        sortDirection = SORT_DIRECTION,
        colorMode = "Harmful",
    })
    controller.refreshAll()

    -- Aura 列表变化时刷新 focus 的整组 debuff 槽位。
    -- 事件用途：处理 focus 的 debuff 结构变化。
    eventFrame:RegisterUnitEvent("UNIT_AURA", UNIT_KEY)
    function eventFrame:UNIT_AURA(unitToken, info)
        -- 因为无法判断isHarmful还是isHelpful，所以只能全量刷新。这个问题在12.0.5修正。等那时候补回来。

        if info.isFullUpdate then
            controller.refreshAll()
            return
        end
        if info.removedAuraInstanceIDs then
            -- for _, instanceID in ipairs(info.removedAuraInstanceIDs) do
            --     controller.removeAura(instanceID)
            -- end
            controller.refreshAll() -- 临时代替，等12.0.5修正API后再改回来
            return                  -- 因为完全刷新了，所以return就行了
        end
        if info.addedAuras then
            -- for _, aura in ipairs(info.addedAuras) do
            --     controller.addAura(aura.auraInstanceID)
            -- end
            controller.refreshAll() -- 临时代替，等12.0.5修正API后再改回来
            return                  -- 因为完全刷新了，所以return就行了
        end
        if info.updatedAuraInstanceIDs then
            -- for _, instanceID in ipairs(info.updatedAuraInstanceIDs) do
            --     controller.updateRemaining(instanceID)
            -- end
            -- 暂时什么都不用做 临时代替，等12.0.5修正API后再改回来
            return -- 因为完全刷新了，所以return就行了
        end
    end

    -- 切换焦点单位时刷新 focus 的整组 debuff 槽位。
    -- 事件用途：处理 focus 槽位整体换人。
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    function eventFrame:PLAYER_FOCUS_CHANGED()
        controller.refreshAll()
    end

    -- 焦点旗标变化时刷新 focus 的整组 debuff 槽位。
    -- 事件用途：处理 focus 可交互状态变化。
    eventFrame:RegisterUnitEvent("UNIT_FLAGS", UNIT_KEY)
    function eventFrame:UNIT_FLAGS(unitToken)
        controller.refreshAll()
    end

    local fastTimeElapsed = -random()     -- 随机初始时间，避免所有事件在同一帧更新
    -- local lowTimeElapsed = -random()      -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            controller.updateRemainingAll()
        end
        -- lowTimeElapsed = lowTimeElapsed + elapsed
        -- if lowTimeElapsed > 0.5 then
        --     lowTimeElapsed = lowTimeElapsed - 0.5
        -- end
        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        --     controller.refreshAll()
        -- end
    end)

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
