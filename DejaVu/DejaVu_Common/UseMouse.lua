local addonName, addonTable = ... -- 插件入口固定写法

-- Lua 原生函数
local After = C_Timer.After
local random = math.random

-- WoW 官方 API
local CreateFrame = CreateFrame
local IsMouselooking = _G.IsMouselooking
local IsMouseButtonDown = _G.IsMouseButtonDown

local DejaVu = _G["DejaVu"]
local COLOR = DejaVu.COLOR
local Cell = DejaVu.Cell

After(2, function() -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local eventFrame = CreateFrame("Frame")
    local cell = Cell:New(58, 9) -- 记录鼠标正在使用

    local function updateCell()
        local useMouse = IsMouselooking()
            or IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
            or IsMouseButtonDown("Button4")
            or IsMouseButtonDown("Button5")
        cell:setCellBoolean(useMouse, COLOR.STATUS_BOOLEAN.USE_MOUSE, COLOR.BLACK)
    end

    local fastTimeElapsed = -random() -- 随机初始时间，避免所有事件在同一帧更新
    -- local lowTimeElapsed = -random() -- 当前未使用，保留 0.5 秒刷新档位结构
    -- local superLowTimeElapsed = -random() -- 当前未使用，保留 2 秒刷新档位结构

    function eventFrame:PLAYER_STARTED_TURNING()
        updateCell()
    end

    function eventFrame:PLAYER_STOPPED_TURNING()
        updateCell()
    end

    -- 监听转向开始，用事件触发即时刷新鼠标使用状态。
    eventFrame:RegisterEvent("PLAYER_STARTED_TURNING")
    -- 监听转向结束，用事件触发即时刷新鼠标使用状态。
    eventFrame:RegisterEvent("PLAYER_STOPPED_TURNING")
    -- 保持周期性轮询，覆盖按键按下等不会触发上述事件的鼠标输入。
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
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
end)
