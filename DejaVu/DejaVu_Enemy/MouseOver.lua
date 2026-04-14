local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local pairs = pairs
local random = math.random
local select = select

-- WoW 官方 API
local After = C_Timer.After
local CreateColor = CreateColor
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local Enum = Enum
local CreateFrame = CreateFrame
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAttack = UnitCanAttack
local UnitCastingDuration = UnitCastingDuration
local UnitCastingInfo = UnitCastingInfo
local UnitChannelDuration = UnitChannelDuration
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHealthPercent = UnitHealthPercent
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsEnemy = UnitIsEnemy
local UnitIsUnit = UnitIsUnit
local UnitPowerPercent = UnitPowerPercent
local UnitPowerType = UnitPowerType

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell
local RangedRange = DejaVu.RangedRange -- 默认的远程检测范围
local MeleeRange = DejaVu.MeleeRange   -- 默认的近战检测范围

local LibStub = LibStub
local LRC = LibStub("LibRangeCheck-3.0")
if not LRC then
    print("|cffff0000[单位状态]|r LibRangeCheck-3.0 未找到, 模块无法工作。")
    return
end

local zeroToOneCurve = CreateColorCurve()
zeroToOneCurve:SetType(Enum.LuaCurveType.Linear)
zeroToOneCurve:AddPoint(0.0, CreateColor(0, 0, 0, 1))
zeroToOneCurve:AddPoint(1.0, CreateColor(1, 1, 1, 1))

local cell = {}                             -- 状态单元格，提供给外部调用以更新状态显示
local UNIT_KEY = "mouseover"                -- 目标单位
local posX = 70                             -- 起始 x 坐标
local posY = 12                             -- 起始 y 坐标

