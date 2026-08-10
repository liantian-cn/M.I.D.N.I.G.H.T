# 摘要：邪恶死亡骑士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/deathknight_unholy.lua 的 SpellList、ChargeList、PlayerBuff、TargetDebuff 字段。
# 表 key 统一为整数 1..n。ChargeList 含腐化与枯萎凋零两项充能项，TargetDebuff 上游为空表。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：11 项；index 8 腐化、index 11 枯萎凋零具备 charge。
# charge_list：腐化 maxValue=3、枯萎凋零 maxValue=2。
# player_buff：9 项玩家增益 Aura 白名单。
# target_debuff：上游为空表，沿用空 dict。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/deathknight_unholy.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DeathknightUnholy(SpecTemplate):
    spec_name = "邪恶死亡骑士"
    spec_base = "DEATHKNIGHT"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 49576, "description": "死亡之握"},
            3: {"spellId": 51052, "description": "反魔法领域"},
            4: {"spellId": 221562, "description": "窒息"},
            5: {"spellId": 207167, "description": "致盲冰雨"},
            6: {"spellId": 46584, "description": "亡者复生"},
            7: {"spellId": 42650, "description": "亡者大军"},
            8: {"spellId": 1247378, "description": "腐化", "charge": True},
            9: {"spellId": 1233448, "description": "黑暗突变"},
            10: {"spellId": 343294, "description": "灵魂收割"},
            11: {"spellId": 43265, "description": "枯萎凋零", "charge": True},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 1247378, "description": "腐化", "minValue": 0, "maxValue": 3},
            2: {"spellId": 43265, "description": "枯萎凋零", "minValue": 0, "maxValue": 2},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "次级食尸鬼", "spellIDs": [1254252]},
            2: {"description": "割魂索命", "spellIDs": [1242654]},
            3: {"description": "末日突降", "spellIDs": [81340]},
            4: {"description": "黑暗援助", "spellIDs": [101568]},
            5: {"description": "禁断知识", "spellIDs": [1242223]},
            6: {"description": "脓疮毒镰", "spellIDs": [458123]},
            7: {"description": "亡者指挥官", "spellIDs": [390260]},
            8: {"description": "暗影之爪", "spellIDs": [1241569]},
            9: {"description": "凋萎", "spellIDs": [1271199]},
        }
        self.target_debuff = {  # 等效lua的addonTable.SPEC.TargetDebuff

        }