--[[
文件定位：




状态：
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenHeight = GetScreenHeight



addonTable.Size = {}

local Size = addonTable.Size

addonTable.Size.GetUIScaleFactor = function(pixelValue)
    local physicalHeight = select(2, GetPhysicalScreenSize())
    local logicalHeight = GetScreenHeight()
    return (pixelValue * logicalHeight) / physicalHeight
end
