--[[
文件定位：




状态：
  draft
]]

local addonName, addonTable = ...
addonTable.Size = {}

local Size = addonTable.Size

addonTable.Size.GetUIScaleFactor = function(pixelValue)
    local _, physicalHeight = GetPhysicalScreenSize()
    local logicalHeight = GetScreenHeight()
    return (pixelValue * logicalHeight) / physicalHeight
end
