--[[
文件：02_cell.lua
定位：DejaVu 标准Cell创建模块
功能：
  - 创建和管理4x4像素单元的Cell对象
  - 提供颜色设置、位置管理、显示/隐藏控制
  - 优化颜色比较性能（处理秘密值）
依赖：
  - addonTable.COLOR 颜色定义
  - addonTable.Matrix.MartixFrame 父级框架
  - addonTable.Matrix.SIZE.CELL 单元格尺寸
接口：
  - Cell:New(x, y, backgroundColor) 构造函数
  - cell:setColor(color) 设置颜色
  - cell:getPosition() 获取位置
  - cell:show()/hide() 显示/隐藏

状态：
  waiting_real_test（等待真实测试）
]]
-- 本地化提高性能
local issecretvalue = issecretvalue
local CreateFrame = CreateFrame
local setmetatable = setmetatable


local addonName, addonTable = ... -- 插件名称与共享表
local COLOR = addonTable.COLOR

-- Cell 类定义
local Cell = {}
Cell.__index = Cell

-- Cell 构造函数
function Cell:New(x, y, backgroundColor)
    if not addonTable.Matrix.MartixFrame then
        return nil
    end

    local instance = setmetatable({}, self)
    instance:_initialize(x, y, backgroundColor)
    return instance
end

-- Cell 初始化方法（私有）
function Cell:_initialize(x, y, backgroundColor)
    if not backgroundColor then
        backgroundColor = COLOR.BLACK
    end

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

    self.Texture = cellTexture
    self.Frame = cellFrame
    self.Slug = cellSlug
    self.X = x
    self.Y = y
end

-- 比较颜色是否相同（处理秘密值）
-- 如果任意颜色是秘密值，返回false（视为不同，需要更新）
-- 如果都不是秘密值，使用IsEqualTo比较
function Cell:_isSameColor(color)
    -- 如果当前没有保存的颜色，视为不同
    if not self.lastColor then
        return false
    end

    -- 如果任意一方是秘密值，无法比较，视为不同
    if self.lastColorIsSecret or issecretvalue(color) then
        return false
    end

    -- 都不是秘密值，使用ColorMixin的IsEqualTo方法
    return self.lastColor:IsEqualTo(color)
end

-- 设置颜色方法
function Cell:setColor(color)
    -- 如果颜色相同，跳过设置以提高性能
    if self:_isSameColor(color) then
        return
    end

    -- 保存颜色状态
    self.lastColor = color
    self.lastColorIsSecret = issecretvalue(color)

    -- 设置贴图颜色
    self.Texture:SetColorTexture(color:GetRGBA())
end

-- 获取位置方法
function Cell:getPosition()
    return self.X, self.Y
end

-- 获取标识方法
function Cell:getSlug()
    return self.Slug
end

-- 显示方法
function Cell:show()
    self.Frame:Show()
end

-- 隐藏方法
function Cell:hide()
    self.Frame:Hide()
end

-- 判断是否显示
function Cell:isShown()
    return self.Frame:IsShown()
end

-- 工厂函数：创建 Cell 实例
function addonTable.CreateCell(x, y, backgroundColor)
    return Cell:New(x, y, backgroundColor)
end

-- 暴露 Cell 类到 addonTable，方便继承和扩展
addonTable.Cell = Cell
