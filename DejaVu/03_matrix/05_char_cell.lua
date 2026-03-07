--[[
文件：05_char_cell.lua
定位：DejaVu 标准CharCell创建模块
功能：
  - 创建和管理显示文本的8x8像素单元的CharCell对象
  - 提供文本设置、位置管理、显示/隐藏控制
依赖：
  - addonTable.Matrix.MartixFrame 父级框架
  - addonTable.Matrix.SIZE.CELL 单元格尺寸
  - addonTable.Matrix.SIZE.MEGA Mega单元格尺寸
  - addonTable.Matrix.SIZE.FONT 字体大小
  - addonTable.Matrix.Font 字体路径
接口：
  - CharCell:New(x, y) 构造函数
  - charCell:setCell(text) 设置文本
  - charCell:clearCell() 清除文本

状态：
  waiting_real_test（等待真实测试）
]]
-- 本地化提高性能
local CreateFrame = CreateFrame
local setmetatable = setmetatable


local addonName, addonTable = ... -- 插件名称与共享表
local COLOR = addonTable.COLOR

---@class CharCell
---@field Frame Frame CharCell底层框架
---@field Background Texture 背景纹理（+1层）
---@field FontString FontString 文本层（+2层）
---@field Slug string 单元格唯一标识（格式：x_y）
---@field X integer X坐标
---@field Y integer Y坐标
---@field lastText? string 上次设置的文本
local CharCell = {}
CharCell.__index = CharCell

---CharCell 构造函数
---@param x integer X坐标（以单元格为单位）
---@param y integer Y坐标（以单元格为单位）
---@return CharCell|nil 返回CharCell实例，如果父框架不存在则返回nil
function CharCell:New(x, y)
    if not addonTable.Matrix.MartixFrame then
        return nil
    end

    local instance = setmetatable({}, self)
    instance:_initialize(x, y)
    return instance
end

---CharCell 初始化方法（私有）
---@private
---@param x integer X坐标
---@param y integer Y坐标
function CharCell:_initialize(x, y)
    local parent = addonTable.Matrix.MartixFrame
    local cellSize = addonTable.Matrix.SIZE.CELL
    local megaSize = addonTable.Matrix.SIZE.MEGA
    local fontSize = addonTable.Matrix.SIZE.FONT
    local fontPath = addonTable.Matrix.Font
    local cellSlug = x .. "_" .. y
    local cellName = addonName .. "CharCell_" .. cellSlug

    -- 底层Frame（+0层）
    local cellFrame = CreateFrame("Frame", cellName, parent)
    cellFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x * cellSize, -y * cellSize)
    cellFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    cellFrame:SetSize(megaSize, megaSize)
    cellFrame:Show()

    -- 背景色层（+1层）
    local cellTexture = cellFrame:CreateTexture(nil, "BACKGROUND")
    cellTexture:SetAllPoints(cellFrame)
    cellTexture:SetColorTexture(COLOR.BLACK:GetRGBA())
    cellTexture:Show()

    -- 文本层（+2层）
    local fontString = cellFrame:CreateFontString(nil, "ARTWORK")
    fontString:SetAllPoints(cellFrame)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    fontString:SetFontObject(GameFontHighlight)
    fontString:SetTextColor(1, 1, 1, 1)
    fontString:SetFont(fontPath, fontSize, "MONOCHROME")
    fontString:SetText("")
    fontString:Show()

    self.Frame = cellFrame
    self.Background = cellTexture
    self.FontString = fontString
    self.Slug = cellSlug
    self.X = x
    self.Y = y
    self.lastText = nil
end

---比较文本是否相同
---@private
---@param text string 要比较的文本
---@return boolean 如果文本相同返回true，否则返回false
function CharCell:_isSameText(text)
    return self.lastText == text
end

---设置单元格方法（设置文本）
---@param text string 要显示的文本
function CharCell:setCell(text)
    -- 如果文本相同，跳过设置以提高性能
    if self:_isSameText(text) then
        return
    end

    -- 保存文本状态
    self.lastText = text

    -- 设置文本
    self.FontString:SetText(text)
end

---清除单元格方法（清空文本）
function CharCell:clearCell()
    self.FontString:SetText("")
    self.lastText = nil
end

---工厂函数：创建 CharCell 实例
---@param x integer X坐标
---@param y integer Y坐标
---@return CharCell|nil 返回CharCell实例
function addonTable.CreateCharCell(x, y)
    return CharCell:New(x, y)
end

-- 暴露 CharCell 类到 addonTable，方便继承和扩展
addonTable.CharCell = CharCell
