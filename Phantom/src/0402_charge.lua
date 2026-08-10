-- Namespace declaration
local addonName, addonTable = ...

-- WoW API cache
local CreateFrame     = CreateFrame
local GetSpellCharges = C_Spell.GetSpellCharges

-- Addon-level variable definitions/references
local CHARGE_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.SPELL_CHARGE
local logging               = addonTable.logging

-- Local variables
local insert        = table.insert
local pairs         = pairs
local type          = type
local MAX_SLOTS     = 6
local START_X       = 55
local START_Y       = 1
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- Code

--[[
Summary:               Configured specialization spell charges
Classification:        Spell charge
Classification index:  ChargeList slot 1-6
Position:              Rows 1-2, columns 55-60

Each valid configured slot keeps its original one-based position. Missing or
invalid slots create no StatusBar, so their matrix area remains black.
]]

local function IsFiniteNumber(value)
    return type(value) == "number" and value > -math.huge and value < math.huge
end

local function InitFrame()
    local chargeList = addonTable.SPEC and addonTable.SPEC.ChargeList
    if type(chargeList) ~= "table" then
        return
    end

    for key in pairs(chargeList) do
        if type(key) == "number" and key > 0 and key < math.huge and key % 1 == 0 and key > MAX_SLOTS then
            logging("ChargeList contains a slot above 6; no charge bars were created.")
            return
        end
    end

    local parent = addonTable.MartixFrame
    local SIZE = addonTable.SIZE
    local r = CHARGE_CLASSIFICATION / 255
    local chargeBars = {}

    for index = 1, MAX_SLOTS do
        local charge = chargeList[index]
        local spellID = type(charge) == "table" and charge.spellId or nil
        local minValue = type(charge) == "table" and charge.minValue or nil
        local maxValue = type(charge) == "table" and charge.maxValue or nil

        if IsFiniteNumber(spellID)
            and spellID > 0
            and spellID % 1 == 0
            and IsFiniteNumber(minValue)
            and IsFiniteNumber(maxValue)
            and maxValue >= minValue
        then
            local g = index / 255
            local chargeBar = CreateFrame("StatusBar", nil, parent)
            chargeBar:SetSize(SIZE.CELL, 2 * SIZE.CELL)
            chargeBar:SetPoint(
                "TOPLEFT",
                parent,
                "TOPLEFT",
                (START_X + index - 2) * SIZE.CELL,
                -(START_Y - 1) * SIZE.CELL
            )
            chargeBar:SetOrientation("VERTICAL")
            chargeBar:SetStatusBarTexture(WHITE_TEXTURE)
            chargeBar:SetStatusBarColor(r, g, 1, 1)
            chargeBar:SetMinMaxValues(minValue, maxValue)
            chargeBar:SetValue(minValue)

            local background = chargeBar:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints(chargeBar)
            background:SetColorTexture(r, g, 0, 1)

            insert(chargeBars, {
                spellID = spellID,
                minValue = minValue,
                bar = chargeBar,
            })
        end
    end

    if #chargeBars == 0 then
        return
    end

    local function UpdateBars()
        for barIndex = 1, #chargeBars do
            local chargeBar = chargeBars[barIndex]
            local chargeInfo = GetSpellCharges(chargeBar.spellID)

            if chargeInfo then
                chargeBar.bar:SetValue(chargeInfo.currentCharges)
            else
                chargeBar.bar:SetValue(chargeBar.minValue)
            end
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:RegisterEvent("SPELL_UPDATE_USES")
    eventFrame:SetScript("OnEvent", UpdateBars)
    UpdateBars()
end

insert(addonTable.FrameInitFuncs, InitFrame)
