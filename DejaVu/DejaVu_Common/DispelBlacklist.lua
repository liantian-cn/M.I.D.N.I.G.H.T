local addonName, addonTable = ...

local pairs = pairs
local insert = table.insert -- 表插入
local Enum = Enum
local After = C_Timer.After
local random = math.random

-- WoW 官方 API
local GetSpellTexture = C_Spell.GetSpellTexture

-- DejaVu Core
local DejaVu = _G["DejaVu"]
local Config = DejaVu.Config
local ConfigRows = DejaVu.ConfigRows
local COLOR = DejaVu.COLOR
local BadgeCell = DejaVu.BadgeCell


-- 创建配置对象
local dispel_blacklist = Config("dispel_blacklist") -- 驱散黑名单配置项
local MAX_COUNT = 10                                -- 最大数量
local POS_X = 64                                    -- X轴位置
local POS_Y = 15                                    -- Y轴位置
local BADGE_COLOR = COLOR.SPELL_TYPE.MAGIC          -- 图标颜色


table.insert(ConfigRows, {
    type = "spell_list", -- 设置类型
    key = "dispel_blacklist", -- 行标识
    name = "驱散黑名单", -- 标题文本
    tooltip = "不可以自动驱散的减益效果列表。", -- 提示信息
    default_value = { -- 默认技能集合
        [1284627] = true, -- 魔导师平台  幽影裂片
    }, -- default_value 结束
    bind_config = dispel_blacklist -- 绑定的配置对象
})



After(2, function()                 -- 2 秒后执行，确保 DejaVu 核心已加载完成
    local cells = {}
    for i = 1, MAX_COUNT do         -- 预创建固定数量的槽位
        local x = POS_X - 2 + 2 * i -- 计算当前槽位 x 坐标
        local y = POS_Y             -- 当前槽位 y 坐标
        local icon = BadgeCell:New(x, y)
        insert(cells, icon)
    end

    local function updateCell(tableValue)
        local i = 1
        for spellID in pairs(tableValue) do
            if i > MAX_COUNT then
                break
            end
            local cell = cells[i]
            cell:setCell(GetSpellTexture(spellID), BADGE_COLOR)

            i = i + 1
        end

        for j = i, MAX_COUNT do
            local cell = cells[j]
            cell:clearCell()
        end
    end
    updateCell(dispel_blacklist:get_value())
    dispel_blacklist:register_callback(updateCell)
end)
