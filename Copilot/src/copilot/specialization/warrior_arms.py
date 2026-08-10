# 摘要：武器战士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/warrior_arms.lua 的 SpellList、ChargeList、PartyBuff 字段。表 key 统一为整数 1..n。
# 上游 PlayerBuff 与 TargetDebuff 为空表未设，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：17 项；index 11 压制具备 charge。
# charge_list：压制 maxValue=8（上游为 Phantom 0..8 fallback）。
# party_buff：战斗怒吼单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/warrior_arms.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class WarriorArms(SpecTemplate):
    spec_name = "武器战士"
    spec_base = "WARRIOR"
    spec_id = 1

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 202168, "description": "胜利在望"},
            3: {"spellId": 376079, "description": "勇士之矛"},
            4: {"spellId": 6544, "description": "英勇飞跃"},
            5: {"spellId": 97462, "description": "集结呐喊"},
            6: {"spellId": 46968, "description": "震荡波"},
            7: {"spellId": 107570, "description": "风暴之锤"},
            8: {"spellId": 384110, "description": "破裂投掷"},
            9: {"spellId": 64382, "description": "碎裂投掷"},
            10: {"spellId": 5246, "description": "破胆怒吼"},
            11: {"spellId": 7384, "description": "压制", "charge": True},
            12: {"spellId": 163201, "description": "斩杀"},
            13: {"spellId": 845, "description": "顺劈斩"},
            14: {"spellId": 12294, "description": "致死打击"},
            15: {"spellId": 167105, "description": "巨人打击"},
            16: {"spellId": 436358, "description": "崩摧"},
            17: {"spellId": 6552, "description": "拳击"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 7384, "description": "压制", "minValue": 0, "maxValue": 8},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "战斗怒吼",
            "spellIDs": [6673],
        }