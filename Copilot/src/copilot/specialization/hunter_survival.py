# 摘要：生存猎人专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/hunter_survival.lua 的 SpellList 字段。表 key 统一为整数 1..n。
# 上游 ChargeList 为空表，PlayerBuff 与 TargetDebuff 为空表未设，PartyHots/PartyBuff/无用字段未定义，
# 沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：15 项；index 1 为公共冷却。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/hunter_survival.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class HunterSurvival(SpecTemplate):
    spec_name = "生存猎人"
    spec_base = "HUNTER"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 53480, "description": "牺牲咆哮"},
            3: {"spellId": 109304, "description": "意气风发"},
            4: {"spellId": 19577, "description": "胁迫"},
            5: {"spellId": 5116, "description": "震荡射击"},
            6: {"spellId": 19801, "description": "宁神射击"},
            7: {"spellId": 187698, "description": "焦油陷进"},
            8: {"spellId": 1513, "description": "恐吓野兽"},
            9: {"spellId": 109248, "description": "束缚射击"},
            10: {"spellId": 195645, "description": "摔绊"},
            11: {"spellId": 1261193, "description": "爆裂火铳"},
            12: {"spellId": 1250646, "description": "狩魂一击"},
            13: {"spellId": 190925, "description": "鱼叉猛刺"},
            14: {"spellId": 186270, "description": "猛禽一击"},
            15: {"spellId": 259495, "description": "野火炸弹"},
        }