-- luacheck: globals C_SpellActivationOverlay
local addonName, addonTable = ... -- luacheck: ignore addonName

local insert = table.insert       -- 表插入
local Enum = Enum
local After = C_Timer.After
local ipairs = ipairs

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
local GetSpellCharges = C_Spell.GetSpellCharges
-- baseSpellID = C_SpellBook.FindBaseSpellByID(spellID)

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local chargeSpells = {}
DejaVu.chargeSpells = chargeSpells
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

local CHARGE_LENGTH = 11


After(2, function()
    if #chargeSpells > CHARGE_LENGTH then
        print("DejaVu_Spell: Charge spells number is greater than CHARGE_LENGTH")
        return
    end
    local cellMap = {}

    local function InitCellMap()
        for i = 1, #chargeSpells do
            local spellID = chargeSpells[i].spellID
            local baseID = FindBaseSpellByID(spellID)

            local x = 60 + 2 * i
            local y = 4
            if baseID then
                local iconCell = BadgeCell:New(x, y)         -- 技能图标
                local remainingCell = Cell:New(x, y + 2)     -- 冷却剩余时间的颜色映射
                local overlayedCell = Cell:New(x + 1, y + 2) -- 技能高亮提示
                local isUsableCell = Cell:New(x, y + 3)      -- 当前不可施放时显示白色
                local isKnownCell = Cell:New(x + 1, y + 3)   -- 不在法术书中时显示白色
                local countCell = CharCell:New(x, y + 4)     -- 当前可用层数
                local iconID = GetSpellTexture(baseID)
                iconCell:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
                cellMap[baseID] = {
                    icon = iconCell,
                    remaining = remainingCell,
                    overlayed = overlayedCell,
                    isUsable = isUsableCell,
                    isKnown = isKnownCell,
                    count = countCell,
                }
            end
        end
    end

    InitCellMap()

    local function updateIcon(spellID)
        local baseID = FindBaseSpellByID(spellID)
        local iconID = GetSpellTexture(baseID)
        cellMap[baseID].icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
    end

    local function updateIconAll()
        for baseID in pairs(cellMap) do
            updateIcon(baseID)
        end
    end

    local function updateRemaining(baseID)
        local remaining = GetSpellCooldownDuration(baseID)
        local result = remaining:EvaluateRemainingDuration(remainingCurve)
        cellMap[baseID].remaining:setCell(result)
    end

    local function updateRemainingAll()
        for baseID in pairs(cellMap) do
            updateRemaining(baseID)
        end
    end

    local function updateOverlayed(baseID)
        local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(baseID), COLOR.SPELL_BOOLEAN.IS_HIGH_LIGHTED, COLOR.BLACK)
        cellMap[baseID].overlayed:setCell(isOverlayed)
    end

    local function updateOverlayedAll()
        for baseID in pairs(cellMap) do
            updateOverlayed(baseID)
        end
    end

    local function updateUnusable(baseID)
        local isUsable = EvaluateColorFromBoolean(IsSpellUsable(baseID), COLOR.SPELL_BOOLEAN.IS_USABLE, COLOR.BLACK)
        cellMap[baseID].isUsable:setCell(isUsable)
    end

    local function updateUnusableAll()
        for baseID in pairs(cellMap) do
            updateUnusable(baseID)
        end
    end

    local function updateUnknown(baseID)
        local isKnown = EvaluateColorFromBoolean(IsSpellInSpellBook(baseID), COLOR.SPELL_BOOLEAN.IS_KNOWN, COLOR.BLACK)
        cellMap[baseID].isKnown:setCell(isKnown)
    end

    local function updateUnknownAll()
        for baseID in pairs(cellMap) do
            updateUnknown(baseID)
        end
    end

    local function updateCount(baseID)
        local chargeInfo = GetSpellCharges(baseID)
        cellMap[baseID].count:setCell(tostring(chargeInfo.currentCharges))
    end

    local function updateCountAll()
        for baseID in pairs(cellMap) do
            updateCount(baseID)
        end
    end



    updateIconAll()
    updateRemainingAll()
    updateOverlayedAll()
    updateUnusableAll()
    updateUnknownAll()
    updateCountAll()



    local eventFrame = CreateFrame("eventFrame")
    local fastTimeElapsed = 0
    local lowTimeElapsed = 0
    local superLowTimeElapsed = 0
    eventFrame:HookScript("OnUpdate", function(self, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.2 then
            fastTimeElapsed = 0
            updateUnusableAll()
        end
        lowTimeElapsed = lowTimeElapsed + elapsed
        if lowTimeElapsed > 0.5 then
            lowTimeElapsed = 0
            updateUnknownAll()
            updateRemainingAll()
            -- updateOverlayedAll()
        end
        superLowTimeElapsed = superLowTimeElapsed + elapsed
        if superLowTimeElapsed > 2 then
            superLowTimeElapsed = 0
            updateIconAll()
        end
    end)

    function eventFrame:SPELL_UPDATE_ICON(spellID)
        updateIcon(spellID)
    end

    function eventFrame:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID)
        updateOverlayed(spellID)
    end

    function eventFrame:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
        updateOverlayed(spellID)
    end

    function eventFrame:SPELL_UPDATE_USES(spellID, baseSpellID)
        updateCount(baseSpellID)
    end

    eventFrame:RegisterEvent("SPELL_UPDATE_USES")
    eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
