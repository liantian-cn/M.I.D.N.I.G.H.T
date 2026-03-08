-- unit 状态格子位置表（x = 列，y = 行）
-- 这套命名里的 unit 表示任意单位，例如 player、target、focus、mouseover、party1-4。
--
-- y\x | 0                        | 1                    | 2                              | 3                    | 4                      | 5                          | 6                                  | 7                              | 8
-- 0   | 存在 unitExists          | 的职业 unitClass     | 的血量 unitHealthPercent       | 是敌人 unitIsEnemy   | 施法图标 unitCastIcon  | 施法进度 unitCastProgress  | 施法可打断 unitCastIsInterruptible | 在远程范围 unitIsInRangedRange | 在战斗中 unitIsInCombat
-- 1   | 存活 unitIsAlive         | 的职责 unitRole      | 的能量 unitPowerPercent        | 可以攻击 unitCanAttack | 通道法术图标 unitChannelIcon | 通道法术进度 unitChannelProgress | 通道法术可打断 unitChannelIsInterruptible | 在近战范围 unitIsInMeleeRange  | 是当前目标 unitIsTarget

local GetSpellCharges = C_Spell.GetSpellCharges
local GetNumSpellBookSkillLines = C_SpellBook.GetNumSpellBookSkillLines
local GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo
local GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo
local IsSpellPassive = C_Spell.IsSpellPassive
local IsSpellBookItemOffSpec = C_SpellBook.IsSpellBookItemOffSpec
local InsertTable = table.insert
local Wipe = wipe
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor
local DoesAuraHaveExpirationTime = C_UnitAuras.DoesAuraHaveExpirationTime
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealthMax = UnitHealthMax
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit
local UnitIsEnemy = UnitIsEnemy
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitChannelDuration = UnitChannelDuration
local UnitCastingDuration = UnitCastingDuration
local UnitInVehicle = UnitInVehicle
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local IsMounted = IsMounted
local GetUnitSpeed = GetUnitSpeed
local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local IsSpellUsable = C_Spell.IsSpellUsable
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local GetSpellLink = C_Spell.GetSpellLink
local CreateColorCurve = C_CurveUtil.CreateColorCurve
