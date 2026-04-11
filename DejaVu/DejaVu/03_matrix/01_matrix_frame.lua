--[[
文件: 01_matrix_frame.lua
定位: DejaVu 矩阵框架创建模块
功能:
  - 创建和管理矩阵主框架（MatrixFrame）
  - 初始化矩阵尺寸（CELL、MEGA、BADGE）
  - 提供矩阵背景与基础容器
依赖:
  - addonTable.Size.GetUIScaleFactor UI缩放计算
  - addonTable.Listeners.InitUI 初始化UI函数列表
接口:
  - InitializeSize() 初始化尺寸
  - CreateMatrixFrame() 创建矩阵框架
状态:
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ... -- 插件名称与共享表

-- WoW 官方 API
local CreateFrame = CreateFrame -- 创建框体
local UIParent = UIParent       -- 游戏主界面父框体

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI                -- 初始化 UI 函数列表
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor -- UI 缩放计算


local scale = 4

local function InitializeSize()              -- 初始化尺寸
    local SIZE = {                           -- 尺寸表主体
        MATRIX = {                           -- MatrixFrame有多个Cell
            Width = 84,                      -- Cell横向个数
            Height = 28,                     -- Cell纵向个数
        },
        CELL = GetUIScaleFactor(scale * 4),  -- Cell尺寸
        MEGA = GetUIScaleFactor(scale * 8),  -- MegaCell尺寸
        BADGE = GetUIScaleFactor(scale * 2), -- Badge尺寸
        FONT = GetUIScaleFactor(scale * 6),  -- Font尺寸
        PAD = GetUIScaleFactor(scale * 1),   -- Padding尺寸
    }                                        -- SIZE 结束
    addonTable.Matrix.SIZE = SIZE            -- 暴露到面板模块
end                                          -- InitializeSize 结束

local function CreateMatrixFrame()           -- 创建矩阵框架
    if addonTable.Matrix.MartixFrame then
        return
    end

    InitializeSize()

    local frame = CreateFrame("Frame", addonName .. "MartixFrame", UIParent)
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    frame:SetSize(addonTable.Matrix.SIZE.CELL * addonTable.Matrix.SIZE.MATRIX.Width, addonTable.Matrix.SIZE.CELL * addonTable.Matrix.SIZE.MATRIX.Height)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(900)
    frame:Show()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)
    bg:Show()
    addonTable.Matrix.MartixFrame = frame
end


table.insert(InitUI, CreateMatrixFrame) -- 第二帧创建面板
