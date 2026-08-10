-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local issecretvalue         = issecretvalue
local UnitCastingDuration   = UnitCastingDuration
local UnitCastingInfo       = UnitCastingInfo
local UnitChannelDuration   = UnitChannelDuration
local UnitChannelInfo       = UnitChannelInfo
local UnitExists            = UnitExists

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell
local COLOR                 = addonTable.COLOR
local IconCell              = addonTable.IconCell

-- 本地变量定义
local insert                = table.insert
local random = math.random

-- 代码部分

--[[
简述：      焦点施法信息
分类：      焦点目标
分类索引：  9、10
位置：      7行55列、7行56列、5行37列图标

说明

显示焦点施法或引导进度、可中断状态和当前施法图标。潜在secret的纹理、持续时间对象和可中断标记直接交给允许secret参数的显示或求值API。

]]

local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.FOCUS_TARGET
local PROGRESS_CELL_INDEX = 9
local INTERRUPTIBLE_CELL_INDEX = 10
local PROGRESS_CELL_POSITION_X = 55
local PROGRESS_CELL_POSITION_Y = 7
local INTERRUPTIBLE_CELL_POSITION_X = 56
local INTERRUPTIBLE_CELL_POSITION_Y = 7
local ICON_CELL_POSITION_X = 37
local ICON_CELL_POSITION_Y = 5

local DEFAULT_VALUE = 0
local FALLBACK_REFRESH_SECONDS = 2
local PROGRESS_REFRESH_SECONDS = 0.1
local CAST_MODE_CASTING = "casting"
local CAST_MODE_CHANNELING = "channeling"
local UNIT_TOKEN = "focus"

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local progressMode = nil

    local progressCell = Cell:New({
        x = PROGRESS_CELL_POSITION_X,
        y = PROGRESS_CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = PROGRESS_CELL_INDEX,
        default_value = DEFAULT_VALUE,
    })

    local interruptibleCell = Cell:New({
        x = INTERRUPTIBLE_CELL_POSITION_X,
        y = INTERRUPTIBLE_CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = INTERRUPTIBLE_CELL_INDEX,
        default_value = DEFAULT_VALUE,
    })

    local iconCell = IconCell:New(ICON_CELL_POSITION_X, ICON_CELL_POSITION_Y)

    local function clearIcon()
        iconCell.Icon:SetTexture(nil)
        iconCell.Icon:Hide()
        iconCell.Border:Hide()
    end

    local function clearCastState()
        progressMode = nil
        progressCell:clearCell()
        interruptibleCell:clearCell()
        clearIcon()
    end

    local function updateProgressCell()
        if not UnitExists(UNIT_TOKEN) then
            clearCastState()
            return
        end

        if progressMode == CAST_MODE_CASTING then
            local duration = UnitCastingDuration(UNIT_TOKEN)

            if not issecretvalue(duration) and duration == nil then
                progressCell:clearCell()
                return
            end

            progressCell:setCell(duration:EvaluateElapsedPercent(progressCell.zeroToOneCurve))
        elseif progressMode == CAST_MODE_CHANNELING then
            local duration = UnitChannelDuration(UNIT_TOKEN)

            if not issecretvalue(duration) and duration == nil then
                progressCell:clearCell()
                return
            end

            progressCell:setCell(duration:EvaluateElapsedPercent(progressCell.zeroToOneCurve))
        else
            progressCell:clearCell()
        end
    end

    local function applyInterruptibleState(notInterruptible)
        if not issecretvalue(notInterruptible) and notInterruptible == nil then
            interruptibleCell:clearCell()
            iconCell.Border:Hide()
            return
        end

        interruptibleCell:setCellBoolean(notInterruptible, true)
        iconCell:SetBorderColor(EvaluateColorFromBoolean(
            notInterruptible,
            COLOR.ENEMY_SPELL_NOT_INTERRUPTIBLE,
            COLOR.ENEMY_SPELL_INTERRUPTIBLE
        ))
    end

    local function updateCastState()
        if not UnitExists(UNIT_TOKEN) then
            clearCastState()
            return
        end

        -- delayTimeMs is a required NeverSecret sentinel for an active cast, avoiding branches on secret texture or name.
        local _, _, castingTexture, _, _, _, _, castNotInterruptible, _, _, castDelayTimeMs = UnitCastingInfo(UNIT_TOKEN)

        if castDelayTimeMs ~= nil then
            progressMode = CAST_MODE_CASTING
            iconCell:SetIcon(castingTexture)
            applyInterruptibleState(castNotInterruptible)
            updateProgressCell()
            return
        end

        -- isEmpowered is a required NeverSecret sentinel for an active channel, avoiding branches on secret texture or name.
        local _, _, channelTexture, _, _, _, channelNotInterruptible, _, isEmpowered = UnitChannelInfo(UNIT_TOKEN)

        if isEmpowered ~= nil then
            progressMode = CAST_MODE_CHANNELING
            iconCell:SetIcon(channelTexture)
            applyInterruptibleState(channelNotInterruptible)
            updateProgressCell()
            return
        end

        clearCastState()
    end

    updateCastState()

    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", UNIT_TOKEN)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", UNIT_TOKEN)

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        updateCastState()
    end)

    local fallbackElapsed = -random()
    local progressElapsed = 0
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed

        if fallbackElapsed >= FALLBACK_REFRESH_SECONDS then
            fallbackElapsed = 0
            updateCastState()
        end

        if progressMode then
            progressElapsed = progressElapsed + elapsed

            if progressElapsed >= PROGRESS_REFRESH_SECONDS then
                progressElapsed = 0
                updateProgressCell()
            end
        else
            progressElapsed = 0
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
