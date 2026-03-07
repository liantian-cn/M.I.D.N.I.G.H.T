--[[
文件定位：




状态：
  draft
]]

local addonName, addonTable = ... -- 插件名称与共享表
local CreateFrame = CreateFrame
local UIParent = UIParent
local InitUI = addonTable.Event.Func.InitUI               -- 初始化 UI 函数列表
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放计算


local scale = 4

local function InitializeSize()              -- 初始化尺寸
    local SIZE = {                           -- 尺寸表主体
        MATRIX = {                           -- MatrixFrame有多个Cell
            Width = 98,                      -- Cell横向个数
            Height = 36,                     -- Cell纵向个数
        },
        CELL = GetUIScaleFactor(scale * 4),  -- Cell尺寸
        MEGA = GetUIScaleFactor(scale * 8),  -- MegaCell尺寸
        BADGE = GetUIScaleFactor(scale * 2), -- Badge尺寸
    }                                        -- SIZE 结束
    addonTable.Matrix.SIZE = SIZE            -- 暴露到面板模块
end                                          -- InitializeSize 结束

local function CreateMatrixFrame()           -- 创建矩阵框架
    if addonTable.Matrix.MartixFrame then
        return
    end

    InitializeSize()

    local frame = CreateFrame("Frame", addonName .. "MartixFrame", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(addonTable.Matrix.SIZE.CELL * addonTable.Matrix.SIZE.MATRIX.Width, addonTable.Matrix.SIZE.CELL * addonTable.Matrix.SIZE.MATRIX.Height)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(900)
    frame:Show()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    bg:Show()
    addonTable.Matrix.MartixFrame = frame
end


table.insert(InitUI, CreateMatrixFrame) -- 第二帧创建面板
