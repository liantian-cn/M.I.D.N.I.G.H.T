local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

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

local GetItemCooldown = C_Container.GetItemCooldown


-- DejaVu Core
local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell

local function itemUsable(itemId)
    if not itemId then
        return false
    end

    local startTime, duration, enable = GetItemCooldown(itemId) -- luacheck: ignore startTime
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

local cell = {}                                             -- 状态单元格，提供给外部调用以更新状态显示
local touch = {}                                            -- 触发器，提供给外部调用以触发状态更新

After(2, function()                                         -- 延迟加载
    local eventFrame = CreateFrame("Frame")                 -- 事件框架

    cell.castIcon = BadgeCell:New(45, 14)                   -- 单位施法图标 / updateCastAndChannel
    cell.channelIcon = BadgeCell:New(47, 14)                -- 单位通道图标 / updateCastAndChannel
    -- 48列
    cell.unitIsAlive = Cell:New(49, 15)                     -- 存活 / updateUnitBasicStatus
    -- 49列
    cell.unitClass = Cell:New(50, 14)                       -- 玩家的职业 / updateClassAndRole
    cell.unitRole = Cell:New(50, 15)                        -- 玩家的角色 / updateClassAndRole
    -- 50 列
    cell.unitHealthPercent = Cell:New(51, 14)               -- 生命值百分比  / updateHealth
    cell.unitPowerPercent = Cell:New(51, 15)                -- 主能量百分比 / updatePower
    -- 51列
    cell.unitIsInCombat = Cell:New(52, 14)                  -- 在战斗中 / updateUnitBasicStatus
    cell.unitIsTarget = Cell:New(52, 15)                    -- 是目标 / updateUnitBasicStatus
    -- 52列
    cell.unitHasBigDefense = Cell:New(53, 14)               -- 有大防御值 / updateAura
    cell.unitHasDispellableDebuff = Cell:New(53, 15)        -- 有可驱散的减益效果 / updateAura
    -- 53列
    cell.castDuration = Cell:New(54, 14)                    -- 施法持续时间 / updateCastAndChannelDuration
    cell.channelDuration = Cell:New(54, 15)                 -- 通道持续时间 / updateCastAndChannelDuration
    -- -- 54列
    cell.unitIsEmpowering = Cell:New(55, 14)                -- 在蓄力   / updateCastAndChannel
    cell.unitEmpoweringStage = Cell:New(55, 15)             -- 蓄力阶段
    -- 55列
    cell.unitIsMoving = Cell:New(56, 14)                    -- 在移动 / updateUnitActionStatus
    cell.unitIsMounted = Cell:New(56, 15)                   -- 在坐骑 / updateUnitActionStatus
    -- 56列
    cell.unitEnemyCount = Cell:New(57, 14)                  -- 敌人数量
    cell.unitIsSpellTargeting = Cell:New(57, 15)            -- 正在选择目标 / updateUnitActionStatus
    -- 57列
    cell.unitIsChatInputActive = Cell:New(58, 14)           -- 正在聊天输入 / updateUnitActionStatus
    cell.unitIsInGroupOrRaid = Cell:New(58, 15)             -- 在队伍/团队中 / updateUnitGroupStatus
    -- 58列
    cell.unitTrinket1CooldownUsable = Cell:New(59, 14)      -- 饰品 1可用 / updateTrinketUsable
    cell.unitTrinket2CooldownUsable = Cell:New(59, 15)      -- 饰品 2可用 / updateTrinketUsable
    -- 59列
    cell.unitHealthstoneCooldownUsable = Cell:New(60, 14)   -- 生命石可用 / updateHealingItemUsable
    cell.unitHealingPotionCooldownUsable = Cell:New(60, 15) -- 治疗药水可用 / updateHealingItemUsable





    -- 职业和颜色
    -- 低频刷新
    local function updateClassAndRole()
        cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass("player"))])                    -- 单位职业
        cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned("player")] or COLOR.ROLE.NONE) -- 单位角色
    end


    -- 更新异常状态
    -- 基于UNIT_AURA事件
    -- 低频刷新补正
    touch.hasAuraUpdateOnFrame = false -- 本帧是否已经处理过 aura 更新，避免同一帧内多次处理
    local function updateAura()
        if touch.hasAuraUpdateOnFrame then
            return
        end
        touch.hasAuraUpdateOnFrame = true
        local bigDefenseTable = GetUnitAuraInstanceIDs("player", "HELPFUL|BIG_DEFENSIVE")
        local dispellableDebuffTable = GetUnitAuraInstanceIDs("player", "HARMFUL|RAID_PLAYER_DISPELLABLE")
        cell.unitHasBigDefense:setCellBoolean(#bigDefenseTable > 0, COLOR.STATUS_BOOLEAN.HAS_BIG_DEFENSE, COLOR.BLACK)
        cell.unitHasDispellableDebuff:setCellBoolean(#dispellableDebuffTable > 0, COLOR.STATUS_BOOLEAN.HAS_DISPELLABLE_DEBUFF, COLOR.BLACK)
    end

    function eventFrame:UNIT_AURA(unitToken, info)
        if info.isFullUpdate or info.removedAuraInstanceIDs or info.addedAuras then
            updateAura()
        end
    end

    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

    -- 更新血量数据
    -- 基于UNIT_HEALTH和UNIT_MAXHEALTH事件
    -- 低频刷新补正
    touch.hasHealthUpdateOnFrame = false -- 本帧是否已经处理过血量更新，避免同一帧内多次处理
    local function updateHealth()
        if touch.hasHealthUpdateOnFrame then
            return
        end
        touch.hasHealthUpdateOnFrame = true
        cell.unitHealthPercent:setCell(UnitHealthPercent("player", true, zeroToOneCurve)) -- 单位生命值百分比
    end
    function eventFrame:UNIT_MAXHEALTH(unitToken)
        updateHealth()
    end

    function eventFrame:UNIT_HEALTH(unitToken)
        updateHealth()
    end

    eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")


    -- 更新能量数据
    -- 基于UNIT_POWER_UPDATE事件
    -- 低频刷新补正
    touch.hasPowerUpdateOnFrame = false -- 本帧是否已经处理过能量更新，避免同一帧内多次处理
    local function updatePower()
        if touch.hasPowerUpdateOnFrame then
            return
        end
        touch.hasPowerUpdateOnFrame = true
        cell.unitPowerPercent:setCell(UnitPowerPercent("player", UnitPowerType("player"), true, zeroToOneCurve)) -- 单位能量百分比
    end
    function eventFrame:UNIT_POWER_UPDATE(unitToken)
        updatePower()
    end

    eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")


    -- 更新单位基础状态
    -- 高频刷新
    local function updateUnitBasicStatus()
        cell.unitIsAlive:setCellBoolean(UnitIsDeadOrGhost("player"), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)          -- 单位是否存活
        cell.unitIsInCombat:setCellBoolean(UnitAffectingCombat("player"), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK) -- 单位是否在战斗中
        cell.unitIsTarget:setCellBoolean(UnitIsUnit("player", "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)     -- 单位是否为目标
    end

    -- 更新单位动作状态
    -- 高频刷新
    local function updateUnitActionStatus()
        cell.unitIsMounted:setCellBoolean(UnitInVehicle("player") or IsMounted(), COLOR.STATUS_BOOLEAN.IS_MOUNTED, COLOR.BLACK) -- 单位是否在坐骑
        cell.unitIsSpellTargeting:setCellBoolean(SpellIsTargeting(), COLOR.STATUS_BOOLEAN.IS_SPELL_TARGETING, COLOR.BLACK)      -- 单位是否正在选择目标
        cell.unitIsChatInputActive:setCellBoolean(
            GetCurrentKeyBoardFocus() ~= nil,
            COLOR.STATUS_BOOLEAN.IS_CHAT_INPUT_ACTIVE,
            COLOR.BLACK
        ) -- 单位是否正在聊天输入
    end

    -- 更新移动状态
    -- PLAYER_STOPPED_MOVING 和 PLAYER_STARTED_MOVING 事件刷新
    -- 低频刷新补正
    touch.hasMovementUpdateOnFrame = false -- 本帧是否已经处理过移动更新，避免同一帧内多次处理
    -- 基于事件开始移动和停止移动都刷新状态，确保状态及时更新
    local function updateMovement_start()
        if touch.hasMovementUpdateOnFrame then
            return
        end
        touch.hasMovementUpdateOnFrame = true
        -- 延迟刷新，确保移动状态稳定
        cell.unitIsMoving:setCell(COLOR.STATUS_BOOLEAN.IS_MOVING) -- 单位是否在移动
    end

    -- 基于事件停止
    local function updateMovement_stop()
        if touch.hasMovementUpdateOnFrame then
            return
        end
        touch.hasMovementUpdateOnFrame = true
        -- 延迟刷新，确保移动状态稳定
        cell.unitIsMoving:setCell(COLOR.BLACK) -- 单位是否在移动
    end
    -- 补正
    local function updateMovement_fix()
        if touch.hasMovementUpdateOnFrame then
            return
        end
        touch.hasMovementUpdateOnFrame = true
        -- 延迟刷新，确保移动状态稳定
        cell.unitIsMoving:setCellBoolean(GetUnitSpeed("player") > 0, COLOR.STATUS_BOOLEAN.IS_MOVING, COLOR.BLACK) -- 单位是否在移动
    end


    function eventFrame:PLAYER_STARTED_MOVING()
        updateMovement_start()
    end

    function eventFrame:PLAYER_STOPPED_MOVING()
        updateMovement_stop()
    end

    eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
    eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")

    -- 更新队伍状态
    -- 低频刷新
    local function updateUnitGroupStatus()
        cell.unitIsInGroupOrRaid:setCellBoolean(IsInGroup() or IsInRaid(), COLOR.STATUS_BOOLEAN.IS_IN_GROUP_OR_RAID, COLOR.BLACK) -- 单位是否在队伍/团队中
    end

    -- 更新饰品可用状态
    -- 低频刷新
    local function updateTrinketUsable()
        cell.unitTrinket1CooldownUsable:setCellBoolean(slotUsable(13), COLOR.STATUS_BOOLEAN.TRINKET_1_USABLE, COLOR.BLACK) -- 饰品 1是否可用
        cell.unitTrinket2CooldownUsable:setCellBoolean(slotUsable(14), COLOR.STATUS_BOOLEAN.TRINKET_2_USABLE, COLOR.BLACK) -- 饰品 2是否可用
    end

    -- 更新治疗物品可用状态
    -- 低频刷新
    local function updateHealingItemUsable()
        cell.unitHealthstoneCooldownUsable:setCellBoolean(itemUsable(224464), COLOR.STATUS_BOOLEAN.HEALTHSTONE_USABLE, COLOR.BLACK)      -- 生命石是否可用
        cell.unitHealingPotionCooldownUsable:setCellBoolean(itemUsable(258138), COLOR.STATUS_BOOLEAN.HEALING_POTION_USABLE, COLOR.BLACK) -- 治疗药水是否可用
    end


    -- 更新施法、通道和蓄力状态
    -- 基于 UNIT_SPELLCAST_START、UNIT_SPELLCAST_STOP、UNIT_SPELLCAST_CHANNEL_START、UNIT_SPELLCAST_CHANNEL_STOP、UNIT_SPELLCAST_CHANNEL_UPDATE 事件
    -- 低频补正
    touch.hasCastOrChannelUpdateOnFrame = false -- 本帧是否已经处理过施法或通道更新，避免同一帧内多次处理
    local inCasting = false
    local inChanneling = false
    local function updateCastAndChannel()
        if touch.hasCastOrChannelUpdateOnFrame then
            return
        end
        touch.hasCastOrChannelUpdateOnFrame = true
        local castIcon = select(3, UnitCastingInfo("player"))
        if castIcon then
            inCasting = true
            cell.castIcon:setCell(castIcon, COLOR.SPELL_TYPE.PLAYER_SPELL) -- 单位施法图标
            cell.channelIcon:clearCell()                                   -- 通道图标
            cell.channelDuration:clearCell()                               -- 通道持续时间
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
                cell.unitIsEmpowering:setCellBoolean(true, COLOR.STATUS_BOOLEAN.IS_EMPOWERING, COLOR.BLACK)
                cell.unitEmpoweringStage:setCell(zeroToOneCurve(UnitEmpoweredStageDurations("player")))
            else
                cell.unitIsEmpowering:setCell(COLOR.BLACK)
                cell.unitEmpoweringStage:setCell(COLOR.BLACK)
            end -- isEmpowered
        else
            inChanneling = false
            cell.channelIcon:clearCell()     -- 通道图标
            cell.channelDuration:clearCell() -- 通道持续时间
        end
    end
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

    -- 更新施法进度
    -- 高频刷新
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



    local fastTimeElapsed = -random()     -- 随机初始时间，避免所有事件在同一帧更新
    local lowTimeElapsed = -random()      -- 随机初始时间，避免所有事件在同一帧更新
    local superLowTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        -- 每帧重置触发器状态，确保状态更新函数在同一帧内只执行一次
        for k in pairs(touch) do
            touch[k] = false
        end
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCastAndChannelDuration()
        end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
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
