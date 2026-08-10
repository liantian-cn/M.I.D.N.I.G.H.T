-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame                      = CreateFrame
local GetSpellTexture                  = C_Spell.GetSpellTexture
local RequestLoadSpellData             = C_Spell.RequestLoadSpellData

-- 插件级变量定义/引用
local Config                           = addonTable.Config
local ConfigRows                       = addonTable.ConfigRows
local IconCell                         = addonTable.IconCell
local ENEMY_SPELL_INTERRUPTIBLE_COLOR  = addonTable.COLOR.ENEMY_SPELL_INTERRUPTIBLE

-- 本地变量定义
local insert          = table.insert
local pairs           = pairs
local sort            = table.sort

-- 代码部分

--[[
摘要：维护打断技能黑名单设置并输出其技能图标。

描述：
模块注册与 DejaVu 相同默认值的“打断黑名单”技能列表设置，并在矩阵 X=1..20、Y=16..17
创建十个连续 IconCell。配置变化时按 spellID 升序刷新，专用区域最多显示前十项；完整配置仍由
UTF 模块读取。每个可见图标的边框始终使用可打断技能颜色。

主要变量信息：
- interruptBlacklist：保存当前配置档案中打断黑名单集合的 Config 对象。
- iconCells：按从左到右顺序保存十个固定 IconCell。
- DEFAULT_SPELLS：与 DejaVu 相同的六个默认黑名单技能 ID。

修改记录：
- 2026-08-01：根据本次打断技能黑名单需求新增模块。
- 2026-08-01：根据实现审计补充异步法术数据加载完成后的图标刷新。
]]

local CONFIG_KEY = "interrupt_blacklist"
local MAX_ICON_COUNT = 10
local FIRST_ICON_POSITION_X = 1
local ICON_POSITION_Y = 16
local DEFAULT_SPELLS = {
    [1254669] = true,
    [1258436] = true,
    [1248327] = true,
    [1262510] = true,
    [468962] = true,
    [1262526] = true,
}

local interruptBlacklist = Config(CONFIG_KEY)
interruptBlacklist:set_default(DEFAULT_SPELLS)

insert(ConfigRows, {
    type = "spell_list",
    key = CONFIG_KEY,
    name = "打断黑名单",
    tooltip = "不可以自动打断的技能列表。",
    default_value = DEFAULT_SPELLS,
    bind_config = interruptBlacklist,
})

local function collectSortedSpellIDs(tableValue)
    local spellIDs = {}
    for spellID, enabled in pairs(tableValue or {}) do
        if enabled then
            insert(spellIDs, spellID)
        end
    end
    sort(spellIDs)
    return spellIDs
end

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local iconCells = {}
    for index = 1, MAX_ICON_COUNT do
        local x = FIRST_ICON_POSITION_X + (index - 1) * 2
        iconCells[index] = IconCell:New(x, ICON_POSITION_Y)
    end

    local function clearIcon(iconCell)
        iconCell.Icon:SetTexture(nil)
        iconCell.Icon:Hide()
        iconCell.Border:Hide()
    end

    local function updateIcons(tableValue)
        local spellIDs = collectSortedSpellIDs(tableValue)

        for index = 1, MAX_ICON_COUNT do
            local iconCell = iconCells[index]
            local spellID = spellIDs[index]
            if spellID then
                iconCell:SetIcon(GetSpellTexture(spellID))
                iconCell:SetBorderColor(ENEMY_SPELL_INTERRUPTIBLE_COLOR)
            else
                clearIcon(iconCell)
            end
        end
    end

    local function requestSpellData(tableValue)
        local spellIDs = collectSortedSpellIDs(tableValue)
        for index = 1, #spellIDs do
            RequestLoadSpellData(spellIDs[index])
        end
    end

    local function refreshIcons(tableValue)
        requestSpellData(tableValue)
        updateIcons(tableValue)
    end

    eventFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
    eventFrame:SetScript("OnEvent", function(self, event, spellID, success)
        local tableValue = interruptBlacklist:get_value() or {}
        if success and tableValue[spellID] then
            updateIcons(tableValue)
        end
    end)

    interruptBlacklist:register_callback(refreshIcons)
    refreshIcons(interruptBlacklist:get_value())
end

insert(addonTable.FrameInitFuncs, InitFrame)
