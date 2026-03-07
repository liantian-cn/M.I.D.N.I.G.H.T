-- luacheck: globals C_CurveUtil Enum
local addonName, addonTable = ... -- luacheck: ignore addonName
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local Enum = Enum
local COLOR = addonTable.COLOR

-- `05_slots` 模块命名空间
addonTable.Slots = {}


local remainingCurve = CreateColorCurve()
remainingCurve:SetType(Enum.LuaCurveType.Linear)
remainingCurve:AddPoint(0.0, COLOR.C0)
remainingCurve:AddPoint(5.0, COLOR.C100)
remainingCurve:AddPoint(30.0, COLOR.C150)
remainingCurve:AddPoint(155.0, COLOR.C200)
remainingCurve:AddPoint(375.0, COLOR.C255)


local playerDebuffCurve = CreateColorCurve()
playerDebuffCurve:AddPoint(0, COLOR.SPELL_TYPE.PLAYER_DEBUFF)
playerDebuffCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
playerDebuffCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
playerDebuffCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
playerDebuffCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
playerDebuffCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
playerDebuffCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)


local playerBuffCurve = CreateColorCurve()
playerBuffCurve:AddPoint(0, COLOR.SPELL_TYPE.PLAYER_BUFF)
playerBuffCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
playerBuffCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
playerBuffCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
playerBuffCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
playerBuffCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
playerBuffCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)



local enemyDebuffCurve = CreateColorCurve()
enemyDebuffCurve:AddPoint(0, COLOR.SPELL_TYPE.ENEMY_DEBUFF)
enemyDebuffCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
enemyDebuffCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
enemyDebuffCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
enemyDebuffCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
enemyDebuffCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
enemyDebuffCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)


addonTable.Slots.remainingCurve = remainingCurve
addonTable.Slots.playerDebuffCurve = playerDebuffCurve
addonTable.Slots.playerBuffCurve = playerBuffCurve
addonTable.Slots.enemyDebuffCurve = enemyDebuffCurve
