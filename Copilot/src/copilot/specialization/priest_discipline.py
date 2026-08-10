# 摘要：戒律牧师专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/priest_discipline.lua 的 SpellList、ChargeList、PlayerBuff、PartyBuff 字段。表 key 统一为
# 整数 1..n。上游 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：17 项；index 7 苦修、index 8 真言术：耀具备 charge。
# charge_list：苦修与真言术：耀两项，maxValue 均为 2。
# player_buff：5 项玩家增益。
# party_buff：真言术：韧单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/priest_discipline.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class PriestDiscipline(SpecTemplate):
    spec_name = "戒律牧师"
    spec_base = "PRIEST"
    spec_id = 1

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 8122, "description": "心灵尖啸"},
            3: {"spellId": 32375, "description": "群体驱散"},
            4: {"spellId": 527, "description": "纯净术"},
            5: {"spellId": 19236, "description": "绝望祷言"},
            6: {"spellId": 232633, "description": "奥术洪流"},
            7: {"spellId": 47540, "description": "苦修", "charge": True},
            8: {"spellId": 194509, "description": "真言术：耀", "charge": True},
            9: {"spellId": 17, "description": "真言术：盾"},
            10: {"spellId": 62618, "description": "真言术：障"},
            11: {"spellId": 421453, "description": "终极苦修"},
            12: {"spellId": 472433, "description": "福音"},
            13: {"spellId": 8092, "description": "心灵震爆"},
            14: {"spellId": 32379, "description": "暗言术：灭"},
            15: {"spellId": 34433, "description": "暗影魔"},
            16: {"spellId": 1235211, "description": "暗影分流"},
            17: {"spellId": 586, "description": "渐隐术"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 47540, "description": "苦修", "minValue": 0, "maxValue": 2},
            2: {"spellId": 194509, "description": "真言术：耀", "minValue": 0, "maxValue": 2},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "虚空之盾", "spellIDs": [1253591]},
            2: {"description": "圣光涌动", "spellIDs": [114255]},
            3: {"description": "暗影愈合", "spellIDs": [1252217]},
            4: {"description": "福音", "spellIDs": [472433]},
            5: {"description": "祸福相依", "spellIDs": [390787]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "真言术：韧",
            "spellIDs": [21562],
        }