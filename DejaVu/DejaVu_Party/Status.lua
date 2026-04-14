local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local format = string.format
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


After(2, function()
    for partyIndex = 1, 4 do
        local eventFrame = CreateFrame("Frame")
        local UNIT_KEY = format("party%d", partyIndex)
        local BASE_X = 21 * partyIndex
        local cell = {}
        local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs
        local zeroToOneCurve = CreateColorCurve()
        zeroToOneCurve:SetType(Enum.LuaCurveType.Linear)
        zeroToOneCurve:AddPoint(0.0, CreateColor(0, 0, 0, 1))
        zeroToOneCurve:AddPoint(1.0, CreateColor(1, 1, 1, 1))

        cell.exists = Cell:New(BASE_X - 9, 24)               -- 单位存在状态
        cell.isAlive = Cell:New(BASE_X - 9, 25)              -- 单位是否存活
        cell.unitClass = Cell:New(BASE_X - 8, 24)            -- 单位职业
        cell.unitRole = Cell:New(BASE_X - 8, 25)             -- 单位角色
        cell.healthPercent = Cell:New(BASE_X - 7, 24)        -- 单位生命值百分比
        cell.powerPercent = Cell:New(BASE_X - 7, 25)         -- 单位能量百分比
        cell.isEnemy = Cell:New(BASE_X - 6, 24)              -- 单位是否敌对
        cell.canAttack = Cell:New(BASE_X - 6, 25)            -- 单位是否可攻击
        cell.isInRangedRange = Cell:New(BASE_X - 5, 24)      -- 单位是否在远程范围内
        cell.isInMeleeRange = Cell:New(BASE_X - 5, 25)       -- 单位是否在近战范围内
        cell.isInCombat = Cell:New(BASE_X - 4, 24)           -- 单位是否在战斗中
        cell.isTarget = Cell:New(BASE_X - 4, 25)             -- 单位是否为目标
        cell.hasBigDefense = Cell:New(BASE_X - 3, 24)        -- 有大防御值
        cell.hasDispellableDebuff = Cell:New(BASE_X - 3, 25) -- 有可驱散的减益效果
        local unitExists = false

        -- 清空当前队友格子的所有状态
        -- 当队友离队、离线或当前 party 槽位为空时使用
        local function clearAll()
            cell.exists:clearCell()               -- 单位存在状态
            cell.isAlive:clearCell()              -- 单位是否存活
            cell.unitClass:clearCell()            -- 单位职业
            cell.unitRole:clearCell()             -- 单位角色
            cell.healthPercent:clearCell()        -- 单位生命值百分比
            cell.powerPercent:clearCell()         -- 单位能量百分比
            cell.isEnemy:clearCell()              -- 单位是否敌对
            cell.canAttack:clearCell()            -- 单位是否可攻击
            cell.isInRangedRange:clearCell()      -- 单位是否在远程范围内
            cell.isInMeleeRange:clearCell()       -- 单位是否在近战范围内
            cell.isInCombat:clearCell()           -- 单位是否在战斗中
            cell.isTarget:clearCell()             -- 单位是否为目标
            cell.hasBigDefense:clearCell()        -- 有大防御值
            cell.hasDispellableDebuff:clearCell() -- 有可驱散的减益效果
        end

        -- 检测队友单位是否存在，更新存在状态
        -- 基于 GROUP_*、PARTY_MEMBER_*、UNIT_FLAGS、UNIT_TARGETABLE_CHANGED 事件
        -- 2 秒补正
        local function updateUnitExists()
            unitExists = UnitExists(UNIT_KEY)

            if not unitExists then
                clearAll()
                return
            end

            cell.exists:setCell(COLOR.STATUS_BOOLEAN.EXISTS)
        end

        -- 更新职业和角色
        -- 基于 GROUP_*、PLAYER_ROLES_ASSIGNED 事件
        -- 2 秒补正
        local function updateClassAndRole()
            if not unitExists then
                return
            end

            local classFile = select(2, UnitClass(UNIT_KEY))
            cell.unitClass:setCell(COLOR.CLASS[classFile] or COLOR.BLACK)
            cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned(UNIT_KEY)] or COLOR.ROLE.NONE)
        end

        -- 更新血量数据
        -- 基于 UNIT_HEALTH 和 UNIT_MAXHEALTH 事件
        -- 2 秒补正
        local function updateHealth()
            if not unitExists then
                return
            end

            cell.healthPercent:setCell(UnitHealthPercent(UNIT_KEY, false, zeroToOneCurve))
        end

        -- 更新能量数据
        -- 基于 UNIT_POWER_UPDATE、UNIT_MAXPOWER、UNIT_DISPLAYPOWER 事件
        -- 2 秒补正
        local function updatePower()
            if not unitExists then
                return
            end

            cell.powerPercent:setCell(UnitPowerPercent(UNIT_KEY, UnitPowerType(UNIT_KEY), false, zeroToOneCurve))
        end

        -- 更新单位基础状态
        -- 基于 UNIT_FLAGS、UNIT_FACTION、PLAYER_TARGET_CHANGED、UNIT_TARGETABLE_CHANGED 事件
        -- 2 秒补正
        local function updateUnitBasicStatus()
            if not unitExists then
                return
            end

            cell.isAlive:setCellBoolean(UnitIsDeadOrGhost(UNIT_KEY), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)
            cell.isEnemy:setCellBoolean(UnitIsEnemy(UNIT_KEY, "player"), COLOR.STATUS_BOOLEAN.IS_ENEMY, COLOR.BLACK)
            cell.canAttack:setCellBoolean(UnitCanAttack("player", UNIT_KEY), COLOR.STATUS_BOOLEAN.CAN_ATTACK, COLOR.BLACK)
            cell.isInCombat:setCellBoolean(UnitAffectingCombat(UNIT_KEY), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK)
            cell.isTarget:setCellBoolean(UnitIsUnit(UNIT_KEY, "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)
        end

        -- 更新队友的远程和近战距离状态。
        -- 没有稳定的队友距离事件。
        -- 0.5 秒轮询，当前无 2 秒补正。
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

        -- 更新异常状态
        -- 基于 UNIT_AURA 事件
        -- 2 秒补正
        local function updateAura()
            if not unitExists then
                return
            end

            local bigDefenseTable = GetUnitAuraInstanceIDs(UNIT_KEY, "HELPFUL|BIG_DEFENSIVE") or {}
            local dispellableDebuffTable = GetUnitAuraInstanceIDs(UNIT_KEY, "HARMFUL|RAID_PLAYER_DISPELLABLE") or {}
            cell.hasBigDefense:setCellBoolean(#bigDefenseTable > 0, COLOR.STATUS_BOOLEAN.HAS_BIG_DEFENSE, COLOR.BLACK)
            cell.hasDispellableDebuff:setCellBoolean(
                #dispellableDebuffTable > 0,
                COLOR.STATUS_BOOLEAN.HAS_DISPELLABLE_DEBUFF,
                COLOR.BLACK
            )
        end

        -- 当前队友格子的整组刷新。
        -- 用于初始化和事件触发时的立即全刷。
        -- 2 秒补正不走 updateAll，距离状态仍只靠 0.5 秒轮询。
        local function updateAll()
            updateUnitExists()
            updateClassAndRole()
            updateHealth()
            updatePower()
            updateUnitBasicStatus()
            updateRangeStatus()
            updateAura()
        end

        local GroupChangeOnFrame = false

        -- 队伍成员变化时当前 party 槽位可能整体换人，直接全刷。
        -- 事件用途：处理 GROUP_ROSTER_UPDATE。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        function eventFrame:GROUP_ROSTER_UPDATE()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 玩家加入队伍后当前 party 槽位可能重排，直接全刷。
        -- 事件用途：处理 GROUP_JOINED。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("GROUP_JOINED")
        function eventFrame:GROUP_JOINED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 玩家离队后当前 party 槽位可能清空或前移，直接全刷。
        -- 事件用途：处理 GROUP_LEFT。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("GROUP_LEFT")
        function eventFrame:GROUP_LEFT()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 新队伍形成时当前 party 槽位整体重建，直接全刷。
        -- 事件用途：处理 GROUP_FORMED。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("GROUP_FORMED")
        function eventFrame:GROUP_FORMED()
            if GroupChangeOnFrame then
                return
            end
            GroupChangeOnFrame = true
            updateAll()
        end

        -- 职责指派变化时刷新职业和职责显示。
        -- 事件用途：处理 PLAYER_ROLES_ASSIGNED。
        -- 2 秒补正：由 updateClassAndRole 单独补正。
        eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
        function eventFrame:PLAYER_ROLES_ASSIGNED()
            updateClassAndRole()
        end

        -- 某个队友重新上线或恢复可交互时刷新当前槽位。
        -- 事件用途：处理 PARTY_MEMBER_ENABLE。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
        function eventFrame:PARTY_MEMBER_ENABLE(unitToken)
            if unitToken == UNIT_KEY then
                updateAll()
            end
        end

        -- 某个队友断线或失去可交互时刷新当前槽位。
        -- 事件用途：处理 PARTY_MEMBER_DISABLE。
        -- 2 秒补正：除距离状态外，其余状态在 superLowTimeElapsed 里分项补正。
        eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
        function eventFrame:PARTY_MEMBER_DISABLE(unitToken)
            if unitToken == UNIT_KEY then
                updateAll()
            end
        end

        -- Aura 变化时刷新友方异常状态。
        -- 事件用途：处理 UNIT_AURA。
        -- 2 秒补正：由 updateAura 单独补正。
        eventFrame:RegisterUnitEvent("UNIT_AURA", UNIT_KEY)
        function eventFrame:UNIT_AURA(unitToken, info)
            if info.isFullUpdate or info.removedAuraInstanceIDs or info.addedAuras then
                updateAura()
            end
        end

        -- 最大生命值变化时刷新血量百分比。
        -- 事件用途：处理 UNIT_MAXHEALTH。
        -- 2 秒补正：由 updateHealth 单独补正。
        eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", UNIT_KEY)
        function eventFrame:UNIT_MAXHEALTH(unitToken)
            updateHealth()
        end

        -- 当前生命值变化时刷新血量百分比。
        -- 事件用途：处理 UNIT_HEALTH。
        -- 2 秒补正：由 updateHealth 单独补正。
        eventFrame:RegisterUnitEvent("UNIT_HEALTH", UNIT_KEY)
        function eventFrame:UNIT_HEALTH(unitToken)
            updateHealth()
        end

        -- 能量和能量制式变化时刷新能量百分比。
        -- 事件用途：处理 UNIT_POWER_UPDATE、UNIT_MAXPOWER、UNIT_DISPLAYPOWER。
        -- 2 秒补正：由 updatePower 单独补正。
        eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", UNIT_KEY)
        eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", UNIT_KEY)
        eventFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", UNIT_KEY)
        function eventFrame:UNIT_POWER_UPDATE(unitToken)
            updatePower()
        end

        function eventFrame:UNIT_MAXPOWER(unitToken)
            updatePower()
        end

        function eventFrame:UNIT_DISPLAYPOWER(unitToken)
            updatePower()
        end

        -- 队友旗标变化时刷新存在、基础状态和距离。
        -- 事件用途：处理 UNIT_FLAGS。
        -- 2 秒补正：存在和基础状态有 2 秒补正，距离状态当前只有 0.5 秒轮询。
        eventFrame:RegisterUnitEvent("UNIT_FLAGS", UNIT_KEY)
        function eventFrame:UNIT_FLAGS(unitToken)
            updateUnitExists()
            updateUnitBasicStatus()
            updateRangeStatus()
        end

        -- 阵营可攻击性变化时刷新友敌和可攻击状态。
        -- 事件用途：处理 UNIT_FACTION。
        -- 2 秒补正：由 updateUnitBasicStatus 单独补正。
        eventFrame:RegisterUnitEvent("UNIT_FACTION", UNIT_KEY)
        function eventFrame:UNIT_FACTION(unitToken)
            updateUnitBasicStatus()
        end

        -- 当前目标变化时更新是否为目标，并顺手刷新一次距离。
        -- 事件用途：处理 PLAYER_TARGET_CHANGED。
        -- 2 秒补正：isTarget 有 2 秒补正，距离状态当前只有 0.5 秒轮询。
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        function eventFrame:PLAYER_TARGET_CHANGED()
            updateUnitBasicStatus()
            updateRangeStatus()
        end

        -- 可交互性变化时刷新存在、基础状态和距离。
        -- 事件用途：处理 UNIT_TARGETABLE_CHANGED。
        -- 2 秒补正：存在和基础状态有 2 秒补正，距离状态当前只有 0.5 秒轮询。
        eventFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", UNIT_KEY)
        function eventFrame:UNIT_TARGETABLE_CHANGED(unitToken)
            updateUnitExists()
            updateUnitBasicStatus()
            updateRangeStatus()
        end

        -- local fastTimeElapsed = -random()     -- 当前未使用，保留 0.1 秒刷新档位结构
        local lowTimeElapsed = -random()      -- 随机初始时间，避免所有队友格子在同一帧中速刷新
        local superLowTimeElapsed = -random() -- 随机初始时间，避免所有队友格子在同一帧低频补正
        eventFrame:HookScript("OnUpdate", function(frame, elapsed)
            GroupChangeOnFrame = false        -- 每帧重置，避免同一帧内重复处理多个队伍结构事件
            -- fastTimeElapsed = fastTimeElapsed + elapsed
            -- if fastTimeElapsed > 0.1 then
            --     fastTimeElapsed = fastTimeElapsed - 0.1
            -- end
            lowTimeElapsed = lowTimeElapsed + elapsed
            if lowTimeElapsed > 0.5 then
                lowTimeElapsed = lowTimeElapsed - 0.5
                updateRangeStatus()
            end
            superLowTimeElapsed = superLowTimeElapsed + elapsed
            if superLowTimeElapsed > 2 then
                superLowTimeElapsed = superLowTimeElapsed - 2
                updateUnitExists()
                updateClassAndRole()
                updateHealth()
                updatePower()
                updateUnitBasicStatus()
                updateAura()
            end
        end)

        updateAll()

        eventFrame:SetScript("OnEvent", function(self, event, ...)
            self[event](self, ...)
        end)
    end
end)
