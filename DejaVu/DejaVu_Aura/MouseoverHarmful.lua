local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local After = C_Timer.After
local random = math.random
local CreateFrame = CreateFrame

-- 插件内引用
local CreateAuraController = addonTable.CreateAuraController

local MAX_AURA_COUNT = 16
local BASE_X = 22
local BASE_Y = 14
local UNIT_KEY = "mouseover"
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
        colorMode = "Harmful",
    })
    controller.refreshAll()

    local eventFrame = CreateFrame("Frame")

    -- 预留鼠标指向 aura 事件处理骨架。
    -- 事件用途：如果后续找到可靠的 mouseover aura 事件，可复用这里。
    -- 当前没有注册，也没有 2 秒补正；实际刷新靠 0.5 秒轮询。
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

    -- function eventFrame:UPDATE_MOUSEOVER_UNIT()
    --     -- controller.refreshAll()
    -- end

    -- function eventFrame:CURSOR_CHANGED()
    --     controller.refreshAll()
    -- end

    -- function eventFrame:UNIT_FLAGS(unitToken)
    --     controller.refreshAll()
    -- end

    -- eventFrame:RegisterUnitEvent("UNIT_AURA", UNIT_KEY)
    -- eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") -- 当鼠标移开时不会触发UPDATE_MOUSEOVER_UNIT事件，所以只能放弃
    -- eventFrame:RegisterEvent("CURSOR_CHANGED")
    -- eventFrame:RegisterUnitEvent("UNIT_FLAGS", UNIT_KEY)
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)

    -- local fastTimeElapsed = -random()     -- 当前未使用，保留 0.1 秒刷新档位结构
    local lowTimeElapsed = -random()
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        -- fastTimeElapsed = fastTimeElapsed + elapsed
        -- if fastTimeElapsed > 0.1 then
        --     fastTimeElapsed = fastTimeElapsed - 0.1
        --     controller.updateRemainingAll()
        --     controller.refreshAll()
        -- end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
            controller.refreshAll()
        end
        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        -- end
    end)
end)

-- 鼠标指向没有事件精准捕获。干脆.5秒更新一次。而且时间无需更新，毕竟指向要在变。
