--[[
文件：03_mega_cell.lua
定位：DejaVu 标准MegaCell创建模块
功能：
  - 创建和管理8x8像素单元的MegaCell对象
  - 提供图标设置、位置管理、显示/隐藏控制
  - 处理秘密值
依赖：
  - addonTable.COLOR 颜色定义
  - addonTable.Matrix.MartixFrame 父级框架
  - addonTable.Matrix.SIZE.CELL 单元格尺寸
  - addonTable.Matrix.SIZE.MEGA Mega单元格尺寸
接口：
  - MegaCell:New(x, y, backgroundColor) 构造函数
  - megaCell:setIcon(icon) 设置图标
  - megaCell:clearIcon() 清除图标

状态：
  waiting_real_test（等待真实测试）
]]
-- 本地化提高性能
local issecretvalue = issecretvalue
local CreateFrame = CreateFrame
local setmetatable = setmetatable


local addonName, addonTable = ... -- 插件名称与共享表
local COLOR = addonTable.COLOR

-- MegaCell 类定义
local MegaCell = {}
MegaCell.__index = MegaCell

-- MegaCell 构造函数
function MegaCell:New(x, y, backgroundColor)
    if not addonTable.Matrix.MartixFrame then
        return nil
    end

    local instance = setmetatable({}, self)
    instance:_initialize(x, y, backgroundColor)
    return instance
end

-- MegaCell 初始化方法（私有）
function MegaCell:_initialize(x, y, backgroundColor)
    if not backgroundColor then
        backgroundColor = COLOR.BLACK
    end

    local parent = addonTable.Matrix.MartixFrame
    local cellSize = addonTable.Matrix.SIZE.CELL
    local megaSize = addonTable.Matrix.SIZE.MEGA
    local cellSlug = x .. "_" .. y
    local cellName = addonName .. "MegaCell_" .. cellSlug

    -- 底层Frame
    local cellFrame = CreateFrame("Frame", cellName, parent)
    cellFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x * cellSize, -y * cellSize)
    cellFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    cellFrame:SetSize(megaSize, megaSize)
    cellFrame:Show()

    -- 中层背景色
    local cellTexture = cellFrame:CreateTexture(nil, "BACKGROUND")
    cellTexture:SetAllPoints(cellFrame)
    cellTexture:SetColorTexture(backgroundColor:GetRGBA())
    cellTexture:Show()

    -- 顶层图标
    local iconTexture = cellFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(cellFrame)
    iconTexture:Hide()

    self.Frame = cellFrame
    self.Background = cellTexture
    self.Icon = iconTexture
    self.Slug = cellSlug
    self.X = x
    self.Y = y
    self.lastIcon = nil
    self.lastIconIsSecret = false
end

-- 设置图标方法
function MegaCell:setIcon(icon)
    -- 检查是否为秘密值
    local isSecret = issecretvalue(icon)

    -- 如果图标相同且都不是秘密值，跳过设置以提高性能
    if not isSecret and not self.lastIconIsSecret and self.lastIcon == icon then
        return
    end

    -- 保存图标状态
    self.lastIcon = icon
    self.lastIconIsSecret = isSecret

    -- 设置图标
    self.Icon:SetTexture(icon)
    self.Icon:Show()
end

-- 清除图标方法
function MegaCell:clearIcon()
    self.Icon:Hide()
    self.lastIcon = nil
    self.lastIconIsSecret = false
end

-- 工厂函数：创建 MegaCell 实例
function addonTable.CreateMegaCell(x, y, backgroundColor)
    return MegaCell:New(x, y, backgroundColor)
end

-- 暴露 MegaCell 类到 addonTable，方便继承和扩展
addonTable.MegaCell = MegaCell