After(2, function()                         -- 延迟加载
    local eventFrame = CreateFrame("Frame") -- 事件框架

    local unitExists = false
    local inCasting = false
    local inChanneling = false
    local updateAll

    cell.exists = Cell:New(posX + 0, posY + 0)                  -- 单位存在状态 / updateUnitExists
    cell.isAlive = Cell:New(posX + 0, posY + 1)                 -- 单位是否存活 / updateUnitBasicStatus
    cell.unitClass = Cell:New(posX + 1, posY + 0)               -- 单位职业 / updateClassAndRole
    cell.unitRole = Cell:New(posX + 1, posY + 1)                -- 单位角色 / updateClassAndRole
    cell.healthPercent = Cell:New(posX + 2, posY + 0)           -- 单位生命值百分比 / updateHealth
    cell.powerPercent = Cell:New(posX + 2, posY + 1)            -- 单位能量百分比 / updatePower
    cell.isEnemy = Cell:New(posX + 3, posY + 0)                 -- 单位是否敌对 / updateUnitBasicStatus
    cell.canAttack = Cell:New(posX + 3, posY + 1)               -- 单位是否可攻击 / updateUnitBasicStatus
    cell.isInRangedRange = Cell:New(posX + 4, posY + 0)         -- 单位是否在远程范围内 / updateRangeStatus
    cell.isInMeleeRange = Cell:New(posX + 4, posY + 1)          -- 单位是否在近战范围内 / updateRangeStatus
    cell.isInCombat = Cell:New(posX + 5, posY + 0)              -- 单位是否在战斗中 / updateUnitBasicStatus
    cell.isTarget = Cell:New(posX + 5, posY + 1)                -- 单位是否为目标 / updateUnitBasicStatus
    cell.castIcon = BadgeCell:New(posX + 6, posY + 0)           -- 单位施法图标 / updateCastAndChannel
    cell.channelIcon = BadgeCell:New(posX + 8, posY + 0)        -- 单位通道图标 / updateCastAndChannel
    cell.castDuration = Cell:New(posX + 10, posY + 0)           -- 单位施法持续时间 / updateCastAndChannelDuration
    cell.channelDuration = Cell:New(posX + 10, posY + 1)        -- 单位通道持续时间 / updateCastAndChannelDuration
    cell.castIsInterruptible = Cell:New(posX + 11, posY + 0)    -- 单位施法是否可中断 / updateCastAndChannel
    cell.channelIsInterruptible = Cell:New(posX + 11, posY + 1) -- 单位通道是否可中断 / updateCastAndChannel

    local function clearAll()
        cell.exists:clearCell()                 -- 单位存在状态 / updateUnitExists
        cell.isAlive:clearCell()                -- 单位是否存活
        cell.unitClass:clearCell()              -- 单位职业
        cell.unitRole:clearCell()               -- 单位角色
        cell.healthPercent:clearCell()          -- 单位生命值百分比 / updateHealth
        cell.powerPercent:clearCell()           -- 单位能量百分比 / updatePower
        cell.isEnemy:clearCell()                -- 单位是否敌对
        cell.canAttack:clearCell()              -- 单位是否可攻击
        cell.isInRangedRange:clearCell()        -- 单位是否在远程范围 / updateRangeStatus
        cell.isInMeleeRange:clearCell()         -- 单位是否在近战范围 / updateRangeStatus
        cell.isInCombat:clearCell()             -- 单位是否在战斗中 / updateUnitBasicStatus
        cell.isTarget:clearCell()               -- 单位是否为目标 / updateUnitBasicStatus
        cell.castIcon:clearCell()               -- 单位施法图标 / updateCastAndChannel
        cell.channelIcon:clearCell()            -- 单位通道图标 / updateCastAndChannel
        cell.castDuration:clearCell()           -- 单位施法持续时间 / updateCastAndChannelDuration
        cell.channelDuration:clearCell()        -- 单位通道持续时间 / updateCastAndChannelDuration
        cell.castIsInterruptible:clearCell()    -- 单位施法是否可中断 / updateCastAndChannel
        cell.channelIsInterruptible:clearCell() -- 单位通道是否可中断 / updateCastAndChannel
    end

    -- 检测鼠标指向单位是否存在，更新存在状态。
    -- 当前无可靠事件，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateUnitExists()
        unitExists = UnitExists(UNIT_KEY)

        if not unitExists then
            inCasting = false
            inChanneling = false
            clearAll()
            return
        end

        cell.exists:setCell(COLOR.STATUS_BOOLEAN.EXISTS) -- 单位存在状态
    end


    -- 更新鼠标指向单位的职业和角色。
    -- 当前无可靠事件，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateClassAndRole()
        if not unitExists then
            return
        end

        cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass(UNIT_KEY))])                    -- 单位职业
        cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned(UNIT_KEY)] or COLOR.ROLE.NONE) -- 单位角色
    end

    -- 更新鼠标指向单位的生命值百分比。
    -- 事件骨架已保留但当前未注册，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateHealth()
        if not unitExists then
            return
        end

        cell.healthPercent:setCell(UnitHealthPercent(UNIT_KEY, false, zeroToOneCurve)) -- 单位生命值百分比
    end

    -- 最大生命值变化时刷新生命值百分比。
    -- 事件用途：处理 UNIT_MAXHEALTH。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", UNIT_KEY)

    -- function eventFrame.UNIT_MAXHEALTH()
    --     updateHealth()
    -- end

    -- 当前生命值变化时刷新生命值百分比。
    -- 事件用途：处理 UNIT_HEALTH。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_HEALTH", UNIT_KEY)

    -- function eventFrame.UNIT_HEALTH()
    --     updateHealth()
    -- end

    -- 更新鼠标指向单位的能量百分比。
    -- 事件骨架已保留但当前未注册，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updatePower()
        if not unitExists then
            return
        end

        cell.powerPercent:setCell(UnitPowerPercent(UNIT_KEY, UnitPowerType(UNIT_KEY), false, zeroToOneCurve)) -- 单位能量百分比
    end

    -- 能量变化时刷新能量百分比。
    -- 事件用途：处理 UNIT_POWER_UPDATE。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", UNIT_KEY)

    -- function eventFrame.UNIT_POWER_UPDATE()
    --     updatePower()
    -- end

    -- 更新鼠标指向单位的基础状态。
    -- 当前无可靠事件，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateUnitBasicStatus()
        if not unitExists then
            return
        end

        cell.isAlive:setCellBoolean(UnitIsDeadOrGhost(UNIT_KEY), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE) -- 单位是否存活
        cell.isEnemy:setCellBoolean(UnitIsEnemy(UNIT_KEY, "player"), COLOR.STATUS_BOOLEAN.IS_ENEMY, COLOR.BLACK)
        cell.canAttack:setCellBoolean(UnitCanAttack("player", UNIT_KEY), COLOR.STATUS_BOOLEAN.CAN_ATTACK, COLOR.BLACK)
        cell.isInCombat:setCellBoolean(UnitAffectingCombat(UNIT_KEY), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK)
        cell.isTarget:setCellBoolean(UnitIsUnit(UNIT_KEY, "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)
    end

    -- 更新鼠标指向单位的距离状态。
    -- 当前无可靠事件，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateRangeStatus()
        if not unitExists then
            return
        end
        local maxRange = select(2, LRC:GetRange(UNIT_KEY)) or 99

        cell.isInRangedRange:setCellBoolean(
            maxRange <= RangedRange,
            COLOR.STATUS_BOOLEAN.IS_IN_RANGED_RANGE,
            COLOR.BLACK
        )

        cell.isInMeleeRange:setCellBoolean(
            maxRange <= MeleeRange,
            COLOR.STATUS_BOOLEAN.IS_IN_MELEE_RANGE,
            COLOR.BLACK
        )
    end

    local function getSpellColor()
        local spellInterruptibleColor = COLOR.SPELL_TYPE.ENEMY_SPELL_INTERRUPTIBLE
        local spellNotInterruptibleColor = COLOR.SPELL_TYPE.ENEMY_SPELL_NOT_INTERRUPTIBLE

        if not UnitCanAttack("player", UNIT_KEY) then
            spellInterruptibleColor = COLOR.SPELL_TYPE.PLAYER_SPELL
            spellNotInterruptibleColor = COLOR.SPELL_TYPE.PLAYER_SPELL
        end

        return spellInterruptibleColor, spellNotInterruptibleColor
    end

    -- 更新鼠标指向单位的施法和通道状态。
    -- 事件骨架已保留但当前未注册，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateCastAndChannel()
        if not unitExists then
            return
        end

        local spellInterruptibleColor, spellNotInterruptibleColor = getSpellColor()
        local castIcon = select(3, UnitCastingInfo(UNIT_KEY))
        local castNotInterruptible = select(8, UnitCastingInfo(UNIT_KEY))
        if castIcon then
            inCasting = true
            inChanneling = false
            cell.castIcon:setCell(
                castIcon,
                EvaluateColorFromBoolean(castNotInterruptible, spellNotInterruptibleColor, spellInterruptibleColor)
            ) -- 单位施法图标
            cell.castIsInterruptible:setCellBoolean(
                castNotInterruptible,
                spellNotInterruptibleColor,
                spellInterruptibleColor
            )                                       -- 单位施法是否可中断
            cell.channelIcon:clearCell()            -- 单位通道图标
            cell.channelIsInterruptible:clearCell() -- 单位通道是否可中断
            cell.channelDuration:clearCell()        -- 单位通道持续时间
            return
        end

        inCasting = false
        cell.castIcon:clearCell()            -- 单位施法图标
        cell.castIsInterruptible:clearCell() -- 单位施法是否可中断

        local channelIcon = select(3, UnitChannelInfo(UNIT_KEY))
        local channelNotInterruptible = select(7, UnitChannelInfo(UNIT_KEY))
        if channelIcon then
            inChanneling = true
            cell.channelIcon:setCell(
                channelIcon,
                EvaluateColorFromBoolean(channelNotInterruptible, spellNotInterruptibleColor, spellInterruptibleColor)
            ) -- 单位通道图标
            cell.channelIsInterruptible:setCellBoolean(
                channelNotInterruptible,
                spellNotInterruptibleColor,
                spellInterruptibleColor
            )                                    -- 单位通道是否可中断
            cell.castIcon:clearCell()            -- 单位施法图标
            cell.castIsInterruptible:clearCell() -- 单位施法是否可中断
            cell.castDuration:clearCell()        -- 单位施法持续时间
            return
        end

        inChanneling = false
        cell.channelIcon:clearCell()            -- 单位通道图标
        cell.channelIsInterruptible:clearCell() -- 单位通道是否可中断
    end

    -- 施法被打断时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_INTERRUPTED。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_INTERRUPTED()
    --     updateCastAndChannel()
    -- end

    -- 开始施法时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_START。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_START()
    --     updateCastAndChannel()
    -- end

    -- 施法结束时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_STOP。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_STOP()
    --     updateCastAndChannel()
    -- end

    -- 施法成功时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_SUCCEEDED。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_SUCCEEDED()
    --     updateCastAndChannel()
    -- end

    -- 开始通道时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_CHANNEL_START。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_CHANNEL_START()
    --     updateCastAndChannel()
    -- end

    -- 通道结束时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_CHANNEL_STOP。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_CHANNEL_STOP()
    --     updateCastAndChannel()
    -- end

    -- 施法失败时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_FAILED。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_FAILED()
    --     updateCastAndChannel()
    -- end

    -- 通道进度更新时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_CHANNEL_UPDATE。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_CHANNEL_UPDATE()
    --     updateCastAndChannel()
    -- end

    -- 引导蓄力开始时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_EMPOWER_START。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_EMPOWER_START()
    --     updateCastAndChannel()
    -- end

    -- 引导蓄力结束时刷新鼠标指向单位的施法显示。
    -- 事件用途：处理 UNIT_SPELLCAST_EMPOWER_STOP。
    -- 当前保留注释骨架，不恢复注册，实际依赖 0.1 秒整组轮询。
    -- eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", UNIT_KEY)

    -- function eventFrame.UNIT_SPELLCAST_EMPOWER_STOP()
    --     updateCastAndChannel()
    -- end

    -- 更新施法和通道的进度颜色。
    -- 当前无可靠事件，实际依赖 0.1 秒整组轮询。
    -- 当前无 2 秒补正。
    local function updateCastAndChannelDuration()
        if not unitExists then
            return
        end

        local castDuration = inCasting and UnitCastingDuration(UNIT_KEY) or nil
        if castDuration then
            cell.castDuration:setCell(castDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位施法持续时间
        else
            cell.castDuration:clearCell()                                                  -- 单位施法持续时间
        end

        local channelDuration = inChanneling and UnitChannelDuration(UNIT_KEY) or nil
        if channelDuration then
            cell.channelDuration:setCell(channelDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位通道持续时间
        else
            cell.channelDuration:clearCell()                                                     -- 单位通道持续时间
        end
    end

    -- 鼠标指向格子的整组轮询刷新。
    -- 用于 mouseover 没有可靠事件时兜底。
    -- 当前无 2 秒补正。
    updateAll = function()
        updateUnitExists()
        updateClassAndRole()
        updateHealth()
        updatePower()
        updateUnitBasicStatus()
        updateRangeStatus()
        updateCastAndChannel()
        updateCastAndChannelDuration()
    end

    local fastTimeElapsed = -random() -- 0.1 秒轮询 mouseover 整组状态
    -- local lowTimeElapsed = -random()      -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateAll()
        end

        -- lowTimeElapsed = lowTimeElapsed + elapsed
        -- if lowTimeElapsed > 0.5 then
        --     lowTimeElapsed = lowTimeElapsed - 0.5
        -- end

        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        -- end
    end)

    updateAll()

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
