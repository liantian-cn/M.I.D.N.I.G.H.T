--[[
文件定位：
  DejaVu 设置面板主框架模块，负责创建panelFrame容器。


状态：
  draft
]]

local addonName, addonTable = ...
local InitUI = addonTable.Event.Func.InitUI
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local COLOR = addonTable.Panel.COLOR







local function CreatePanelFrame()
    print("..")
end

table.insert(InitUI, CreatePanelFrame)
