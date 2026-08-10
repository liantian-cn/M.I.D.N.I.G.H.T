# 摘要：冰霜死亡骑士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/deathknight_frost.lua 的 SpellList、ChargeList、PlayerBuff、TargetDebuff 字段。
# 表 key 统一为整数 1..n。上游 ChargeList 与 TargetDebuff 中分别为充能项与空表，按定义迁移。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：10 项技能冷却表；index 1 为公共冷却，index 9 符文武器增效具备 charge。
# charge_list：符文武器增效充能项，minValue=0 maxValue=2。
# player_buff：7 项玩家增益 Aura 白名单。
# target_debuff：上游为空表，沿用空 dict。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/deathknight_frost.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DeathknightFrost(SpecTemplate):
    spec_name = "冰霜死亡骑士"
    spec_base = "DEATHKNIGHT"
    spec_id = 2

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 49576, "description": "死亡之握"},
            3: {"spellId": 51052, "description": "反魔法领域"},
            4: {"spellId": 221562, "description": "窒息"},
            5: {"spellId": 207167, "description": "致盲冰雨"},
            6: {"spellId": 51271, "description": "冰霜之柱"},
            7: {"spellId": 279302, "description": "冰霜巨龙之怒"},
            8: {"spellId": 439843, "description": "死神印记"},
            9: {"spellId": 47568, "description": "符文武器增效", "charge": True},
            10: {"spellId": 1249658, "description": "冰龙吐息"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 47568, "description": "符文武器增效", "minValue": 0, "maxValue": 2},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "黑暗援助", "spellIDs": [101568]},
            2: {"description": "杀戮机器", "spellIDs": [51124]},
            3: {"description": "白霜", "spellIDs": [59052]},
            4: {"description": "冰霜灾祸", "spellIDs": [1229310]},
            5: {"description": "冰霜之柱", "spellIDs": [51271]},
            6: {"description": "霜巢之眷", "spellIDs": [1265630]},
            7: {"description": "霜巢之眷-冰霜巨龙之怒", "spellIDs": [1265639]},
        }
        self.target_debuff = {  # 等效lua的addonTable.SPEC.TargetDebuff

        }