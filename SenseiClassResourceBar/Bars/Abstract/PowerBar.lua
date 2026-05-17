local _, addonTable = ...

local PowerBarMixin = Mixin({}, addonTable.BarMixin)

function PowerBarMixin:GetBarColor(resource)
    return addonTable:GetOverrideResourceColor(resource)
end

function PowerBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self.Frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self.Frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    self.Frame:RegisterEvent("PET_BATTLE_OPENING_START")
    self.Frame:RegisterEvent("PET_BATTLE_CLOSE")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        self.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end
end

function PowerBarMixin:OnEvent(event, ...)
    local unit = ...
    self._curEvent = event

    if event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        RunNextFrame(function() self:ApplyVisibilitySettings() end)
        self:ApplyLayout(nil, true)
        self:UpdateDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then

        self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
        self:ApplyLayout(nil, true)
        self:UpdateDisplay()

    elseif event == "UNIT_MAXPOWER" and unit == "player" then

        self:ApplyLayout(nil, true)

    end
end

function PowerBarMixin:GetTagValues(resource, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    -- Pre-compute values instead of creating closures for better performance
    local currentStr = string.format("%s", AbbreviateNumbers(current))
    local maxStr = string.format("%s", AbbreviateNumbers(max))
    local percentStr
    if type(resource) == "number" and (issecretvalue(max) or issecretvalue(current)) then
        percentStr = string.format(pFormat, UnitPowerPercent("player", resource, true, CurveConstants.ScaleTo100))
    elseif not issecretvalue(max) and not issecretvalue(current) and max ~= 0 then
        percentStr = string.format(pFormat, (current / max) * 100)
    else
        percentStr = ''
    end

    return {
        ["[current]"] = function() return currentStr end,
        ["[percent]"] = function() return percentStr end,
        ["[max]"] = function() return maxStr end,
    }
end

addonTable.PowerBarMixin = PowerBarMixin