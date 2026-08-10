-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- 插件级变量定义/引用
local PARTY_DAMAGE_ABSORB = addonTable.CELL_CLASSIFICATION.PARTY_DAMAGE_ABSORB
local ABSORB_THRESHOLD = addonTable.PLAYER_DAMAGE_ABSORB_THRESHOLD

-- 本地变量定义
local insert = table.insert
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- 代码部分
--[[
摘要：输出小队成员伤害吸收量阈值状态条。

描述：
状态条直接接收可能为 secret 的吸收量，阈值保持 10000；成员缺席时仅将本模块的对应条归零。

主要变量信息：
ABSORB_THRESHOLD 是原有吸收阈值；absorbBars 保存四个固定 party 行的独立状态条。

修改记录：
2026-07-26：按小队属性拆分需求迁移伤害吸收状态。
]]

local function InitFrame()
    local parent = addonTable.MartixFrame
    local size = addonTable.SIZE
    local absorbBars = {}

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        local absorbBar = CreateFrame("StatusBar", nil, parent)
        local red = PARTY_DAMAGE_ABSORB / 255
        local green = memberIndex / 255
        local y = PARTY_ROW_Y[memberIndex]

        absorbBar:SetSize(size.CELL, size.CELL)
        absorbBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 5 * size.CELL, -(y - 1) * size.CELL)
        absorbBar:SetStatusBarTexture(WHITE_TEXTURE)
        absorbBar:SetStatusBarColor(red, green, 1, 1)
        absorbBar:SetMinMaxValues(ABSORB_THRESHOLD, ABSORB_THRESHOLD + 1)
        local background = absorbBar:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(absorbBar)
        background:SetColorTexture(red, green, 0, 1)
        absorbBars[memberIndex] = absorbBar
    end

    local function updateBars()
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            if UnitExists(unitToken) then
                absorbBars[memberIndex]:SetValue(UnitGetTotalAbsorbs(unitToken))
            else
                absorbBars[memberIndex]:SetValue(0)
            end
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "party1", "party2", "party3", "party4")
    eventFrame:SetScript("OnEvent", updateBars)
    updateBars()
end

insert(addonTable.FrameInitFuncs, InitFrame)
