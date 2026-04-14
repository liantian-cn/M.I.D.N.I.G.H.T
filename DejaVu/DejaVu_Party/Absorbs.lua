local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local After = C_Timer.After
local random = math.random

-- WoW 官方 API
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitHealthMax = UnitHealthMax

local DejaVu = _G["DejaVu"]
local Bar = DejaVu.Bar




After(2, function()
    for partyIndex = 1, 4 do
        local eventFrame = CreateFrame("Frame") -- 事件框架
        local UNIT_KEY = format("party%d", partyIndex)

        local BASE_X = 21 * partyIndex

        local unitExists = false
        local damageAbsorbsBar = Bar:New(BASE_X - 20, 24, 10)
        local healAbsorbsBar = Bar:New(BASE_X - 20, 25, 10)
        -- local inCominngHealsBar = Bar:New(BASE_X - 20, 24, 10, true)

        -- 更新当前队友吸收条的刻度范围。
        -- 基于 UNIT_MAXHEALTH 事件。
        -- 2 秒补正时会在 updateAll 里一起补正。
        local function updateMaxHealth()
            local maxHealth = UnitHealthMax(UNIT_KEY) or 0
            damageAbsorbsBar:setMinMaxValues(0, maxHealth / 2)
            healAbsorbsBar:setMinMaxValues(0, maxHealth / 2)
            -- inCominngHealsBar:setMinMaxValues(0, maxHealth / 2)
        end

        -- 更新当前队友的伤害吸收条数值。
        -- 基于 UNIT_ABSORB_AMOUNT_CHANGED 事件。
        -- 2 秒补正时会在 updateAll 里一起补正。
        local function updateDamageAbsorbs()
            if unitExists then
                damageAbsorbsBar:setValue(UnitGetTotalAbsorbs(UNIT_KEY) or 0)
            else
                damageAbsorbsBar:setValue(0)
            end
        end

        -- 更新当前队友的治疗吸收条数值。
        -- 基于 UNIT_HEAL_ABSORB_AMOUNT_CHANGED 事件。
        -- 2 秒补正时会在 updateAll 里一起补正。
        local function updateHealAbsorbs()
            if unitExists then
                healAbsorbsBar:setValue(UnitGetTotalHealAbsorbs(UNIT_KEY) or 0)
            else
                healAbsorbsBar:setValue(0)
            end
        end

        -- 最大生命值变化时同步刻度，并顺手重刷两条吸收条。
        -- 事件用途：处理吸收条刻度变化。
        -- 2 秒补正：通过 updateAll 间接补正。
        eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", UNIT_KEY)
        function eventFrame:UNIT_MAXHEALTH(unitToken)
            updateMaxHealth()
            updateDamageAbsorbs()
            updateHealAbsorbs()
        end

        -- 伤害吸收变化时只刷新伤害吸收条。
        -- 事件用途：处理 UNIT_ABSORB_AMOUNT_CHANGED。
        -- 2 秒补正：通过 updateAll 间接补正。
        eventFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", UNIT_KEY)
        function eventFrame:UNIT_ABSORB_AMOUNT_CHANGED(unitToken)
            updateDamageAbsorbs()
        end

        -- 治疗吸收变化时只刷新治疗吸收条。
        -- 事件用途：处理 UNIT_HEAL_ABSORB_AMOUNT_CHANGED。
        -- 2 秒补正：通过 updateAll 间接补正。
        eventFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", UNIT_KEY)
        function eventFrame:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(unitToken)
            updateHealAbsorbs()
        end

        -- 即将收到的治疗更新时只刷新即将收到的治疗条。
        -- 事件用途：处理 UNIT_HEAL_PREDICTION_CHANGED。
        -- 2 秒补正：在 superLowTimeElapsed 档位里单独
        -- 补正。

        -- local function updateIncomingHeals()
        --     inCominngHealsBar:setValue(UnitGetIncomingHeals(UNIT_KEY) or 0)
        -- end

        -- function eventFrame:UNIT_HEAL_PREDICTION(unitToken)
        --     updateIncomingHeals()
        -- end

        -- eventFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", UNIT_KEY)



        local updateUnitExists = function()
            unitExists = UnitExists(UNIT_KEY)
        end

        -- 当前 party 槽位的整组吸收状态刷新。
        -- 用于队伍结构变化、上下线以及 2 秒低频补正。
        local updateAll = function()
            updateUnitExists()
            updateMaxHealth()
            updateDamageAbsorbs()
            updateHealAbsorbs()
            -- updateIncomingHeals()
        end

        local GroupChangeOnFrame = false

        -- 队伍成员变化时对应的 party 槽位可能整体换人，直接全刷
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        function eventFrame:GROUP_ROSTER_UPDATE()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 玩家加入队伍后，party 槽位重新分配，直接全刷
        eventFrame:RegisterEvent("GROUP_JOINED")
        function eventFrame:GROUP_JOINED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 玩家离队后，party 槽位可能清空或前移，直接全刷
        eventFrame:RegisterEvent("GROUP_LEFT")
        function eventFrame:GROUP_LEFT()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 新队伍形成时，party 槽位整体重建，直接全刷
        eventFrame:RegisterEvent("GROUP_FORMED")
        function eventFrame:GROUP_FORMED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 某个队友重新上线、进出可交互状态时刷新当前槽位
        eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
        function eventFrame:PARTY_MEMBER_ENABLE(unitToken)
            if unitToken == UNIT_KEY then
                updateAll()
            end
        end

        -- 某个队友断线、离开可交互状态时刷新当前槽位
        eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
        function eventFrame:PARTY_MEMBER_DISABLE(unitToken)
            if unitToken == UNIT_KEY then
                updateAll()
            end
        end

        -- local fastTimeElapsed = -random()     -- 当前未使用，保留 0.1 秒刷新档位结构
        -- local lowTimeElapsed = -random()      -- 当前未使用，保留 0.5 秒刷新档位结构
        local superLowTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
        eventFrame:HookScript("OnUpdate", function(frame, elapsed)
            GroupChangeOnFrame = false        -- 每帧重置触发器状态，确保状态更新函数在同一帧内只执行一次

            -- fastTimeElapsed = fastTimeElapsed + elapsed
            -- if fastTimeElapsed > 0.1 then
            --     fastTimeElapsed = fastTimeElapsed - 0.1
            -- end
            -- lowTimeElapsed = lowTimeElapsed + elapsed
            -- if lowTimeElapsed > 0.5 then
            --     lowTimeElapsed = lowTimeElapsed - 0.5
            -- end
            superLowTimeElapsed = superLowTimeElapsed + elapsed
            if superLowTimeElapsed > 2 then
                superLowTimeElapsed = superLowTimeElapsed - 2
                updateAll()
                -- updateMaxHealth()
                -- updateDamageAbsorbs()
                -- updateHealAbsorbs()
            end
        end)

        eventFrame:SetScript("OnEvent", function(self, event, ...)
            self[event](self, ...)
        end)
    end
end)
