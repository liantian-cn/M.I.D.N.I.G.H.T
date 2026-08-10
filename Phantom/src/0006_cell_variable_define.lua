-- 命名空间声明
local addonName, addonTable = ...

-- WOW API 缓存

-- 插件级变量定义/引用

-- 本地变量定义

-- 代码部分

--[[
摘要：定义矩阵 Cell 使用的全部分类编号。

描述：
分类写入 Cell 的 R 通道，用于让外部解码器区分玩家、目标、Aura、环境以及队伍成员数据。
PARTY_* 分类由小队和团队输出共享，依次覆盖十项成员状态与五个 HOT 槽位，编号从 100 到 170 每项递增 5。

主要变量信息：
CELL_CLASSIFICATION：分类名称到 R 通道整数值的固定映射。

修改记录：
2026-07-26：根据小队模块需求补充 PARTY_EXIST 至 PARTY_HOT5 分类。
2026-07-30：根据团队属性需求说明 PARTY_* 分类由小队和团队输出共享，分类名称和值保持不变。
]]

-- 说明
-- 每个cell的RGB值分别有不同的涵义
-- R: 分类（根据cell用途不同，每个cell有个分类设置，范围0-255）
-- G: 索引（相同分类的cell，每个cell有个索引设置，范围0-255），代表同一个分类下的不同cell。
-- B: Value（根据cell用途不同，每个cell有个value设置，范围0-255），由解码器解析。

-- 以上逻辑确保了，即便无法准确定位像素的坐标，也能通过RGB值来传输数据，解码器可以根据RGB值来解析出cell的分类、索引和value，从而实现数据的传输和解析。


local CELL_CLASSIFICATION = {
    MARKER = 255,                -- 标记分类，用于定位的Cell，index表示处于第几行，value=0代表左侧开始，value=255代表右侧结束。
    PLAYER_STATUS = 5,           -- 玩家状态分类，index代表第几个，value各不相同。
    TARGET_STATUS = 10,          -- 目标状态分类，index代表第几个，value各不相同。
    FOCUS_TARGET = 15,           -- 焦点目标分类，index代表第几个，value各不相同。
    PLAYER_BUFF_DURATION = 20,   -- 玩家Buff分类，index代表第几个，value各不相同。
    PLAYER_BUFF_COUNT = 25,      -- 玩家Buff分类，index代表第几个，value各不相同。
    TARGET_DEBUFF_DURATION = 30, -- 目标Debuff分类，index代表第几个，value各不相同。
    TARGET_DEBUFF_COUNT = 35,    -- 目标Debuff分类，index代表第几个，value各不相同。
    PLAYER_DEBUFF_DURATION = 40, -- 玩家Debuff分类，index代表第几个，value各不相同。
    PLAYER_DEBUFF_COUNT = 45,    -- 玩家Debuff分类，index代表第几个，value各不相同。

    ENVIRONMENT = 50,            -- 环境分类，index代表第几个，value各不相同。
    SPEC = 55,                   -- 特殊分类，index代表第几个，value各不相同。
    SETTING = 60,                -- 设置分类，index代表第几个，value各不相同。
    SPELL_COOLDOWN = 65,         -- 技能冷却分类，index代表第几个，value各不相同。
    SPELL_USABLE = 70,           -- 技能可用分类，index代表第几个，value各不相同。
    SPELL_OVERLAYED = 75,        -- 技能高亮分类，index代表第几个，value各不相同。
    SPELL_KNOWN = 80,            -- 技能已知分类，index代表第几个，value各不相同。
    SPELL_CHARGE = 85,           -- 技能充能分类，index代表第几个，value各不相同。

    PARTY_EXIST = 100,            -- 小队和团队成员存在状态。
    PARTY_TARGET = 105,           -- 小队和团队成员当前目标状态。
    PARTY_ROLE = 110,             -- 小队和团队成员职责。
    PARTY_RANGE = 115,            -- 小队和团队成员距离状态。
    PARTY_HEALTH = 120,           -- 小队和团队成员生命百分比。
    PARTY_DAMAGE_ABSORB = 125,    -- 小队和团队成员伤害吸收状态。
    PARTY_HEAL_ABSORB = 130,      -- 小队成员治疗吸收状态。
    PARTY_BUFF = 135,             -- 小队成员配置增益状态。
    PARTY_DISPELLABLE = 140,      -- 小队和团队成员可驱散减益状态。
    PARTY_BIG_DEFENSIVE = 145,    -- 小队成员大型防御状态。
    PARTY_HOT1 = 150,             -- 小队和团队成员第 1 组 HOT。
    PARTY_HOT2 = 155,             -- 小队和团队成员第 2 组 HOT。
    PARTY_HOT3 = 160,             -- 小队和团队成员第 3 组 HOT。
    PARTY_HOT4 = 165,             -- 小队和团队成员第 4 组 HOT。
    PARTY_HOT5 = 170,             -- 小队和团队成员第 5 组 HOT。
}
addonTable.CELL_CLASSIFICATION = CELL_CLASSIFICATION
