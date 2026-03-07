local addonName, addonTable = ...
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local Enum = Enum
local COLOR = addonTable.COLOR

-- Slots模块命名空间
addonTable.Slots = {}



local remainingCurve = CreateColorCurve()
remainingCurve:SetType(Enum.LuaCurveType.Linear)
remainingCurve:AddPoint(0.0, COLOR.C0)
remainingCurve:AddPoint(5.0, COLOR.C100)
remainingCurve:AddPoint(30.0, COLOR.C150)
remainingCurve:AddPoint(155.0, COLOR.C200)
remainingCurve:AddPoint(375.0, COLOR.C255)

addonTable.Slots.remainingCurve = remainingCurve
