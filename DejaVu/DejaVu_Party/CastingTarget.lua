local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local pairs = pairs
local random = math.random

-- WoW 官方 API
local UnitName = UnitName
local issecretvalue = issecretvalue
local After = C_Timer.After
local CreateFrame = CreateFrame
local UnitExists = UnitExists


local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell


local party_members = {
    "player",
    "party1",
    "party2",
    "party3",
    "party4",
}

After(2, function()
    local cell = {
        player = Cell:New(61, 14),
        party1 = Cell:New(19, 24),
        party2 = Cell:New(40, 24),
        party3 = Cell:New(61, 24),
        party4 = Cell:New(82, 24),
    }
    local eventFrame = CreateFrame("Frame") -- 事件框架


    local function setUnitCasting(unitToken)
        for k, c in pairs(cell) do
            if k == unitToken then
                c:setCell(COLOR.WHITE)
            else
                c:setCell(COLOR.BLACK)
            end
        end
    end

    local function clearUnitCasting(unitToken)
        cell[unitToken]:setCell(COLOR.BLACK)
    end

    local currentCastingTarget = nil

    -- 某个队友断线、离开可交互状态时刷新当前槽位
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
    function eventFrame:UNIT_SPELLCAST_SENT(unitTarget, targetName, castGUID, spellID)
        if not issecretvalue(targetName) then
            for _, partyUnit in pairs(party_members) do
                if UnitExists(partyUnit) and (UnitName(partyUnit) == targetName) then
                    currentCastingTarget = partyUnit
                    -- print("当前施法目标:", partyUnit, targetName)
                    setUnitCasting(partyUnit)
                    break
                end
            end
            -- print(state.castTargetUnit, state.castTargetName, state.castTargetIndex)
        end
    end

    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    function eventFrame:UNIT_SPELLCAST_INTERRUPTED()
        clearUnitCasting(currentCastingTarget)
        currentCastingTarget = nil
        -- print("施法被打断，清除施法目标")
    end

    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    function eventFrame:UNIT_SPELLCAST_STOP()
        clearUnitCasting(currentCastingTarget)
        currentCastingTarget = nil
        -- print("施法结束，清除施法目标")
    end

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)

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
            -- updateMaxHealth()
            -- updateDamageAbsorbs()
            -- updateHealAbsorbs()
        end
    end)
end)
