--[[
文件定位：




状态：
  draft
]]
local addonName, addonTable = ...
addonTable.COLOR = {
    RED = CreateColor(255 / 255, 0, 0, 1),                                          -- 红色
    GREEN = CreateColor(0, 255 / 255, 0, 1),                                        -- 绿色
    BLUE = CreateColor(0, 0, 255 / 255, 1),                                         -- 蓝色
    BLACK = CreateColor(0, 0, 0, 1),                                                -- 黑色
    WHITE = CreateColor(1, 1, 1, 1),                                                -- 白色
    TRANSPARENT = CreateColor(0, 0, 0, 0),                                          -- 透明
    SPELL_TYPE = {                                                                  -- 技能类型颜色表
        MAGIC = CreateColor(60 / 255, 100 / 255, 220 / 255, 1),                     -- 魔法
        CURSE = CreateColor(100 / 255, 0, 120 / 255, 1),                            -- 诅咒
        DISEASE = CreateColor(160 / 255, 120 / 255, 60 / 255, 1),                   -- 疾病
        POISON = CreateColor(154 / 255, 205 / 255, 50 / 255, 1),                    -- 中毒
        ENRAGE = CreateColor(230 / 255, 120 / 255, 20 / 255, 1),                    -- 激怒
        BLEED = CreateColor(80 / 255, 0, 20 / 255, 1),                              -- 流血
        PLAYER_DEBUFF = CreateColor(255 / 255, 60 / 255, 60 / 255, 1),              -- 无分类减益
        PLAYER_BUFF = CreateColor(80 / 255, 220 / 255, 120 / 255, 1),               -- 友方增益
        PLAYER_SPELL = CreateColor(64 / 255, 158 / 255, 210 / 255, 1),              -- 友方施法
        ENEMY_SPELL_INTERRUPTIBLE = CreateColor(255 / 255, 255 / 255, 60 / 255, 1), -- 可打断
        ENEMY_SPELL_NOT_INTERRUPTIBLE = CreateColor(200 / 255, 0, 0, 1),            -- 不可打断
        ENEMY_DEBUFF = CreateColor(105 / 255, 105 / 255, 210 / 255, 1),             -- 敌方减益
        NONE = CreateColor(0, 0, 0, 0),                                             -- 无
    },
    MARK_POINT = {                                                                  -- 标记点颜色表
        NEAR_BLACK_1 = CreateColor(15 / 255, 25 / 255, 20 / 255, 1),                -- 接近黑色
        NEAR_BLACK_2 = CreateColor(25 / 255, 15 / 255, 20 / 255, 1),                -- 接近黑色
    },
    C0 = CreateColor(0, 0, 0, 1),                                                   -- 黑色
    C100 = CreateColor(100 / 255, 100 / 255, 100 / 255, 1),                         -- 灰色
    C150 = CreateColor(150 / 255, 150 / 255, 150 / 255, 1),
    C200 = CreateColor(200 / 255, 200 / 255, 200 / 255, 1),
    C250 = CreateColor(250 / 255, 250 / 255, 250 / 255, 1),
    C255 = CreateColor(255 / 255, 255 / 255, 255 / 255, 1),
    ROLE = {                                                           -- 角色颜色表
        TANK = CreateColor(180 / 255, 80 / 255, 20 / 255, 1),          -- 坦克
        HEALER = CreateColor(120 / 255, 200 / 255, 255 / 255, 1),      -- 治疗
        DAMAGER = CreateColor(230 / 255, 200 / 255, 50 / 255, 1),      -- 伤害输出
        NONE = CreateColor(0, 0, 0, 1),                                -- 无角色
    },
    CLASS = {                                                          -- 职业颜色表
        WARRIOR = CreateColor(199 / 255, 86 / 255, 36 / 255, 1),       -- 战士
        PALADIN = CreateColor(245 / 255, 140 / 255, 186 / 255, 1),     -- 圣骑士
        HUNTER = CreateColor(163 / 255, 203 / 255, 66 / 255, 1),       -- 猎人
        ROGUE = CreateColor(255 / 255, 245 / 255, 105 / 255, 1),       -- 潜行者
        PRIEST = CreateColor(196 / 255, 207 / 255, 207 / 255, 1),      -- 牧师
        DEATHKNIGHT = CreateColor(125 / 255, 125 / 255, 215 / 255, 1), -- 死亡骑士
        SHAMAN = CreateColor(64 / 255, 148 / 255, 255 / 255, 1),       -- 萨满祭司
        MAGE = CreateColor(64 / 255, 158 / 255, 210 / 255, 1),         -- 法师
        WARLOCK = CreateColor(105 / 255, 105 / 255, 210 / 255, 1),     -- 术士
        MONK = CreateColor(0 / 255, 255 / 255, 150 / 255, 1),          -- 武僧
        DRUID = CreateColor(255 / 255, 125 / 255, 10 / 255, 1),        -- 德鲁伊
        DEMONHUNTER = CreateColor(163 / 255, 48 / 255, 201 / 255, 1),  -- 恶魔猎手
        EVOKER = CreateColor(108 / 255, 191 / 255, 246 / 255, 1)       -- 唤魔师
    }
}
