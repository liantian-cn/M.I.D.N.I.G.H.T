local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local After = C_Timer.After
local random = math.random
local format = string.format
-- WoW 官方 API
local CreateFrame = CreateFrame


local DejaVu_Aura = _G["DejaVu_Aura"]

-- 插件内引用
local CreateAuraController = DejaVu_Aura.CreateAuraController

local MAX_AURA_COUNT = 3
local BASE_Y = 19
-- local AURA_FILTER = "HELPFUL"
local AURA_FILTER = "HARMFUL"
local SORT_RULE = Enum.UnitAuraSortRule.Default
local SORT_DIRECTION = Enum.UnitAuraSortDirection.Reverse


After(2, function()
    for partyIndex = 1, 4 do
        local eventFrame = CreateFrame("Frame")
        local UNIT_KEY = format("party%d", partyIndex)
        local BASE_X = 21 * partyIndex - 6
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

        -- Aura 列表变化时按当前限制做整组刷新当前 party 槽位的减益显示。
        -- 事件用途：处理当前 party 槽位的减益结构变化。
        -- 当前没有 2 秒全量补正，只有 0.1 秒的剩余时间补正。
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

        -- 队友旗标变化时重刷当前 party 槽位的减益显示。
        -- 事件用途：处理上下线和可交互状态变化。
        -- 当前没有单独 2 秒补正。
        eventFrame:RegisterUnitEvent("UNIT_FLAGS", UNIT_KEY)
        function eventFrame:UNIT_FLAGS(unitToken)
            controller.refreshAll()
        end

        local GroupChangeOnFrame = false

        -- 队伍名单变化时重刷当前 party 槽位。
        -- 事件用途：处理 party 槽位整体换人。
        -- 当前没有单独 2 秒补正。
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        function eventFrame:GROUP_ROSTER_UPDATE()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            controller.refreshAll()
        end

        -- 加入队伍时重刷当前 party 槽位。
        -- 事件用途：处理新 party 结构建立。
        -- 当前没有单独 2 秒补正。
        eventFrame:RegisterEvent("GROUP_JOINED")
        function eventFrame:GROUP_JOINED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            controller.refreshAll()
        end

        -- 离开队伍时重刷当前 party 槽位。
        -- 事件用途：处理 party 槽位清空或前移。
        -- 当前没有单独 2 秒补正。
        eventFrame:RegisterEvent("GROUP_LEFT")
        function eventFrame:GROUP_LEFT()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            controller.refreshAll()
        end

        -- 新队伍形成时重刷当前 party 槽位。
        -- 事件用途：处理 party 槽位整体重建。
        -- 当前没有单独 2 秒补正。
        eventFrame:RegisterEvent("GROUP_FORMED")
        function eventFrame:GROUP_FORMED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            controller.refreshAll()
        end

        local fastTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
        -- local lowTimeElapsed = -random()      -- 当前未使用，保留 0.5 秒刷新档位结构
        -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
        eventFrame:HookScript("OnUpdate", function(frame, elapsed)
            GroupChangeOnFrame = false -- 每帧重置，避免同一帧内重复处理多个队伍结构事件
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
    end
end)
