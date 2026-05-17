local addonName, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local LibSerialize = addonTable.LibSerialize or LibStub("LibSerialize")
local LibDeflate = addonTable.LibDeflate or LibStub("LibDeflate")
local L = addonTable.L

local EXPORT_VERSION = 1

addonTable.updateBar = function(name)
    local bar = addonTable.barInstances[name]
    if not bar then return end

    bar:ApplyLayout()
end

addonTable.updateBars = function()
    for name, _ in pairs(addonTable.barInstances) do
        addonTable.updateBar(name)
    end
end

addonTable.fullUpdateBar = function(name)
    local bar = addonTable.barInstances[name]
    if not bar then return end

    bar:InitCooldownManagerWidthHook()
    bar:InitCustomFrameWidthHook()
    bar:ApplyVisibilitySettings()
    bar:ApplyLayout()
    bar:UpdateDisplay()

    if type(bar.ApplyMouseSettings) == "function" then
        bar:ApplyMouseSettings()
    end
end

addonTable.fullUpdateBars = function()
    for name, _ in pairs(addonTable.barInstances) do
        addonTable.fullUpdateBar(name)
    end
end

addonTable.setFontStringFont = function(fontString, fontFace, size, flags)
	if not (fontString and fontString.SetFont and fontFace) then return false end
	local ok, applied = pcall(fontString.SetFont, fontString, fontFace, size, flags)
	return ok and applied ~= false
end

addonTable.decodeImportString = function(importString)
    local prefix, version, encoded = importString:match("^([^:]+):(%d+):(.+)$")
    if prefix ~= addonName then
        return nil, L["IMPORT_STRING_NOT_SUITABLE"] .. ' ' .. addonName
    end
    if not version or version ~= tostring(EXPORT_VERSION) then
        return nil, L["IMPORT_STRING_OLDER_VERSION"] .. ' ' .. addonName
    end
    if not encoded then
        return nil, L["IMPORT_STRING_INVALID"]
    end

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then
        return nil, L["IMPORT_DECODE_FAILED"]
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return nil, L["IMPORT_DECOMPRESSION_FAILED"]
    end

    local success, data = LibSerialize:Deserialize(serialized)
    if not success then
        return nil, L["IMPORT_DESERIALIZATION_FAILED"]
    end

    return data
end

addonTable.encodeDataAsString = function(data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return addonName .. ":" .. EXPORT_VERSION .. ":" .. encoded
end

addonTable.exportBarAsString = function(dbName)
    local data = {
        BARS = {},
    }

    local layoutName = LEM.GetActiveLayoutName() or "Default"
    if dbName
    and SenseiClassResourceBarDB
    and SenseiClassResourceBarDB[dbName]
    and SenseiClassResourceBarDB[dbName][layoutName] then
        data.BARS[dbName] = SenseiClassResourceBarDB[dbName][layoutName] or nil
    end

    return addonTable.encodeDataAsString(data)
end

--- Can work with default global export string
addonTable.importBarAsString = function(importString, dbName)
    local data, errMsg = addonTable.decodeImportString(importString)
    if not data or errMsg then
        return nil, errMsg or "?"
    end

    if data.BARS[dbName] then
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

        local layoutName = LEM.GetActiveLayoutName() or "Default"
        SenseiClassResourceBarDB[dbName][layoutName] = data.BARS[dbName]
    end

    return data
end

addonTable.exportProfileAsString = function(includeBarSettings, includeAddonSettings, layoutNameToExport)
    local data = {
        BARS = {},
        GLOBAL = nil,
    }

    if includeBarSettings then
        local layoutName = layoutNameToExport or LEM.GetActiveLayoutName() or "Default"
        for _, barSettings in pairs(addonTable.RegisteredBar or {}) do
            if barSettings
            and barSettings.dbName
            and SenseiClassResourceBarDB
            and SenseiClassResourceBarDB[barSettings.dbName]
            and SenseiClassResourceBarDB[barSettings.dbName][layoutName] then
                data.BARS[barSettings.dbName] = SenseiClassResourceBarDB[barSettings.dbName][layoutName] or nil
            end
        end
    end

    if includeAddonSettings then
        if SenseiClassResourceBarDB and SenseiClassResourceBarDB["_Settings"] then
            data.GLOBAL = SenseiClassResourceBarDB["_Settings"]
        end
    end

    return addonTable.encodeDataAsString(data)
end
SCRB.exportProfileAsString = addonTable.exportProfileAsString

--- Can work with individual export string
addonTable.importProfileFromString = function(importString)
    local data, errMsg = addonTable.decodeImportString(importString)
    if not data or errMsg then
        return nil, errMsg or "?"
    end

    local layoutName = LEM.GetActiveLayoutName() or "Default"
    for dbName, barSettings in pairs(data.BARS or {}) do
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

        if not SenseiClassResourceBarDB[dbName] then
            SenseiClassResourceBarDB[dbName] = {}
        end

        SenseiClassResourceBarDB[dbName][layoutName] = barSettings
    end

    if data.GLOBAL then
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

		SenseiClassResourceBarDB["_Settings"] = data.GLOBAL
    end

    return data
end
SCRB.importProfileFromString = addonTable.importProfileFromString

addonTable.getAvailableProfiles = function()
    local profiles = {}

    if not SenseiClassResourceBarDB then
        return profiles
    end

    for _, barSettings in pairs(addonTable.RegisteredBar or {}) do
        if barSettings and barSettings.dbName then
            local dbName = barSettings.dbName
            if SenseiClassResourceBarDB[dbName] then
                for layoutName, _ in pairs(SenseiClassResourceBarDB[dbName]) do
                    profiles[layoutName] = true
                end
            end
        end
    end

    local keyset = {}
    for k, _ in pairs(profiles) do
        keyset[#keyset + 1] = k
    end

    return keyset
end
SCRB.getAvailableProfiles = addonTable.getAvailableProfiles

addonTable.getCurrentProfileName = function()
    return LEM.GetActiveLayoutName() or "Default"
end
SCRB.getCurrentProfileName = addonTable.getCurrentProfileName

addonTable.prettyPrint = function(...)
  print("|cffb5a707"..addonName..":|r", ...)
end

addonTable.clamp = function(x, min, max)
    if x < min then
        return min
    elseif x > max then
        return max
    else
        return x
    end
end

addonTable.rounded = function(num, idp)
    if not num then return num end

    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

addonTable.getPixelPerfectScale = function(customUIScale)
    local screenHeight = select(2, GetPhysicalScreenSize())
    local scale = customUIScale or UIParent:GetEffectiveScale()

    if scale == 0 or screenHeight == 0 then
        return 1
    end

    return 768 / screenHeight / scale
end

addonTable.getNearestPixel = function(value, customUIScale)
    if value == 0 then
        return 0
    end

    local ppScale = addonTable.getPixelPerfectScale(customUIScale)
    return addonTable.rounded(value / ppScale) * ppScale
end

addonTable.registerCustomFrame = function(customFrame, customFrameName)
	if type(customFrame) == "table" then
		customFrame = customFrame.GetName and customFrame:GetName() or nil
	end

	if customFrame and not addonTable.availableCustomFrames[customFrame] then
		addonTable.availableCustomFrames[customFrame] = customFrameName or customFrame
		addonTable.customFrameNamesToFrame[customFrameName or customFrame] = customFrame

		tinsert(addonTable.availableWidthModes, { text = customFrameName or customFrame })
		addonTable.fullUpdateBars()
	end
end
SCRB.registerCustomFrame = addonTable.registerCustomFrame