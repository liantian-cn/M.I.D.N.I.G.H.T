-- luacheck: globals C_SpellActivationOverlay
local addonName, addonTable = ... -- luacheck: ignore addonName

local pairs = pairs
local insert = table.insert -- 表插入
local Enum = Enum
local After = C_Timer.After
local random = math.random
-- WoW 官方 API
local CreateFrame = CreateFrame
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local FindBaseSpellByID = C_SpellBook.FindBaseSpellByID
-- baseSpellID = C_SpellBook.FindBaseSpellByID(spellID)

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

local COOLDOWN_LENGTH = 40


After(2, function()
    if #cooldownSpells > COOLDOWN_LENGTH then
        print("DejaVu_Spell: Cooldown spells number is greater than COOLDOWN_LENGTH")
        return
    end
    local cellMap = {}
    local validSpellID = {}
    local baseIDToSpellID = {}

    local function getValidSpellID(spellID)
        if not spellID or not validSpellID[spellID] then
            return nil
        end
        return spellID
    end

    local function getSpellIDFromBaseID(baseID)
        if not baseID then
            return nil
        end

        local spellID = baseIDToSpellID[baseID]
        if not spellID or not validSpellID[spellID] then
            return nil
        end
        return spellID
    end

    local function InitCellMap()
        for i = 1, #cooldownSpells do
            local spellID = cooldownSpells[i].spellID
            local x = 2 * i
            local y = 0
            local baseID = FindBaseSpellByID(spellID)
            local iconCell = BadgeCell:New(x, y)         -- 技能图标
            local remainingCell = Cell:New(x, y + 2)     -- 冷却剩余时间的颜色映射
            local overlayedCell = Cell:New(x + 1, y + 2) -- 技能高亮提示
            local isUsableCell = Cell:New(x, y + 3)      -- 当前不可施放时显示白色
            local isKnownCell = Cell:New(x + 1, y + 3)   -- 不在法术书中时显示白色
            local iconID = GetSpellTexture(spellID)

            validSpellID[spellID] = true
            if baseID then
                baseIDToSpellID[baseID] = spellID
            end

            iconCell:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
            cellMap[spellID] = {
                icon = iconCell,
                remaining = remainingCell,
                overlayed = overlayedCell,
                isUsable = isUsableCell,
                isKnown = isKnownCell,
            }
        end
    end

    InitCellMap()

    local function updateIcon(spellID)
        local iconID = GetSpellTexture(spellID)
        cellMap[spellID].icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
    end

    local function updateIconAll()
        for spellID in pairs(cellMap) do
            updateIcon(spellID)
        end
    end

    local function updateRemaining(spellID)
        local remaining = GetSpellCooldownDuration(spellID)
        local result = remaining:EvaluateRemainingDuration(remainingCurve)
        cellMap[spellID].remaining:setCell(result)
    end

    local function updateRemainingAll()
        for spellID in pairs(cellMap) do
            updateRemaining(spellID)
        end
    end

    local function updateOverlayed(spellID)
        local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(spellID), COLOR.SPELL_BOOLEAN.IS_HIGH_LIGHTED, COLOR.BLACK)
        cellMap[spellID].overlayed:setCell(isOverlayed)
    end

    local function updateOverlayedAll()
        for spellID in pairs(cellMap) do
            updateOverlayed(spellID)
        end
    end

    local function updateUnusable(spellID)
        local isUsable = EvaluateColorFromBoolean(IsSpellUsable(spellID), COLOR.SPELL_BOOLEAN.IS_USABLE, COLOR.BLACK)
        cellMap[spellID].isUsable:setCell(isUsable)
    end

    local function updateUnusableAll()
        for spellID in pairs(cellMap) do
            updateUnusable(spellID)
        end
    end

    local function updateUnknown(spellID)
        local isKnown = EvaluateColorFromBoolean(IsSpellInSpellBook(spellID), COLOR.SPELL_BOOLEAN.IS_KNOWN, COLOR.BLACK)
        cellMap[spellID].isKnown:setCell(isKnown)
    end

    local function updateUnknownAll()
        for spellID in pairs(cellMap) do
            updateUnknown(spellID)
        end
    end


    updateIconAll()
    updateRemainingAll()
    updateOverlayedAll()
    updateUnusableAll()
    updateUnknownAll()



    local eventFrame = CreateFrame("eventFrame")
    local fastTimeElapsed = -random()     -- 随机初始时间，避免所有事件在同一帧更新
    local lowTimeElapsed = -random()      -- 随机初始时间，避免所有事件在同一帧更新
    local superLowTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    eventFrame:HookScript("OnUpdate", function(self, elapsed)
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
            -- updateOverlayedAll()
        end
        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = superLowTimeElapsed - 2
            updateIconAll()
        end
    end)

    function eventFrame:SPELL_UPDATE_ICON(baseID)
        local spellID = getSpellIDFromBaseID(baseID)
        if not spellID then
            return
        end
        updateIcon(spellID)
    end

    function eventFrame:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID)
        local validID = getValidSpellID(spellID)
        if not validID then
            return
        end
        updateOverlayed(validID)
    end

    function eventFrame:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
        local validID = getValidSpellID(spellID)
        if not validID then
            return
        end
        updateOverlayed(validID)
    end

    eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
