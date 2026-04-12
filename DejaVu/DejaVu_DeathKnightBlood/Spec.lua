local addonName, addonTable             = ... -- luacheck: ignore addonName

-- Lua 原生函数
local After                             = C_Timer.After
local random                            = math.random
local insert                            = table.insert -- 表插入

-- WoW 官方 API
local CreateFrame                       = CreateFrame
local GetRuneCooldown                   = GetRuneCooldown
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEATHKNIGHT" then
    C_AddOns.DisableAddOn(addonName)
    return
end                                 -- 不是死亡骑士则停止
if currentSpec ~= 1 then return end -- 不是鲜血专精则停止
-- DejaVu Core
local DejaVu = _G["DejaVu"]
local Cell = DejaVu.Cell


After(2, function()                    -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local cells = {
        ReadyRunes = Cell:New(55, 13) -- 可用符文数量
    }


    local function UpdateReadyRunes()
        local readyRunes = 0
        for runeIndex = 1, 6 do
            local startTime, duration, runeReady = GetRuneCooldown(runeIndex) -- luacheck: ignore startTime duration
            if runeReady then
                readyRunes = readyRunes + 1
            end
        end
        cells.ReadyRunes:setCellRGBA(readyRunes * 10 / 255)
    end



    local eventFrame = CreateFrame("Frame")
    local fastTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    -- local lowTimeElapsed = -random() -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            UpdateReadyRunes()
        end
        -- lowTimeElapsed = lowTimeElapsed + elapsed
        -- if lowTimeElapsed > 0.5 then
        --     lowTimeElapsed = lowTimeElapsed - 0.5
        --     UpdateReadyRunes()
        -- end
        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        --     UpdateReadyRunes()
        -- end
    end)
end)
