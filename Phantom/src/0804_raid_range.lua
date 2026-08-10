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
local RAID_MEMBER_COUNT = 30

-- 代码部分
--[[
摘要：输出按职业配置技能判断的 raid1 至 raid30 距离状态。

描述：
模块按 PartyRangeSpellIDs 顺序选择首个已学习且支持友方距离查询的技能。技能书刷新期间先清理输出，
再以 0.25 秒合并延迟重新选择；距离状态仅由本团队模块的 0.2 秒错峰轮询持续刷新。
配置为空、候选不可用、成员缺席或范围结果为 nil 时，仅清理对应 PARTY_RANGE Cell。

主要变量信息：
RAID_LAYOUT 保存固定团队布局；activeRangeSpellID 保存当前距离技能；confirmedCandidateValid 用于错误节流；
FALLBACK_REFRESH_SECONDS 是团队距离模块唯一的轮询周期。

修改记录：
2026-07-30：按团队属性冻结计划新增团队距离输出并保留小队模块的候选选择契约。
]]

local RAID_LAYOUT = {}

for raidNumber = 1, RAID_MEMBER_COUNT do
    local x
    local y
    if raidNumber <= 10 then
        x = 31 + ((raidNumber - 1) % 5) * 6
        y = raidNumber <= 5 and 8 or 10
    else
        x = 1 + ((raidNumber - 11) % 10) * 6
        y = raidNumber <= 20 and 12 or 14
    end
    RAID_LAYOUT[raidNumber] = {
        unitToken = "raid" .. raidNumber,
        x = x,
        y = y,
        index = raidNumber + 10,
    }
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local cells = {}
    local activeRangeSpellID
    local confirmedCandidateValid
    local pendingRefreshTimer

    for raidNumber, member in ipairs(RAID_LAYOUT) do
        cells[raidNumber] = Cell:New({
            x = member.x + 3,
            y = member.y,
            classification = PARTY_RANGE,
            index = member.index,
            default_value = 0,
        })
    end

    local function clearCells()
        for raidNumber = 1, RAID_MEMBER_COUNT do
            cells[raidNumber]:clearCell()
        end
    end

    local function updateCells()
        for raidNumber, member in ipairs(RAID_LAYOUT) do
            if not UnitExists(member.unitToken) or activeRangeSpellID == nil then
                cells[raidNumber]:clearCell()
            else
                local isInRange = IsSpellInRange(activeRangeSpellID, member.unitToken)
                if isInRange == nil then
                    cells[raidNumber]:clearCell()
                else
                    cells[raidNumber]:setCellBoolean(isInRange)
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
