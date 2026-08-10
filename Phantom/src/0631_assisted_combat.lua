-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateFrame      = CreateFrame
local GetNextCastSpell = C_AssistedCombat.GetNextCastSpell
local GetSpellTexture  = C_Spell.GetSpellTexture

-- 插件级变量定义/引用
local IconCell           = addonTable.IconCell
local PLAYER_SPELL_COLOR = addonTable.COLOR.PLAYER_SPELL

-- 本地变量定义
local insert           = table.insert

-- 代码部分

--[[
摘要：输出官方一键辅助推荐的下一个技能图标。

描述：
模块在矩阵 X=31..32、Y=5..6 创建一个 IconCell，每 0.1 秒读取一次官方一键辅助推荐技能。
存在推荐技能时直接显示对应纹理，并始终使用玩家技能颜色作为边框；没有推荐技能时隐藏图标和边框。

主要变量信息：
- iconCell：承载当前一键辅助推荐技能的 2x2 图标槽。
- refreshElapsed：累计两次一键辅助查询之间的时间。

修改记录：
- 2026-08-01：根据本次一键辅助功能需求新增模块。
]]

local ICON_POSITION_X = 31
local ICON_POSITION_Y = 5
local REFRESH_SECONDS = 0.1

local function InitFrame()
    local eventFrame = CreateFrame("Frame")
    local iconCell = IconCell:New(ICON_POSITION_X, ICON_POSITION_Y)

    local function clearIcon()
        iconCell.Icon:SetTexture(nil)
        iconCell.Icon:Hide()
        iconCell.Border:Hide()
    end

    local function updateIcon()
        local spellID = GetNextCastSpell(false)
        if spellID == nil then
            clearIcon()
            return
        end

        iconCell:SetIcon(GetSpellTexture(spellID))
        iconCell:SetBorderColor(PLAYER_SPELL_COLOR)
    end

    updateIcon()

    local refreshElapsed = 0
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        refreshElapsed = refreshElapsed + elapsed
        if refreshElapsed >= REFRESH_SECONDS then
            refreshElapsed = refreshElapsed - REFRESH_SECONDS
            updateIcon()
        end
    end)
end

insert(addonTable.FrameInitFuncs, InitFrame)
