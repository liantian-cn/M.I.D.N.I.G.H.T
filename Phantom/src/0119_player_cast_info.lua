-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame
local issecretvalue         = issecretvalue
local UnitCastingDuration   = UnitCastingDuration
local UnitCastingInfo       = UnitCastingInfo
local UnitChannelDuration   = UnitChannelDuration
local UnitChannelInfo       = UnitChannelInfo

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell
local COLOR                 = addonTable.COLOR
local IconCell              = addonTable.IconCell

-- 本地变量定义
local insert                = table.insert

-- 代码部分

--[[
简述：      玩家施法信息
分类：      玩家属性
分类索引：  19、20
位置：      7行19列、7行20列、5行33列图标

说明

显示玩家施法或引导进度、蓄力引导状态和当前施法图标。

]]

-- 分类定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.PLAYER_STATUS
local PROGRESS_CELL_INDEX = 19
local EMPOWERED_CELL_INDEX = 20
local PROGRESS_CELL_POSITION_X = 19
local EMPOWERED_CELL_POSITION_X = 20
local CELL_POSITION_Y = 7
local ICON_CELL_POSITION_X = 33
local ICON_CELL_POSITION_Y = 5

-- 默认值：cell初始化时的B通道值（0-255）
local DEFAULT_VALUE = 0
local PROGRESS_REFRESH_SECONDS = 0.1
local CAST_MODE_CASTING = "casting"
local CAST_MODE_CHANNELING = "channeling"

local function InitFrame()
    local eventFrame = CreateFrame("Frame") -- 每个文件独立的事件框架
    local progressMode = nil

    local progressCell = Cell:New({
        x = PROGRESS_CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = PROGRESS_CELL_INDEX,
        default_value = DEFAULT_VALUE,
    })

    local empoweredCell = Cell:New({
        x = EMPOWERED_CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = EMPOWERED_CELL_INDEX,
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
        empoweredCell:clearCell()
        clearIcon()
    end

    local function updateProgressCell()
        if progressMode == CAST_MODE_CASTING then
            local duration = UnitCastingDuration("player")

            if not issecretvalue(duration) and duration == nil then
                progressCell:clearCell()
                return
            end

            progressCell:setCell(duration:EvaluateElapsedPercent(progressCell.zeroToOneCurve))
        elseif progressMode == CAST_MODE_CHANNELING then
            local duration = UnitChannelDuration("player")

            if not issecretvalue(duration) and duration == nil then
                progressCell:clearCell()
                return
            end

            progressCell:setCell(duration:EvaluateElapsedPercent(progressCell.zeroToOneCurve))
        else
            progressCell:clearCell()
        end
    end

    local function updateCastState()
        -- delayTimeMs is a required NeverSecret sentinel for an active cast, avoiding branches on secret texture or name.
        local _, _, castingTexture, _, _, _, _, _, _, _, castDelayTimeMs = UnitCastingInfo("player")

        if castDelayTimeMs ~= nil then
            progressMode = CAST_MODE_CASTING
            iconCell:SetIcon(castingTexture)
            iconCell:SetBorderColor(COLOR.PLAYER_SPELL)
            empoweredCell:setCellBoolean(false)
            updateProgressCell()
            return
        end

        -- isEmpowered is a required NeverSecret sentinel for an active channel, avoiding branches on secret texture or name.
        local _, _, channelTexture, _, _, _, _, _, isEmpowered = UnitChannelInfo("player")

        if isEmpowered ~= nil then
            progressMode = CAST_MODE_CHANNELING
            iconCell:SetIcon(channelTexture)
            iconCell:SetBorderColor(COLOR.PLAYER_SPELL)
            empoweredCell:setCellBoolean(isEmpowered)
            updateProgressCell()
            return
        end

        clearCastState()
    end

    updateCastState()

    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        updateCastState()
    end)

    local progressElapsed = 0
    eventFrame:HookScript("OnUpdate", function(self, elapsed)
        progressElapsed = progressElapsed + elapsed

        if progressElapsed >= PROGRESS_REFRESH_SECONDS then
            progressElapsed = 0
            updateProgressCell()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
