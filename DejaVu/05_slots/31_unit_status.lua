--[[
文件定位：
  DejaVu 通用单位状态显示模块。



状态：
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法
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

local InitUI = addonTable.UpdateFunc.InitUI                       -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR                                    -- 颜色表
local Cell = addonTable.Cell                                      -- 基础色块单元
local BadgeCell = addonTable.BadgeCell                            -- 图标单元
local CharCell = addonTable.CharCell                              -- 文字单元

local OnUpdateHigh = addonTable.UpdateFunc.OnUpdateHigh           -- 高频刷新回调列表
local UNIT_AURA = addonTable.UpdateFunc.UNIT_AURA                 -- UNIT_AURA 回调列表
local TARGET_CHANGED = addonTable.UpdateFunc.TARGET_CHANGED       -- 目标变化回调列表
local FOCUS_CHANGED = addonTable.UpdateFunc.FOCUS_CHANGED         -- 焦点变化回调列表
local MOUSEOVER_CHANGED = addonTable.UpdateFunc.MOUSEOVER_CHANGED -- 鼠标悬停变化回调列表

local remainingCurve = addonTable.Slots.remainingCurve            -- 剩余时间颜色曲线
local playerDebuffCurve = addonTable.Slots.playerDebuffCurve      -- 玩家身上减益颜色曲线
local enemyDebuffCurve = addonTable.Slots.enemyDebuffCurve        -- 敌方身上减益颜色曲线
local playerBuffCurve = addonTable.Slots.playerBuffCurve          -- 玩家身上增益颜色曲线

--[[
表格定位指导

 y\x | 0           | 1        | 2                 | 3             | 4               | 5                   | 6                          | 7                   | 8
 0   | unitExists  | unitClass| unitHealthPercent | unitIsEnemy   | unitCastIcon    | unitCastDuration    | unitCastIsInterruptible    | unitIsInRangedRange | unitIsInCombat
 1   | unitIsAlive | unitRole | unitPowerPercent  | unitCanAttack | unitChannelIcon | unitChannelDuration | unitChannelIsInterruptible | unitIsInMeleeRange  | unitIsTarget
]]


local function UnitStatusSequenceCreator(options) -- 创建一组单位状态显示槽位
    local unit = options.unit                     -- 目标单位
    local posX = options.posX                     -- 左上角 x 坐标
    local posY = options.posY                     -- 左上角 y 坐标
    local cell = {}                               -- 单元格对象列表
    local x = posX
    local y = posY
    cell.unitExists = Cell:New(posX, posY) -- 单位存在状态
end
