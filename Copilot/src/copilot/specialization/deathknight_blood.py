# 摘要：鲜血死亡骑士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/deathknight_blood.lua 的 SpellList、ChargeList、PlayerBuff、TargetDebuff
# 字段，并迁移上游 addonTable.RANGED_SEPLL 与 MELEE_SEPLL 通用 spellId（计划中在 Copilot 无用，但仍按
# 上游存在定义迁移）。表 key 统一为整数 1..n。PartyBuff 等本专精上游未定义的字段沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：12 项技能冷却表；index 1 为公共冷却。
# charge_list：上游为空表，沿用空 dict。
# player_buff：白骨之盾、枯萎凋零两项，含 maxApplications。
# target_debuff：血之疫病、死神印记两项，含 maxApplications。
# ranged_spell：195292 远程通用 spellId。
# melee_spell：195182 近战通用 spellId。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步并迁移 RANGED/MELEE_SEPLL，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/deathknight_blood.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DeathknightBlood(SpecTemplate):
    spec_name = "鲜血死亡骑士"
    spec_base = "DEATHKNIGHT"
    spec_id = 1

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 49576, "description": "死亡之握"},
            3: {"spellId": 51052, "description": "反魔法领域"},
            4: {"spellId": 221562, "description": "窒息"},
            5: {"spellId": 207167, "description": "致盲冰雨"},
            6: {"spellId": 46585, "description": "亡者复生"},
            7: {"spellId": 55233, "description": "吸血鬼之血"},
            8: {"spellId": 48792, "description": "冰封之韧"},
            9: {"spellId": 49039, "description": "巫妖之躯"},
            10: {"spellId": 108199, "description": "血魔之握"},
            11: {"spellId": 1263569, "description": "憎恶附肢"},
            12: {"spellId": 50, "description": "吞噬"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList

        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "白骨之盾", "spellIDs": [195181], "maxApplications": 12},
            2: {"description": "枯萎凋零", "spellIDs": [188290], "maxApplications": 1},
        }
        self.target_debuff = {  # 等效lua的addonTable.SPEC.TargetDebuff
            1: {"description": "血之疫病", "spellIDs": [55078], "maxApplications": 4},
            2: {"description": "死神印记", "spellIDs": [434765], "maxApplications": 40},
        }
        self.ranged_spell = 195292  # 等效lua的addonTable.RANGED_SEPLL,计划中在Copilot中无用.
        self.melee_spell = 195182  # 等效lua的addonTable.MELEE_SEPLL,计划中在Copilot中无用.