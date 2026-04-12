local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local After = C_Timer.After
local random = math.random
local min = math.min
local insert = table.insert

-- WoW 官方 API
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitHealthMax = UnitHealthMax

local DejaVu = _G["DejaVu"]
local Bar = DejaVu.Bar


After(2, function()
    local eventFrame = CreateFrame("Frame") -- 事件框架
    local damageAbsorbsBar = Bar:New(43, 16, 20)
    local healAbsorbsBar = Bar:New(64, 14, 20)

    -- 更新玩家两条吸收条的刻度范围。
    -- 基于 UNIT_MAXHEALTH 事件。
    -- 2 秒补正时会单独再次调用这组更新函数。
    local function updateMaxHealth()
        local maxHealth = UnitHealthMax("player") or 0
        damageAbsorbsBar:setMinMaxValues(0, maxHealth)
        healAbsorbsBar:setMinMaxValues(0, maxHealth)
    end

    -- 更新玩家的伤害吸收条数值。
    -- 基于 UNIT_ABSORB_AMOUNT_CHANGED 事件。
    -- 2 秒补正时会单独再次调用这组更新函数。
    local function updateDamageAbsorbs()
        damageAbsorbsBar:setValue(UnitGetTotalAbsorbs("player") or 0)
    end

    -- 更新玩家的治疗吸收条数值。
    -- 基于 UNIT_HEAL_ABSORB_AMOUNT_CHANGED 事件。
    -- 2 秒补正时会单独再次调用这组更新函数。
    local function updateHealAbsorbs()
        healAbsorbsBar:setValue(UnitGetTotalHealAbsorbs("player") or 0)
    end

    -- 最大生命值变化时同步刻度，并顺手重刷两条吸收条。
    -- 事件用途：处理吸收条刻度变化。
    -- 2 秒补正：在 superLowTimeElapsed 档位里单独补正。
    function eventFrame:UNIT_MAXHEALTH(unitToken)
        updateMaxHealth()
        updateDamageAbsorbs()
        updateHealAbsorbs()
    end
    eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")

    -- 伤害吸收变化时只刷新伤害吸收条。
    -- 事件用途：处理 UNIT_ABSORB_AMOUNT_CHANGED。
    -- 2 秒补正：在 superLowTimeElapsed 档位里单独补正。
    function eventFrame:UNIT_ABSORB_AMOUNT_CHANGED(unitToken)
        updateDamageAbsorbs()
    end
    eventFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")

    -- 治疗吸收变化时只刷新治疗吸收条。
    -- 事件用途：处理 UNIT_HEAL_ABSORB_AMOUNT_CHANGED。
    -- 2 秒补正：在 superLowTimeElapsed 档位里单独补正。
    function eventFrame:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(unitToken)
        updateHealAbsorbs()
    end
    eventFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")

    -- local fastTimeElapsed = -random()     -- 当前未使用，保留 0.1 秒刷新档位结构
    -- local lowTimeElapsed = -random()      -- 当前未使用，保留 0.5 秒刷新档位结构
    local superLowTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
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
            updateMaxHealth()
            updateDamageAbsorbs()
            updateHealAbsorbs()
        end
    end)

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
