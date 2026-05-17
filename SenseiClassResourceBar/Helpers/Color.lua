local _, addonTable = ...

function addonTable:GetOverrideHealthBarColor()
    local color = self:GetHealthBarColor()

    local settings = SenseiClassResourceBarDB and SenseiClassResourceBarDB["_Settings"]
    local powerColors = settings and settings["HealthColors"]
    local overrideColor = powerColors and powerColors["HEALTH"]

    if overrideColor then
        if overrideColor.r then color.r = overrideColor.r end
        if overrideColor.g then color.g = overrideColor.g end
        if overrideColor.b then color.b = overrideColor.b end
        if overrideColor.a then color.a = overrideColor.a end
    end

    return color
end

function addonTable:GetHealthBarColor()
    return { r = 0, g = 1, b = 0 }
end

function addonTable:GetOverrideResourceColor(resource)
    local color, settingKey = self:GetResourceColor(resource)

    local settings = SenseiClassResourceBarDB and SenseiClassResourceBarDB["_Settings"]
    local powerColors = settings and settings["PowerColors"]
    local overrideColor = powerColors and powerColors[settingKey or resource]

    if overrideColor then
        if overrideColor.r then color.r = overrideColor.r end
        if overrideColor.g then color.g = overrideColor.g end
        if overrideColor.b then color.b = overrideColor.b end
        if overrideColor.a then color.a = overrideColor.a end
    end

    return color
end

function addonTable:GetResourceColor(resource)
    local color = nil
    local settingKey = nil

    local powerName = nil
    for name, value in pairs(Enum.PowerType) do
        if value == resource then
            -- LunarPower -> LUNAR_POWER
            powerName = name:gsub("(%u)", "_%1"):gsub("^_", ""):upper()
            break;
        end
    end

    if resource == "STAGGER" or resource == "STAGGER_LOW" or resource == "STAGGER_MEDIUM" or resource == "STAGGER_HEAVY" then
        local staggerColors = {
            ["STAGGER_LOW"] = GetPowerBarColor("STAGGER").green,
            ["STAGGER_MEDIUM"] = GetPowerBarColor("STAGGER").yellow,
            ["STAGGER_HEAVY"] = GetPowerBarColor("STAGGER").red,
        }

        if resource == "STAGGER" then
            local stagger = UnitStagger("player") or 0
            local maxHealth = UnitHealthMax("player") or 1

            -- Sometimes the stagger is secret (even though Blizzard said it's not), so just skip the computation if secret
            if issecretvalue(stagger) then
                resource = "STAGGER_LOW"
            else
                local staggerPercent = (stagger / maxHealth) * 100

                if staggerPercent < 30 then
                    resource = "STAGGER_LOW"
                elseif staggerPercent < 60 then
                    resource = "STAGGER_MEDIUM"
                else
                    resource = "STAGGER_HEAVY"
                end
            end
        end

        color = staggerColors[resource]
        settingKey = resource
    elseif resource == "SOUL_FRAGMENTS" or resource == "SOUL_FRAGMENTS_VOID_META" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(1217607) -- Void Meta

        -- Different color during Void Metamorphosis
        if resource == "SOUL_FRAGMENTS_VOID_META" or auraData ~= nil then
            settingKey = "SOUL_FRAGMENTS_VOID_META"
            color = { r = 0.037, g = 0.220, b = 0.566, atlas = "UF-DDH-CollapsingStar-Bar-Ready" }
        else
            color = { r = 0.278, g = 0.125, b = 0.796, atlas = "UF-DDH-VoidMeta-Bar-Ready" }
        end
    elseif resource == "SOUL_FRAGMENTS_VENGEANCE" then
        color = { r = 0.341, g = 0.063, b = 0.459 }
    elseif resource == Enum.PowerType.Runes or resource == Enum.PowerType.RuneBlood or resource == Enum.PowerType.RuneUnholy or resource == Enum.PowerType.RuneFrost then
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        local runeColors = {
            [Enum.PowerType.RuneBlood]  = { r = 1,   g = 0.2, b = 0.3 },
            [Enum.PowerType.RuneFrost]  = { r = 0.0, g = 0.6, b = 1.0 },
            [Enum.PowerType.RuneUnholy] = { r = 0.1, g = 1.0, b = 0.1 },
        }

        local specToRune = {
            [250] = Enum.PowerType.RuneBlood,
            [251] = Enum.PowerType.RuneFrost,
            [252] = Enum.PowerType.RuneUnholy,
        }

        -- Pick color based on precise resource, fallback to current spec
        local key = resource ~= Enum.PowerType.Runes and resource or specToRune[specID]
        color = runeColors[key]
        settingKey = key
        -- Else fallback on Blizzard Runes color, grey...
    elseif resource == Enum.PowerType.Essence then
        color = GetPowerBarColor("FUEL")
    elseif resource == Enum.PowerType.ComboPoints then
        color = { r = 0.878, g = 0.176, b = 0.180 }
    elseif resource == "OVERCHARGED_COMBO_POINTS" then
        color = { r = 0.169, g = 0.733, b = 0.992 }
    elseif resource == Enum.PowerType.Chi then
        color = { r = 0.024, g = 0.741, b = 0.784 }
    elseif resource == "MAELSTROM_WEAPON" then
        color = { r = 0, g = 0.5, b = 1 }
    elseif resource == "MAELSTROM_WEAPON_ABOVE_5" then
        color = { r = 1, g = 0.5, b = 0 }
    elseif resource == "TIP_OF_THE_SPEAR" then
        color = { r = 0.6, g = 0.8, b = 0.2 }
    elseif resource == "WHIRLWIND" then
        color = { r = 0.2, b = 0.8, g = 0.2 }
    elseif resource == "ICICLES" then
        color = { r = 0.020, g = 0.714, b = 0.910 }
    elseif resource == "FREEZE" then
        color = { r = 0.100, g = 0.600, b = 0.950 }
    end

    -- If not custom, try with power name or id
    return CopyTable(color or GetPowerBarColor(powerName) or GetPowerBarColor(resource) or { r = 1, g = 1, b = 1 }), settingKey
end