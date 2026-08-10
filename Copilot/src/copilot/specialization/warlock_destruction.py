# 摘要：毁灭术士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/warlock_destruction.lua 的 SpellList、ChargeList 字段。表 key 统一为整数 1..n。
# 上游 PlayerBuff 与 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：15 项；index 15 燃烧具备 charge。
# charge_list：燃烧 maxValue=8（上游为 Phantom 0..8 fallback）。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/warlock_destruction.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class WarlockDestruction(SpecTemplate):
    spec_name = "毁灭术士"
    spec_base = "WARLOCK"
    spec_id = 3

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
            13: {"spellId": 1122, "description": "召唤地狱火"},
            14: {"spellId": 6353, "description": "灵魂之火"},
            15: {"spellId": 17962, "description": "燃烧", "charge": True},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 17962, "description": "燃烧", "minValue": 0, "maxValue": 8},
        }