local addonName, addonTable = ...
local InitUI = addonTable.Event.Func.InitUI
local GetUIScaleFactor = addonTable.Size.GetUIScaleFactor
local COLOR = addonTable.Panel.COLOR



local AddSliderRow = addonTable.Panel.AddSliderRow
local AddComboRow = addonTable.Panel.AddComboRow
local AddSpellListRow = addonTable.Panel.AddSpellListRow



local function CreatePanelRows()
    for _, row_info in ipairs(addonTable.Panel.Rows) do
        -- do some thing
        -- if row_info.type == "slider"  AddSliderRow..
    end
end

table.insert(InitUI, CreatePanelRows)
