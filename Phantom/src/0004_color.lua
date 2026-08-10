-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存
local CreateColor = CreateColor

-- 插件级变量定义/引用

addonTable.COLOR = {                                                                -- 技能类型颜色表
    MAGIC = CreateColor(60 / 255, 100 / 255, 220 / 255, 1),                         -- 魔法
    CURSE = CreateColor(100 / 255, 0, 120 / 255, 1),                                -- 诅咒
    DISEASE = CreateColor(160 / 255, 120 / 255, 60 / 255, 1),                       -- 疾病
    POISON = CreateColor(154 / 255, 205 / 255, 50 / 255, 1),                        -- 中毒
    ENRAGE = CreateColor(230 / 255, 120 / 255, 20 / 255, 1),                        -- 激怒
    BLEED = CreateColor(80 / 255, 0, 20 / 255, 1),                                  -- 流血
    DEBUFF_ON_FRIENDLY = CreateColor(255 / 255, 60 / 255, 60 / 255, 1),             -- 在友方身上的减益
    BUFF_ON_FRIENDLY = CreateColor(80 / 255, 220 / 255, 120 / 255, 1),              -- 在友方身上的增益
    PLAYER_SPELL = CreateColor(64 / 255, 158 / 255, 210 / 255, 1),                  -- 友方施法
    ENEMY_SPELL_INTERRUPTIBLE = CreateColor(255 / 255, 255 / 255, 60 / 255, 1),     -- 可打断
    ENEMY_SPELL_NOT_INTERRUPTIBLE = CreateColor(200 / 255, 0, 0, 1),                -- 不可打断
    DEBUFF_ON_ENEMY = CreateColor(105 / 255, 105 / 255, 210 / 255, 1),              -- 在敌方身上的减益
    NONE = CreateColor(0, 0, 0, 0),                                                 -- 无

}


-- 本地变量定义

-- 代码部分
