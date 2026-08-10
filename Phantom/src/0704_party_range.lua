-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame = CreateFrame
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local IsSpellInRange = C_Spell.IsSpellInRange
local NewTimer = C_Timer.NewTimer
local UnitExists = UnitExists

-- 插件级变量定义/引用
local Cell = addonTable.Cell
local logging = addonTable.logging
local PARTY_RANGE = addonTable.CELL_CLASSIFICATION.PARTY_RANGE

-- 本地变量定义
local insert = table.insert
local random = math.random
local FALLBACK_REFRESH_SECONDS = 0.2
local SPELL_REFRESH_DELAY_SECONDS = 0.25
local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local PARTY_ROW_Y = { 8, 9, 10, 11 }

-- 代码部分
--[[
摘要：输出按职业配置技能判断的小队成员距离状态。

描述：
技能书或进入世界事件发生后，模块立即停用当前技能并清理 Cell，再以 0.25 秒合并延迟按配置顺序
选择首个已学习且支持 player 友方距离查询的候选技能。距离没有稳定的状态事件，因此保留唯一的
0.2 秒错峰轮询；配置为空、无有效候选、成员缺席或距离结果不可用时清理自己的 Cell。

主要变量信息：
FALLBACK_REFRESH_SECONDS 是唯一的小队轮询周期；SPELL_REFRESH_DELAY_SECONDS 是技能选择合并延迟；
activeRangeSpellID 保存当前选中的技能；confirmedCandidateValid 独立记录最近一次候选确认结果；
PARTY_UNITS 和 PARTY_ROW_Y 保存固定成员映射。

修改记录：
2026-07-26：按小队属性拆分需求迁移距离状态，并保留原有连续距离轮询。
2026-07-26：按小队距离技能选择需求增加有序候选筛选、技能书刷新与错误节流。
]]

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}
    local activeRangeSpellID
    local confirmedCandidateValid
    local pendingRefreshTimer

    for memberIndex, unitToken in ipairs(PARTY_UNITS) do
        cells[memberIndex] = Cell:New({
            x = 4,
            y = PARTY_ROW_Y[memberIndex],
            classification = PARTY_RANGE,
            index = memberIndex,
            default_value = 0,
        })
    end

    local function clearCells()
        for memberIndex = 1, #cells do
            cells[memberIndex]:clearCell()
        end
    end

    local function updateCells()
        for memberIndex, unitToken in ipairs(PARTY_UNITS) do
            if not UnitExists(unitToken) or activeRangeSpellID == nil then
                cells[memberIndex]:clearCell()
            else
                local isInRange = IsSpellInRange(activeRangeSpellID, unitToken)
                if isInRange == nil then
                    cells[memberIndex]:clearCell()
                else
                    cells[memberIndex]:setCellBoolean(isInRange)
                end
            end
        end
    end

    -- 每次延迟刷新只确认一次候选状态，错误仅在首次失败或有效状态转为无效时输出。
    local function refreshActiveRangeSpell()
        local rangeSpellIDs = addonTable.SPEC.PartyRangeSpellIDs
        activeRangeSpellID = nil

        for candidateIndex = 1, #rangeSpellIDs do
            local spellID = rangeSpellIDs[candidateIndex]
            if IsSpellInSpellBook(spellID) then
                local friendlyRangeResult = IsSpellInRange(spellID, "player")
                if friendlyRangeResult ~= nil then
                    activeRangeSpellID = spellID
                    break
                end
            end
        end

        if activeRangeSpellID ~= nil then
            confirmedCandidateValid = true
            updateCells()
        elseif #rangeSpellIDs == 0 then
            confirmedCandidateValid = nil
            clearCells()
        else
            if confirmedCandidateValid ~= false then
                logging("PartyRangeSpellIDs 未找到已学习且支持友方距离检测的候选技能。")
            end
            confirmedCandidateValid = false
            clearCells()
        end
    end

    local function requestSpellRefresh()
        activeRangeSpellID = nil
        clearCells()

        if pendingRefreshTimer then
            pendingRefreshTimer:Cancel()
        end

        pendingRefreshTimer = NewTimer(SPELL_REFRESH_DELAY_SECONDS, function()
            pendingRefreshTimer = nil
            refreshActiveRangeSpell()
        end)
    end

    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "GROUP_ROSTER_UPDATE" then
            updateCells()
        else
            requestSpellRefresh()
        end
    end)
    local fallbackElapsed = -random()
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed
        if fallbackElapsed >= FALLBACK_REFRESH_SECONDS then
            fallbackElapsed = 0
            updateCells()
        end
    end)
    clearCells()
end

insert(addonTable.FrameInitFuncs, InitFrame)
