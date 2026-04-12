local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local After = C_Timer.After
local random = math.random

-- WoW 官方 API
local CreateFrame = CreateFrame

local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell

After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local cell = Cell:New(54, 9) -- 闪烁 cell，用于判断插帧
    local flashValue = true

    local function updateCell()
        cell:setCellBoolean(flashValue, COLOR.WHITE, COLOR.BLACK)
        flashValue = not flashValue
    end

    local eventFrame = CreateFrame("Frame")
    local fastTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    -- local lowTimeElapsed = -random() -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构
    eventFrame:HookScript("OnUpdate", function(frame, elapsed)
        fastTimeElapsed = fastTimeElapsed + elapsed
        if fastTimeElapsed > 0.1 then
            fastTimeElapsed = fastTimeElapsed - 0.1
            updateCell()
        end
        -- lowTimeElapsed = lowTimeElapsed + elapsed
        -- if lowTimeElapsed > 0.5 then
        --     lowTimeElapsed = lowTimeElapsed - 0.5
        --     updateCell()
        -- end
        -- superLowTimeElapsed = superLowTimeElapsed + elapsed
        -- if superLowTimeElapsed > 2 then
        --     superLowTimeElapsed = superLowTimeElapsed - 2
        --     updateCell()
        -- end
    end)
end)
