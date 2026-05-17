local addonName, addonTable = ...

local pairs = pairs
local ipairs = ipairs
local insert = table.insert
local Enum = Enum
local random = math.random
local max = math.max
local type = type

-- luacheck: globals GetInventoryItemTexture GetInventoryItemCooldown
-- WoW 官方 API
local CreateFrame = CreateFrame
local CreateColor = CreateColor
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local GetItemIconByID = C_Item.GetItemIconByID
local GetItemCooldown = C_Container.GetItemCooldown
local IsUsableItem = C_Item.IsUsableItem
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetTime = GetTime
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local FindBaseSpellByID = C_SpellBook.FindBaseSpellByID
local GetSpellName = C_Spell.GetSpellName

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local cooldownSpells = {}
DejaVu.cooldownSpells = cooldownSpells
insert(cooldownSpells, { spellID = 61304, name = "公共冷却" })
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell
local BadgeCell = DejaVu.BadgeCell

local remainingCurve = CreateColorCurve()
remainingCurve:SetType(Enum.LuaCurveType.Linear)
remainingCurve:AddPoint(0.0, COLOR.C0)
remainingCurve:AddPoint(5.0, COLOR.C100)
remainingCurve:AddPoint(30.0, COLOR.C150)
remainingCurve:AddPoint(155.0, COLOR.C200)
remainingCurve:AddPoint(375.0, COLOR.C255)

local function evaluateRemainingNumber(remaining)
    if remaining <= 0 then
        return COLOR.C0
    elseif remaining <= 5 then
        local value = remaining / 5 * 100
        return CreateColor(value / 255, value / 255, value / 255, 1)
    elseif remaining <= 30 then
        local value = 100 + (remaining - 5) / 25 * 50
        return CreateColor(value / 255, value / 255, value / 255, 1)
    elseif remaining <= 155 then
        local value = 150 + (remaining - 30) / 125 * 50
        return CreateColor(value / 255, value / 255, value / 255, 1)
    elseif remaining <= 375 then
        local value = 200 + (remaining - 155) / 220 * 55
        return CreateColor(value / 255, value / 255, value / 255, 1)
    end
    return COLOR.C255
end

local COOLDOWN_LENGTH = 40
local MartixInitFuncs = DejaVu.MartixInitFuncs

local function getEntryType(entry)
    return entry.type or "spell"
end

local function findInventorySlot(entry)
    if entry.slot then
        return entry.slot
    end
    if not entry.slots then
        return nil
    end

    for _, slot in ipairs(entry.slots) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID and (not entry.itemID or itemID == entry.itemID) then
            return slot
        end
    end
    return nil
end

local function getEntryItemID(entry)
    if entry.itemID then
        return entry.itemID
    end
    local slot = findInventorySlot(entry)
    if slot then
        return GetInventoryItemID("player", slot)
    end
    return nil
end

local function getEntryIcon(entry)
    local entryType = getEntryType(entry)
    if entryType == "inventory" then
        local slot = findInventorySlot(entry)
        if slot then
            return GetInventoryItemTexture("player", slot) or GetItemIconByID(entry.itemID)
        end
        return GetItemIconByID(entry.itemID)
    elseif entryType == "item" then
        return GetItemIconByID(entry.itemID)
    end
    return GetSpellTexture(entry.spellID)
end

local function getEntryName(entry)
    if entry.name then
        return entry.name
    end
    return GetSpellName(entry.spellID)
end

local function getItemRemaining(startTime, duration, enable)
    if enable ~= 1 or not duration or duration == 0 then
        return 0
    end
    return max(0, (startTime or 0) + duration - GetTime())
end

local function getEntryRemaining(entry)
    local entryType = getEntryType(entry)
    if entryType == "inventory" then
        local slot = findInventorySlot(entry)
        if not slot then
            return 0
        end
        return getItemRemaining(GetInventoryItemCooldown("player", slot))
    elseif entryType == "item" then
        return getItemRemaining(GetItemCooldown(entry.itemID))
    end
    return GetSpellCooldownDuration(entry.spellID)
end

