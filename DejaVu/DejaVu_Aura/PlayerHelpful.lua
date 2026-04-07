local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local ipairs = ipairs
local pairs = pairs
local wipe = wipe
local After = C_Timer.After

-- WoW 官方 API
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs                 -- 读取单位 aura 实例 ID 列表
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID       -- 读取 aura 数据
local GetAuraDuration = C_UnitAuras.GetAuraDuration                               -- 读取 aura 剩余时长对象
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount -- 读取 aura 层数字符串
local DoesAuraHaveExpirationTime = C_UnitAuras.DoesAuraHaveExpirationTime         -- 判断 aura 是否会自然结束
local CreateColorCurve = C_CurveUtil.CreateColorCurve

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell
local CharCell = DejaVu.CharCell

local remainingCurve = CreateColorCurve()
remainingCurve:SetType(Enum.LuaCurveType.Linear)
remainingCurve:AddPoint(0.0, COLOR.C0)
remainingCurve:AddPoint(5.0, COLOR.C100)
remainingCurve:AddPoint(30.0, COLOR.C150)
remainingCurve:AddPoint(155.0, COLOR.C200)
remainingCurve:AddPoint(375.0, COLOR.C255)

local MAX_AURA_COUNT = 30
local BASE_X = 1
local BASE_Y = 4
local UNIT_KEY = "player"
local AURA_FILTER = "HELPFUL"
local SORT_RULE = Enum.UnitAuraSortRule.Default
local SORT_DIRECTION = Enum.UnitAuraSortDirection.Normal



