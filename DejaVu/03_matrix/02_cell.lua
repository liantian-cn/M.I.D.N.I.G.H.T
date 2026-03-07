--[[
文件定位：
  DejaVu 标准Cell创建模块，负责4x4像素单元的创建。



状态：
  draft
]]

local addonName, addonTable = ... -- 插件名称与共享表
local COLOR = addonTable.COLOR

function addonTable.CreateCell(x, y, backgroundColor)
    if not addonTable.Matrix.MartixFrame then
        return
    end
    if not backgroundColor then
        backgroundColor = COLOR.BLACK
    end
    local cell = {}
    local parent = addonTable.Matrix.MartixFrame
    local cellSize = addonTable.Matrix.SIZE.CELL
    local cellSlug = x .. "_" .. y
    local cellName = addonName .. "Cell_" .. cellSlug
    local cellFrame = CreateFrame("Frame", cellName, parent)
    cellFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x * cellSize, -y * cellSize)
    cellFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    cellFrame:SetSize(cellSize, cellSize)
    cellFrame:Show()
    local cellTexture = cellFrame:CreateTexture(nil, "BACKGROUND")
    cellTexture:SetAllPoints(cellFrame)
    cellTexture:SetColorTexture(backgroundColor:GetRGBA())
    cellTexture:Show()
    cell.Texture = cellTexture
    cell.Frame = cellFrame
    cell.Slug = cellSlug
    cell.X = x
    cell.Y = y
    local function setColor(color)
        cell.Texture:SetColorTexture(color:GetRGBA())
    end
    cell.setColor = setColor
    -- return cellTexture, cellFrame
end
