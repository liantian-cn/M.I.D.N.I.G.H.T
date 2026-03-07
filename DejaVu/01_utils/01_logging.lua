--[[
文件定位：
  DejaVu 日志组件，提供统一的日志输出与调试辅助功能。



状态：
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName

local function logging(msg)
    print("|cFFFFBB66[DéjàVu]|r" .. tostring(msg))
end
addonTable.Logging = logging