After(2, function()
    local Cells = {}         -- 初始化容器，key为位置，value为Cell对象
    local InstanceIDMap = {} -- 初始化容器，key为InstanceID，value为位置
    local function InitCells()
        for i = 1, MAX_AURA_COUNT do
            local x = BASE_X - 2 + 2 * i                 -- 计算当前槽位 x 坐标
            local y = BASE_Y                             -- 当前槽位 y 坐标
            local iconCell = BadgeCell:New(x, y)         -- aura 图标
            local remainingCell = Cell:New(x, y + 2)     -- 剩余时间颜色
            local spellTypeCell = Cell:New(x + 1, y + 2) -- aura 类型颜色
            local countCell = CharCell:New(x, y + 3)     -- aura 层数文本
            Cells[i] = {
                icon = iconCell,
                remaining = remainingCell,
                spellType = spellTypeCell,
                count = countCell,
                instanceID = nil,
            }
            -- print(Cells[i])
        end
    end





    local function clearCell(cell)
        cell.icon:clearCell()
        cell.remaining:clearCell()
        cell.spellType:clearCell()
        cell.count:clearCell()
        cell.instanceID = nil
    end

    local function drawCell(cell, instanceID)
        local aura = GetAuraDataByAuraInstanceID(UNIT_KEY, instanceID) -- 取当前 aura 数据
        if aura == nil then
            clearCell(cell)
            return false
        end
        cell.instanceID = instanceID

        local remaining = GetAuraDuration(UNIT_KEY, instanceID)                    -- 剩余时间对象
        local count = GetAuraApplicationDisplayCount(UNIT_KEY, instanceID, 1, 9)   -- 取层数字符串
        local hasExpirationTime = DoesAuraHaveExpirationTime(UNIT_KEY, instanceID) -- 是否会到时结束
        local spellTypeColor = COLOR.SPELL_TYPE.BUFF_ON_FRIENDLY                   -- 本次 aura 的边框 / 类型颜色

        -- 1 icon
        cell.icon:setCell(aura.icon, spellTypeColor)

        -- 2 remaining
        local remainingColor = COLOR.WHITE -- 默认是白色，也就是无限持续
        if not hasExpirationTime then
            remainingColor = COLOR.WHITE
        else                                                                     -- 有剩余时间对象时更新颜色
            remainingColor = remaining:EvaluateRemainingDuration(remainingCurve) -- 计算时间颜色
        end
        cell.remaining:setCell(remainingColor)
        -- 3 spellType
        cell.spellType:setCell(spellTypeColor)
        -- 4 count
        cell.count:setCell(count)
        return true
    end

    local function findFirstEmptyCellIndex()
        for i = 1, MAX_AURA_COUNT do
            if Cells[i].instanceID == nil then
                return i
            end
        end
    end

    local function removeAura(instanceID)
        local index = InstanceIDMap[instanceID]
        if index == nil then
            return
        end
        clearCell(Cells[index])
        InstanceIDMap[instanceID] = nil
    end

    local function addAura(instanceID)
        if instanceID == nil then
            return
        end
        if InstanceIDMap[instanceID] ~= nil then
            drawCell(Cells[InstanceIDMap[instanceID]], instanceID)
            return
        end
        local index = findFirstEmptyCellIndex()
        if index == nil then
            return
        end
        InstanceIDMap[instanceID] = index
        if not drawCell(Cells[index], instanceID) then
            InstanceIDMap[instanceID] = nil
        end
    end

    local function refreshAll()
        wipe(InstanceIDMap)
        local auraInstanceIDs = GetUnitAuraInstanceIDs(UNIT_KEY, AURA_FILTER, MAX_AURA_COUNT, SORT_RULE, SORT_DIRECTION) or {} -- 获取排序后的 aura 实例列表
        for i = 1, MAX_AURA_COUNT do
            local cell = Cells[i]
            local instanceID = auraInstanceIDs[i]
            if instanceID == nil then
                clearCell(cell)
            else
                if drawCell(cell, instanceID) then
                    InstanceIDMap[instanceID] = i
                end
            end
        end
    end

    local function updateCell(instanceID)
        local index = InstanceIDMap[instanceID]
        if index == nil then
            return
        end
        local cell = Cells[index]
        -- local aura = GetAuraDataByAuraInstanceID(UNIT_KEY, instanceID)             -- 取当前 aura 数据
        local remaining = GetAuraDuration(UNIT_KEY, instanceID)                    -- 剩余时间对象
        local count = GetAuraApplicationDisplayCount(UNIT_KEY, instanceID, 1, 9)   -- 取层数字符串
        local hasExpirationTime = DoesAuraHaveExpirationTime(UNIT_KEY, instanceID) -- 是否会到时结束
        local remainingColor = COLOR.WHITE                                         -- 默认是白色，也就是无限持续
        if not hasExpirationTime then
            remainingColor = COLOR.WHITE
        else                                                                     -- 有剩余时间对象时更新颜色
            remainingColor = remaining:EvaluateRemainingDuration(remainingCurve) -- 计算时间颜色
        end
        cell.remaining:setCell(remainingColor)
        cell.count:setCell(count)
    end

    local function updateAll()
        for instanceID in pairs(InstanceIDMap) do
            updateCell(instanceID)
        end
    end


    InitCells()
    refreshAll()

    local eventFrame = CreateFrame("eventFrame")
    local fastTimeElapsed = 0
    local lowTimeElapsed = 0
    local superLowTimeElapsed = 0
    eventFrame:HookScript("OnUpdate", function(self, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.2 then
            fastTimeElapsed = 0
            updateAll()
        end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = 0
        end
        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = 0
            refreshAll()
        end
    end)

    function eventFrame:UNIT_AURA(unit, info)
        if info.isFullUpdate then
            refreshAll()
            return
        end
        if info.removedAuraInstanceIDs then
            for _, instanceID in ipairs(info.removedAuraInstanceIDs) do
                removeAura(instanceID)
            end
        end
        if info.addedAuras then
            for _, aura in ipairs(info.addedAuras) do
                addAura(aura.auraInstanceID)
            end
        end
        if info.updatedAuraInstanceIDs then
            for _, instanceID in ipairs(info.updatedAuraInstanceIDs) do
                updateCell(instanceID)
            end
        end
    end

    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
