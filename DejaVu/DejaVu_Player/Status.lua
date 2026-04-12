local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local After = C_Timer.After
local random = math.random
local min = math.min
local insert = table.insert

-- WoW 官方 API
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local Enum = Enum

local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local GetInventoryItemID = GetInventoryItemID
local GetUnitSpeed = GetUnitSpeed
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsMounted = IsMounted
local IsUsableItem = C_Item.IsUsableItem
local SpellIsTargeting = SpellIsTargeting
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAttack = UnitCanAttack
local UnitChannelInfo = UnitChannelInfo
local UnitEmpoweredStageDurations = UnitEmpoweredStageDurations
local UnitExists = UnitExists
local UnitInVehicle = UnitInVehicle
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsUnit = UnitIsUnit
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs
local IsSpellInRange = C_Spell.IsSpellInRange

local GetItemCooldown = C_Container.GetItemCooldown

local LibStub = LibStub
local LRC = LibStub("LibRangeCheck-3.0")
if not LRC then
    print("|cffff0000[单位状态]|r LibRangeCheck-3.0 未找到, 模块无法工作。")
    return
end

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell
local MeleeRange = DejaVu.MeleeRange -- 默认的近战检测范围

local function itemUsable(itemId)
    if not itemId then
        return false
    end

    local startTime, duration, enable = GetItemCooldown(itemId)
    local usable, noMana = IsUsableItem(itemId)
    return enable == 1 and duration == 0 and usable and not noMana
end

local function slotUsable(slotId)
    return itemUsable(GetInventoryItemID("player", slotId))
end

local zeroToOneCurve = CreateColorCurve()
zeroToOneCurve:SetType(Enum.LuaCurveType.Linear)
zeroToOneCurve:AddPoint(0.0, CreateColor(0, 0, 0, 1))
zeroToOneCurve:AddPoint(1.0, CreateColor(1, 1, 1, 1))

local cell = {}                                         -- 状态单元格，提供给外部调用以更新状态显示                                    -- 触发器，提供给外部调用以触发状态更新

