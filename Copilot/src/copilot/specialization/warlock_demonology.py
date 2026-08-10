# 摘要：恶魔术士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/warlock_demonology.lua 的 SpellList 字段。表 key 统一为整数 1..n。
# 上游 ChargeList 为空表，PlayerBuff 与 TargetDebuff 为空表未设，PartyHots/PartyBuff/无用字段未定义，
# 沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：22 项；index 1 为公共冷却。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/warlock_demonology.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class WarlockDemonology(SpecTemplate):
    spec_name = "恶魔术士"
    spec_base = "WARLOCK"
    spec_id = 2

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 5782, "description": "恐惧"},
            3: {"spellId": 6789, "description": "死亡缠绕"},
            4: {"spellId": 20707, "description": "灵魂石"},
            5: {"spellId": 30283, "description": "暗影之怒"},
            6: {"spellId": 333889, "description": "邪能统御"},
            7: {"spellId": 108416, "description": "黑暗契约"},
            8: {"spellId": 111771, "description": "恶魔传送门"},
            9: {"spellId": 127174, "description": "虚弱灾厄"},
            10: {"spellId": 1271802, "description": "语言灾厄"},
            11: {"spellId": 48018, "description": "恶魔法阵"},
            12: {"spellId": 48020, "description": "恶魔法阵：传送"},
            13: {"spellId": 196277, "description": "内爆"},
            14: {"spellId": 265187, "description": "召唤恶魔暴君"},
            15: {"spellId": 1276467, "description": "魔典：邪能破坏者"},
            16: {"spellId": 105174, "description": "古尔丹之手"},
            17: {"spellId": 1276672, "description": "召唤末日守卫"},
            18: {"spellId": 104316, "description": "召唤恐惧猎犬"},
            19: {"spellId": 264187, "description": "恶魔之箭"},
            20: {"spellId": 1276452, "description": "魔典：小鬼领主"},
            21: {"spellId": 388215, "description": "吞噬魔法"},
            22: {"spellId": 30146, "description": "召唤恶魔卫士"},
        }