local function isEntryUsable(entry)
    local entryType = getEntryType(entry)
    if entryType == "inventory" or entryType == "item" then
        local itemID = getEntryItemID(entry)
        if entry.itemID and itemID ~= entry.itemID then
            return false
        end
        if not itemID then
            return false
        end
        local usable, noMana = IsUsableItem(itemID)
        return usable and not noMana
    end
    return IsSpellUsable(entry.spellID)
end

local function isEntryKnown(entry)
    local entryType = getEntryType(entry)
    if entryType == "inventory" or entryType == "item" then
        local itemID = getEntryItemID(entry)
        return itemID ~= nil and (not entry.itemID or itemID == entry.itemID)
    end
    return IsSpellInSpellBook(entry.spellID)
end

local function isEntryOverlayed(entry)
    if getEntryType(entry) ~= "spell" then
        return false
    end
    return IsSpellOverlayed(entry.spellID)
end


local function InitFrame()
    if #cooldownSpells > COOLDOWN_LENGTH then
        print("DejaVu_Spell: Cooldown spells number is greater than COOLDOWN_LENGTH")
        return
    end

    local cellMap = {}
    local validSpellID = {}
    local baseIDToIndex = {}
    local eventFrame = CreateFrame("Frame")

    local function getValidSpellID(spellID)
        if not spellID or not validSpellID[spellID] then
            return nil
        end
        return validSpellID[spellID]
    end

    local function getSpellIDFromBaseID(baseID)
        if not baseID then
            return nil
        end

        local index = baseIDToIndex[baseID]
        if not index then
            return nil
        end
        return index
    end

    local function InitCellMap()
        for i = 1, #cooldownSpells do
            local entry = cooldownSpells[i]
            local spellID = entry.spellID
            local x = 2 * i
            local y = 0
            local baseID = spellID and FindBaseSpellByID(spellID)

            -- x = x, y = y
            -- 用途：技能图标。
            -- 更新函数：updateIcon
            local iconCell = BadgeCell:New(x, y)
            -- x = x, y = y + 2
            -- 用途：显示冷却剩余时间颜色。
            -- 更新函数：updateRemaining
            local remainingCell = Cell:New(x, y + 2)
            -- x = x + 1, y = y + 2
            -- 用途：显示技能高亮提示。
            -- 更新函数：updateOverlayed
            local overlayedCell = Cell:New(x + 1, y + 2)
            -- x = x, y = y + 3
            -- 用途：显示技能是否不可施放。
            -- 更新函数：updateUnusable
            local isUsableCell = Cell:New(x, y + 3)
            -- x = x + 1, y = y + 3
            -- 用途：显示技能是否未学会。
            -- 更新函数：updateUnknown
            local isKnownCell = Cell:New(x + 1, y + 3)
            local iconID = getEntryIcon(entry)
            local spellName = getEntryName(entry)


            if spellID then
                validSpellID[spellID] = i
            end
            if baseID then
                baseIDToIndex[baseID] = i
            end

            iconCell:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL, spellName)
            cellMap[i] = {
                entry = entry,
                icon = iconCell,
                remaining = remainingCell,
                overlayed = overlayedCell,
                isUsable = isUsableCell,
                isKnown = isKnownCell,
            }
        end
    end

    InitCellMap()

    -- 说明：刷新单个技能图标。
    -- 依赖事件更新：SPELL_UPDATE_ICON。
    -- 依赖定时刷新：2 秒。
    local function updateIcon(index)
        local entry = cellMap[index].entry
        local iconID = getEntryIcon(entry)
        local spellName = getEntryName(entry)
        cellMap[index].icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL, spellName)
    end

    -- 说明：刷新全部技能图标。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：2 秒。
    local function updateIconAll()
        for index in pairs(cellMap) do
            updateIcon(index)
        end
    end

    -- 说明：刷新单个技能冷却剩余时间颜色。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.5 秒。
    local function updateRemaining(index)
        local remaining = getEntryRemaining(cellMap[index].entry)
        local result
        if type(remaining) == "number" then
            result = evaluateRemainingNumber(remaining)
        else
            result = remaining:EvaluateRemainingDuration(remainingCurve)
        end
        cellMap[index].remaining:setCell(result)
    end

    -- 说明：刷新全部技能冷却剩余时间颜色。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.5 秒。
    local function updateRemainingAll()
        for index in pairs(cellMap) do
            updateRemaining(index)
        end
    end

    -- 说明：刷新单个技能高亮提示状态。
    -- 依赖事件更新：SPELL_ACTIVATION_OVERLAY_GLOW_SHOW、SPELL_ACTIVATION_OVERLAY_GLOW_HIDE。
    -- 依赖定时刷新：无。
    local function updateOverlayed(index)
        local isOverlayed = EvaluateColorFromBoolean(isEntryOverlayed(cellMap[index].entry), COLOR.SPELL_BOOLEAN.IS_HIGH_LIGHTED, COLOR.BLACK)
        cellMap[index].overlayed:setCell(isOverlayed)
    end

    -- 说明：刷新全部技能高亮提示状态。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：无。
    local function updateOverlayedAll()
        for index in pairs(cellMap) do
            updateOverlayed(index)
        end
    end

    -- 说明：刷新单个技能是否可施放状态。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.1 秒。
    local function updateUnusable(index)
        local isUsable = EvaluateColorFromBoolean(isEntryUsable(cellMap[index].entry), COLOR.SPELL_BOOLEAN.IS_USABLE, COLOR.BLACK)
        cellMap[index].isUsable:setCell(isUsable)
    end

    -- 说明：刷新全部技能是否可施放状态。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.1 秒。
    local function updateUnusableAll()
        for index in pairs(cellMap) do
            updateUnusable(index)
        end
    end

    -- 说明：刷新单个技能是否已学会状态。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.5 秒。
    local function updateUnknown(index)
        local isKnown = EvaluateColorFromBoolean(isEntryKnown(cellMap[index].entry), COLOR.SPELL_BOOLEAN.IS_KNOWN, COLOR.BLACK)
        cellMap[index].isKnown:setCell(isKnown)
    end

    -- 说明：刷新全部技能是否已学会状态。
    -- 依赖事件更新：无。
    -- 依赖定时刷新：0.5 秒。
    local function updateUnknownAll()
        for index in pairs(cellMap) do
            updateUnknown(index)
        end
    end

    -- SPELL_UPDATE_ICON
    -- 事件说明：技能图标变化时刷新对应技能图标。
    -- 对应函数：updateIcon
    eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
    function eventFrame.SPELL_UPDATE_ICON(baseID)
        local index = getSpellIDFromBaseID(baseID)
        if not index then
            return
        end
        updateIcon(index)
    end

    -- SPELL_ACTIVATION_OVERLAY_GLOW_SHOW
    -- 事件说明：技能高亮出现时刷新对应技能高亮状态。
    -- 对应函数：updateOverlayed
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    function eventFrame.SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID)
        local index = getValidSpellID(spellID)
        if not index then
            return
        end
        updateOverlayed(index)
    end

    -- SPELL_ACTIVATION_OVERLAY_GLOW_HIDE
    -- 事件说明：技能高亮消失时刷新对应技能高亮状态。
    -- 对应函数：updateOverlayed
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    function eventFrame.SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
        local index = getValidSpellID(spellID)
        if not index then
            return
        end
        updateOverlayed(index)
    end

    local fastTimeElapsed = -random()     -- 0.1 秒刷新可施放状态。
    local lowTimeElapsed = -random()      -- 0.5 秒刷新已学会状态和冷却剩余。
    local superLowTimeElapsed = -random() -- 2 秒补正技能图标。
    eventFrame:HookScript("OnUpdate", function(_, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateUnusableAll()
        end

        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = lowTimeElapsed - 0.5
            updateUnknownAll()
            updateRemainingAll()
            -- updateOverlayedAll() -- 当前保留低频补正占位，未启用。
        end

        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = superLowTimeElapsed - 2
            updateIconAll()
        end
    end)

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](...)
    end)

    -- 首次刷新
    updateIconAll()
    updateRemainingAll()
    updateOverlayedAll()
    updateUnusableAll()
    updateUnknownAll()
end
insert(MartixInitFuncs, InitFrame)