After(2, function()                                     -- 延迟加载
    local eventFrame = CreateFrame("Frame")             -- 事件框架

    cell.castIcon = BadgeCell:New(45, 14)               -- 单位施法图标 / updateCastAndChannel
    cell.channelIcon = BadgeCell:New(47, 14)            -- 单位通道图标 / updateCastAndChannel
    -- 48列
    cell.isAlive = Cell:New(49, 15)                     -- 存活 / updateUnitBasicStatus
    -- 49列
    cell.unitClass = Cell:New(50, 14)                   -- 玩家的职业 / updateClassAndRole
    cell.unitRole = Cell:New(50, 15)                    -- 玩家的角色 / updateClassAndRole
    -- 50 列
    cell.healthPercent = Cell:New(51, 14)               -- 生命值百分比  / updateHealth
    cell.powerPercent = Cell:New(51, 15)                -- 主能量百分比 / updatePower
    -- 51列
    cell.isInCombat = Cell:New(52, 14)                  -- 在战斗中 / updateUnitBasicStatus
    cell.isTarget = Cell:New(52, 15)                    -- 是目标 / updateUnitBasicStatus
    -- 52列
    cell.hasBigDefense = Cell:New(53, 14)               -- 有大防御值 / updateAura
    cell.hasDispellableDebuff = Cell:New(53, 15)        -- 有可驱散的减益效果 / updateAura
    -- 53列
    cell.castDuration = Cell:New(54, 14)                -- 施法持续时间 / updateCastAndChannelDuration
    cell.channelDuration = Cell:New(54, 15)             -- 通道持续时间 / updateCastAndChannelDuration
    -- -- 54列
    cell.isEmpowering = Cell:New(55, 14)                -- 在蓄力   / updateCastAndChannel
    cell.empoweringStage = Cell:New(55, 15)             -- 蓄力阶段 / updateCastAndChannel
    -- 55列
    cell.isMoving = Cell:New(56, 14)                    -- 在移动 / updateUnitActionStatus
    cell.isMounted = Cell:New(56, 15)                   -- 在坐骑 / updateUnitActionStatus
    -- 56列
    cell.enemyCount = Cell:New(57, 14)                  -- 敌人数量
    cell.isSpellTargeting = Cell:New(57, 15)            -- 正在选择目标 / updateUnitActionStatus
    -- 57列
    cell.isChatInputActive = Cell:New(58, 14)           -- 正在聊天输入 / updateUnitActionStatus
    cell.isInGroupOrRaid = Cell:New(58, 15)             -- 在队伍/团队中 / updateUnitGroupStatus
    -- 58列
    cell.trinket1CooldownUsable = Cell:New(59, 14)      -- 饰品 1可用 / updateTrinketUsable
    cell.trinket2CooldownUsable = Cell:New(59, 15)      -- 饰品 2可用 / updateTrinketUsable
    -- 59列
    cell.healthstoneCooldownUsable = Cell:New(60, 14)   -- 生命石可用 / updateHealingItemUsable
    cell.healingPotionCooldownUsable = Cell:New(60, 15) -- 治疗药水可用 / updateHealingItemUsable





    -- 职业和颜色
    -- 低频刷新
    local function updateClassAndRole()
        cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass("player"))])                    -- 单位职业
        cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned("player")] or COLOR.ROLE.NONE) -- 单位角色
    end


    -- 更新玩家的大防御和可驱散减益状态。
    -- 基于 UNIT_AURA 事件。
    -- 2 秒补正。
    local function updateAura()
        local bigDefenseTable = GetUnitAuraInstanceIDs("player", "HELPFUL|BIG_DEFENSIVE")
        local dispellableDebuffTable = GetUnitAuraInstanceIDs("player", "HARMFUL|RAID_PLAYER_DISPELLABLE")
        cell.hasBigDefense:setCellBoolean(#bigDefenseTable > 0, COLOR.STATUS_BOOLEAN.HAS_BIG_DEFENSE, COLOR.BLACK)
        cell.hasDispellableDebuff:setCellBoolean(#dispellableDebuffTable > 0, COLOR.STATUS_BOOLEAN.HAS_DISPELLABLE_DEBUFF, COLOR.BLACK)
    end

    -- Aura 结构变化时刷新玩家异常状态。
    -- 事件用途：处理增减益列表变化。
    -- 2 秒补正：由 superLowTimeElapsed 单独补正。
    function eventFrame:UNIT_AURA(unitToken, info)
        if info.isFullUpdate or info.removedAuraInstanceIDs or info.addedAuras then
            updateAura()
        end
    end

    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

    -- 更新玩家生命值百分比。
    -- 基于 UNIT_HEALTH 和 UNIT_MAXHEALTH 事件。
    -- 2 秒补正。
    local function updateHealth()
        cell.healthPercent:setCell(UnitHealthPercent("player", false, zeroToOneCurve)) -- 单位生命值百分比
    end

    -- 最大生命值变化时刷新生命值百分比。
    -- 事件用途：处理生命值刻度变化。
    -- 2 秒补正：由 superLowTimeElapsed 单独补正。
    function eventFrame:UNIT_MAXHEALTH(unitToken)
        updateHealth()
    end

    -- 当前生命值变化时刷新生命值百分比。
    -- 事件用途：处理生命值进度变化。
    -- 2 秒补正：由 superLowTimeElapsed 单独补正。
    function eventFrame:UNIT_HEALTH(unitToken)
        updateHealth()
    end

    eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")


    -- 更新玩家主能量百分比。
    -- 基于 UNIT_POWER_UPDATE 事件。
    -- 2 秒补正。
    local function updatePower()
        cell.powerPercent:setCell(UnitPowerPercent("player", UnitPowerType("player"), false, zeroToOneCurve)) -- 单位能量百分比
    end

    -- 主能量变化时刷新能量百分比。
    -- 事件用途：处理能量进度变化。
    -- 2 秒补正：由 superLowTimeElapsed 单独补正。
    function eventFrame:UNIT_POWER_UPDATE(unitToken)
        updatePower()
    end

    eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")


    -- 更新玩家的存活、战斗和目标状态。
    -- 没有稳定事件可覆盖所有变化。
    -- 0.5 秒轮询，当前无 2 秒单独补正。
    local function updateUnitBasicStatus()
        cell.isAlive:setCellBoolean(UnitIsDeadOrGhost("player"), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)          -- 单位是否存活
        cell.isInCombat:setCellBoolean(UnitAffectingCombat("player"), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK) -- 单位是否在战斗中
        cell.isTarget:setCellBoolean(UnitIsUnit("player", "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)     -- 单位是否为目标
    end

    -- 更新玩家的坐骑、选目标法术和聊天输入状态。
    -- 没有稳定事件可覆盖所有变化。
    -- 0.5 秒轮询，当前无 2 秒单独补正。
    local function updateUnitActionStatus()
        cell.isMounted:setCellBoolean(UnitInVehicle("player") or IsMounted(), COLOR.STATUS_BOOLEAN.IS_MOUNTED, COLOR.BLACK) -- 单位是否在坐骑
        cell.isSpellTargeting:setCellBoolean(SpellIsTargeting(), COLOR.STATUS_BOOLEAN.IS_SPELL_TARGETING, COLOR.BLACK)      -- 单位是否正在选择目标
        cell.isChatInputActive:setCellBoolean(
            GetCurrentKeyBoardFocus() ~= nil,
            COLOR.STATUS_BOOLEAN.IS_CHAT_INPUT_ACTIVE,
            COLOR.BLACK
        ) -- 单位是否正在聊天输入
    end

    -- 玩家开始移动时点亮移动状态。
    -- 事件用途：处理 PLAYER_STARTED_MOVING。
    -- 2 秒补正：由 updateMovement_fix 单独补正。
    local function updateMovement_start()
        cell.isMoving:setCell(COLOR.STATUS_BOOLEAN.IS_MOVING) -- 单位是否在移动
    end

    -- 玩家停止移动时熄灭移动状态。
    -- 事件用途：处理 PLAYER_STOPPED_MOVING。
    -- 2 秒补正：由 updateMovement_fix 单独补正。
    local function updateMovement_stop()
        cell.isMoving:setCell(COLOR.BLACK) -- 单位是否在移动
    end

    -- 低频补正移动状态，防止事件丢失或顺序抖动。
    -- 不走 updateAll，在 2 秒档位里单独补正。
    local function updateMovement_fix()
        cell.isMoving:setCellBoolean(GetUnitSpeed("player") > 0, COLOR.STATUS_BOOLEAN.IS_MOVING, COLOR.BLACK) -- 单位是否在移动
    end

    -- 开始移动时立即点亮移动状态。
    -- 事件用途：处理 PLAYER_STARTED_MOVING。
    -- 2 秒补正：由 updateMovement_fix 单独补正。
    function eventFrame:PLAYER_STARTED_MOVING()
        updateMovement_start()
    end

    -- 停止移动时立即熄灭移动状态。
    -- 事件用途：处理 PLAYER_STOPPED_MOVING。
    -- 2 秒补正：由 updateMovement_fix 单独补正。
    function eventFrame:PLAYER_STOPPED_MOVING()
        updateMovement_stop()
    end

    eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
    eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")

    -- 更新玩家是否在队伍或团队中。
    -- 无单独事件，依赖 2 秒轮询。
    local function updateUnitGroupStatus()
        cell.isInGroupOrRaid:setCellBoolean(IsInGroup() or IsInRaid(), COLOR.STATUS_BOOLEAN.IS_IN_GROUP_OR_RAID, COLOR.BLACK) -- 单位是否在队伍/团队中
    end

    -- 更新两个饰品的可用状态。
    -- 无单独事件，依赖 2 秒轮询。
    local function updateTrinketUsable()
        cell.trinket1CooldownUsable:setCellBoolean(slotUsable(13), COLOR.STATUS_BOOLEAN.TRINKET_1_USABLE, COLOR.BLACK) -- 饰品 1是否可用
        cell.trinket2CooldownUsable:setCellBoolean(slotUsable(14), COLOR.STATUS_BOOLEAN.TRINKET_2_USABLE, COLOR.BLACK) -- 饰品 2是否可用
    end

    -- 更新生命石和治疗药水的可用状态。
    -- 无单独事件，依赖 2 秒轮询。
    local function updateHealingItemUsable()
        cell.healthstoneCooldownUsable:setCellBoolean(itemUsable(224464), COLOR.STATUS_BOOLEAN.HEALTHSTONE_USABLE, COLOR.BLACK)      -- 生命石是否可用
        cell.healingPotionCooldownUsable:setCellBoolean(itemUsable(258138), COLOR.STATUS_BOOLEAN.HEALING_POTION_USABLE, COLOR.BLACK) -- 治疗药水是否可用
    end

    -- 更新近战范围内的敌人数量。
    -- 无可靠事件，依赖 0.5 秒轮询。
    local function updateEnemyCount()
        local count = 0

        for i = 1, 10 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local maxRange = select(2, LRC:GetRange(unit)) or 99
                if maxRange <= MeleeRange then
                    count = count + 1
                end
            end
        end

        cell.enemyCount:setCellRGBA(min(count / 51, 1))
    end

    -- 更新玩家的施法、通道和蓄力状态。
    -- 基于 UNIT_SPELLCAST_* 事件。
    -- 2 秒补正。
    local inCasting = false
    local inChanneling = false
    local function updateCastAndChannel()
        local castIcon = select(3, UnitCastingInfo("player"))
        if castIcon then
            inCasting = true
            cell.castIcon:setCell(castIcon, COLOR.SPELL_TYPE.PLAYER_SPELL) -- 单位施法图标
            cell.channelIcon:clearCell()                                   -- 通道图标
            cell.channelDuration:clearCell()                               -- 通道持续时间
            cell.isEmpowering:clearCell()                                  -- 蓄力状态
            cell.empoweringStage:clearCell()                               -- 蓄力阶段
            return                                                         -- 在施法就不可在通道, 这里可以返回了。
        else
            inCasting = false
            cell.castIcon:clearCell()     -- 单位施法图标
            cell.castDuration:clearCell() -- 单位施法是否可中断
        end

        local channelIcon = select(3, UnitChannelInfo("player"))
        if channelIcon then
            inChanneling = true
            cell.channelIcon:setCell(channelIcon, COLOR.SPELL_TYPE.PLAYER_SPELL) -- 单位通道图标
            cell.castIcon:clearCell()                                            -- 单位施法图标
            cell.castDuration:clearCell()                                        -- 单位施法剩余
            local isEmpowered = select(9, UnitChannelInfo("player"))
            if isEmpowered then
                cell.isEmpowering:setCellBoolean(true, COLOR.STATUS_BOOLEAN.IS_EMPOWERING, COLOR.BLACK)
                cell.empoweringStage:setCell(zeroToOneCurve(UnitEmpoweredStageDurations("player")))
            else
                cell.isEmpowering:setCell(COLOR.BLACK)
                cell.empoweringStage:setCell(COLOR.BLACK)
            end -- isEmpowered
        else
            inChanneling = false
            cell.channelIcon:clearCell()     -- 通道图标
            cell.channelDuration:clearCell() -- 通道持续时间
        end
    end
    -- 施法和通道状态变化时刷新图标、是否可中断和蓄力信息。
    -- 事件用途：处理 UNIT_SPELLCAST_* 这一组事件。
    -- 2 秒补正：由 superLowTimeElapsed 单独补正。
    function eventFrame:UNIT_SPELLCAST_INTERRUPTED(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_START(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_STOP(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_SUCCEEDED(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_CHANNEL_START(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_CHANNEL_STOP(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_FAILED(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_CHANNEL_UPDATE(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_EMPOWER_START(unitToken)
        updateCastAndChannel()
    end

    function eventFrame:UNIT_SPELLCAST_EMPOWER_STOP(unitToken)
        updateCastAndChannel()
    end

    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")

    -- 更新施法和通道的进度条颜色。
    -- 无可靠事件可持续驱动进度。
    -- 0.1 秒轮询，当前无 2 秒单独补正。
    local function updateCastAndChannelDuration()
        -- print("updateCastAndChannelDuration")
        local castDuration = inCasting and UnitCastingDuration("player") or nil
        if castDuration then
            cell.castDuration:setCell(castDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位施法持续时间
        else
            cell.castDuration:clearCell()                                                  -- 单位施法持续时间
        end

        local channelDuration = inChanneling and UnitChannelDuration("player") or nil
        if channelDuration then
            cell.channelDuration:setCell(channelDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位通道施法持续时间
        else
            cell.channelDuration:clearCell()                                                     -- 单位通道施法持续时间
        end
    end



    local fastTimeElapsed = -random()     -- 0.1 秒刷新施法和通道进度
    local lowTimeElapsed = -random()      -- 0.5 秒刷新基础状态、动作状态和附近敌人数量
    local superLowTimeElapsed = -random() -- 2 秒补正事件驱动和低频状态
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCastAndChannelDuration()
        end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
            updateEnemyCount()
            updateUnitBasicStatus()
            updateUnitActionStatus()
        end
        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = superLowTimeElapsed - 2
            updateClassAndRole()
            updateAura()
            updateHealth()
            updatePower()
            updateUnitGroupStatus()
            updateTrinketUsable()
            updateHealingItemUsable()
            updateCastAndChannel()
            updateMovement_fix()
        end
    end)





    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
