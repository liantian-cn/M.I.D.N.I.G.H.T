-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame                       = CreateFrame
local GetCooldownViewerCategorySet      = C_CooldownViewer.GetCooldownViewerCategorySet
local GetCooldownViewerCooldownInfo     = C_CooldownViewer.GetCooldownViewerCooldownInfo
local GetSpellName                      = C_Spell.GetSpellName
local GetSpellTexture                   = C_Spell.GetSpellTexture
local RequestLoadSpellData              = C_Spell.RequestLoadSpellData
local ESSENTIAL_CATEGORY                = Enum.CooldownViewerCategory.Essential
local UTILITY_CATEGORY                  = Enum.CooldownViewerCategory.Utility

-- 插件级变量定义/引用
local Cell                              = addonTable.Cell
local Config                            = addonTable.Config
local IconCell                          = addonTable.IconCell
local ENEMY_SPELL_INTERRUPTIBLE_COLOR   = addonTable.COLOR.ENEMY_SPELL_INTERRUPTIBLE
local PLAYER_SPELL_COLOR                = addonTable.COLOR.PLAYER_SPELL

-- 本地变量定义
local byte                              = string.byte
local insert                            = table.insert
local ipairs                            = ipairs
local len                               = string.len
local pairs                             = pairs
local sort                              = table.sort
local sub                               = string.sub

-- 代码部分

--[[
摘要：轮转输出技能图标、来源颜色和技能名称 UTF 编码。

描述：
模块直接收集冷却管理器 Essential、Utility 分类中的玩家技能，以及打断黑名单中的全部技能。
每 0.5 秒输出一个条目：X=41..42、Y=16..17 的 IconCell 显示技能图标和来源边框颜色，
X=43..58、Y=16 的十六个 Cell 按 DejaVu 规则编码“*#技能名称*#”的前十六个 UTF-8 字符。
玩家技能优先使用 overrideSpellID；不同来源中的相同 spellID 分别保留为独立轮转条目。

主要变量信息：
- rotationEntries：仅保存当前轮转所需的 spellID 与来源颜色，不缓存图标或技能名称。
- currentIndex：当前显示条目在 rotationEntries 中的一基索引。
- utfCells：按从左到右顺序保存十六个 UTF RGB 输出 Cell。

修改记录：
- 2026-08-01：根据本次 UTF 输出需求新增模块，并移除对 BadgeTitleTable 的依赖。
- 2026-08-01：根据实现审计将技能去重限制在各自的直接来源内。
]]

local ICON_POSITION_X = 41
local ICON_POSITION_Y = 16
local UTF_FIRST_POSITION_X = 43
local UTF_POSITION_Y = 16
local UTF_CELL_COUNT = 16
local ROTATE_SECONDS = 0.5
local interruptBlacklist = Config("interrupt_blacklist")

local function splitUTF8Characters(text)
    local characters = {}
    local index = 1
    local textLength = len(text)

    while index <= textLength do
        local currentByte = byte(text, index)
        local characterLength = 1
        if currentByte >= 240 then
            characterLength = 4
        elseif currentByte >= 224 then
            characterLength = 3
        elseif currentByte >= 192 then
            characterLength = 2
        end

        insert(characters, sub(text, index, index + characterLength - 1))
        index = index + characterLength
    end

    return characters
end

local function collectSortedBlacklistIDs(tableValue)
    local spellIDs = {}
    for spellID, enabled in pairs(tableValue or {}) do
        if enabled then
            RequestLoadSpellData(spellID)
            insert(spellIDs, spellID)
        end
    end
    sort(spellIDs)
    return spellIDs
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local iconCell = IconCell:New(ICON_POSITION_X, ICON_POSITION_Y)
    local utfCells = {}
    for index = 1, UTF_CELL_COUNT do
        utfCells[index] = Cell:New({
            x = UTF_FIRST_POSITION_X + index - 1,
            y = UTF_POSITION_Y,
            classification = 0,
            index = 0,
            default_value = 0,
        })
    end

    local rotationEntries = {}
    local currentIndex = 0

    local function clearOutput()
        iconCell.Icon:SetTexture(nil)
        iconCell.Icon:Hide()
        iconCell.Border:Hide()
        for index = 1, UTF_CELL_COUNT do
            utfCells[index]:clearCell()
        end
    end

    local function renderTitle(title)
        local characters = splitUTF8Characters("*#" .. (title or "") .. "*#")
        for index = 1, UTF_CELL_COUNT do
            local character = characters[index]
            if character then
                local red, green, blue = byte(character, 1, 3)
                utfCells[index]:setCellRGBA((red or 0) / 255, (green or 0) / 255, (blue or 0) / 255)
            else
                utfCells[index]:clearCell()
            end
        end
    end

    local function appendCooldownCategory(category, seenSpellIDs)
        local cooldownIDs = GetCooldownViewerCategorySet(category, true)
        for _, cooldownID in ipairs(cooldownIDs) do
            local cooldownInfo = GetCooldownViewerCooldownInfo(cooldownID)
            if cooldownInfo then
                local spellID = cooldownInfo.overrideSpellID or cooldownInfo.spellID
                if spellID and not seenSpellIDs[spellID] then
                    seenSpellIDs[spellID] = true
                    insert(rotationEntries, {
                        spellID = spellID,
                        color = PLAYER_SPELL_COLOR,
                    })
                end
            end
        end
    end

    local function rebuildEntries()
        rotationEntries = {}
        appendCooldownCategory(ESSENTIAL_CATEGORY, {})
        appendCooldownCategory(UTILITY_CATEGORY, {})

        local blacklistIDs = collectSortedBlacklistIDs(interruptBlacklist:get_value())
        for _, spellID in ipairs(blacklistIDs) do
            insert(rotationEntries, {
                spellID = spellID,
                color = ENEMY_SPELL_INTERRUPTIBLE_COLOR,
            })
        end

        currentIndex = 0
    end

    local function renderNextEntry()
        local entryCount = #rotationEntries
        if entryCount == 0 then
            clearOutput()
            return
        end

        currentIndex = currentIndex + 1
        if currentIndex > entryCount then
            currentIndex = 1
        end

        local entry = rotationEntries[currentIndex]
        iconCell:SetIcon(GetSpellTexture(entry.spellID))
        iconCell:SetBorderColor(entry.color)
        renderTitle(GetSpellName(entry.spellID))
    end

    local function refreshEntries()
        rebuildEntries()
        renderNextEntry()
    end

    interruptBlacklist:register_callback(refreshEntries)
    eventFrame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
    eventFrame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
    eventFrame:RegisterEvent("COOLDOWN_VIEWER_TABLE_HOTFIXED")
    eventFrame:SetScript("OnEvent", refreshEntries)

    refreshEntries()

    local rotateElapsed = 0
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        rotateElapsed = rotateElapsed + elapsed
        while rotateElapsed >= ROTATE_SECONDS do
            rotateElapsed = rotateElapsed - ROTATE_SECONDS
            renderNextEntry()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
