-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame           = CreateFrame

-- 插件级变量定义/引用
local Cell                  = addonTable.Cell
local Config                = addonTable.Config
local logging               = addonTable.logging

-- 本地变量定义
local insert                = table.insert
local tostring              = tostring

-- 代码部分

--[[
摘要：      输出当前首领战的兼容紧凑编码
分类：      环境信息
分类索引：  3
位置：      5行41列

描述：
首领战开始时将 encounterID 映射为约定的紧凑编码并写入 Cell，战斗结束时清零。
未知且有效的 encounterID 写入 0；诊断配置开启时，每个未知 ID 仅记录一次日志。

主要变量信息：
- BOSS_ENCOUNTER_CODES：encounterID 到紧凑编码的映射，分别包含团本与大米首领。
- unknownEncounterDiagnostic：控制未知首领 ID 诊断日志的配置项，默认开启。
- loggedUnknownEncounterIDs：记录本次会话中已经报告过的未知 ID，避免重复日志。
- cell：环境信息分类第 3 个 Cell，位于第 5 行第 41 列。

修改记录：
- 2026-07-26：根据本次补充注释需求完善文件说明、映射、诊断与事件流程注释。

]]

-- 分类定义
local CELL_CLASSIFICATION = addonTable.CELL_CLASSIFICATION.ENVIRONMENT
local CELL_CLASSIFICATION_INDEX = 3
local CELL_POSITION_X = 41
local CELL_POSITION_Y = 5

-- 默认值：cell初始化时的B通道值（0-255）
local DEFAULT_VALUE = 0

-- encounterID 到紧凑编码的兼容映射；团本使用 1 起始，大米使用 51 起始。
local BOSS_ENCOUNTER_CODES = {
    -- 团本
    [3176] = 1,
    [3177] = 2,
    [3179] = 3,
    [3178] = 4,
    [3180] = 5,
    [3181] = 6,
    [3306] = 7,
    [3182] = 8,
    [3183] = 9,
    [3454] = 10,
    [3459] = 11,
    [3431] = 12,
    [3436] = 13,
    -- 大米
    [3328] = 51,
    [3332] = 52,
    [3333] = 53,
    [3212] = 54,
    [3213] = 55,
    [3214] = 56,
    [3056] = 57,
    [3057] = 58,
    [3058] = 59,
    [3059] = 60,
    [3071] = 61,
    [3072] = 62,
    [3073] = 63,
    [3074] = 64,
    [2065] = 65,
    [2066] = 66,
    [2067] = 67,
    [2068] = 68,
    [2562] = 69,
    [2563] = 70,
    [2564] = 71,
    [2565] = 72,
    [1999] = 73,
    [2001] = 74,
    [2000] = 75,
    [1698] = 76,
    [1699] = 77,
    [1700] = 78,
    [1701] = 79,
}

local unknownEncounterDiagnostic = Config("boss_encounter_unknown_id_diagnostic")
unknownEncounterDiagnostic:set_default(true)

-- 未知 ID 只在首次遇到时记录，避免同一会话重复输出诊断信息。
local loggedUnknownEncounterIDs = {}

local function InitFrame()
    local eventFrame = CreateFrame("Frame") -- 每个文件独立的事件框架

    local cell = Cell:New({
        x = CELL_POSITION_X,
        y = CELL_POSITION_Y,
        classification = CELL_CLASSIFICATION,
        index = CELL_CLASSIFICATION_INDEX,
        default_value = DEFAULT_VALUE,
    })

    -- R、G 通道标识环境信息分类及索引，B 通道保存首领紧凑编码。
    local function updateCell(value)
        cell:setCellRGBA(
            CELL_CLASSIFICATION / 255,
            CELL_CLASSIFICATION_INDEX / 255,
            value / 255
        )
    end

    updateCell(DEFAULT_VALUE)

    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")

    -- 开战时完成映射与可选诊断，结束时无条件清除当前首领编码。
    eventFrame:SetScript("OnEvent", function(_, event, encounterID)
        if event == "ENCOUNTER_START" then
            local value = BOSS_ENCOUNTER_CODES[encounterID] or 0

            if encounterID and encounterID ~= 0 and value == 0
                and unknownEncounterDiagnostic:get_value()
                and not loggedUnknownEncounterIDs[encounterID] then
                loggedUnknownEncounterIDs[encounterID] = true
                logging(" Unknown boss encounter ID: " .. tostring(encounterID))
            end

            updateCell(value)
        elseif event == "ENCOUNTER_END" then
            updateCell(0)
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
