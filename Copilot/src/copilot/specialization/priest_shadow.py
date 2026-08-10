# 摘要：暗影牧师专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/priest_shadow.lua 的 SpellList、PartyBuff 字段。表 key 统一为整数 1..n。
# 上游 ChargeList 与 TargetDebuff 为空表或未设，PlayerBuff 上游为空表，PartyHots/无用字段未定义，
# 沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：14 项；index 1 为公共冷却。
# party_buff：真言术：韧单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/priest_shadow.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class PriestShadow(SpecTemplate):
    spec_name = "暗影牧师"
    spec_base = "PRIEST"
    spec_id = 3

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
            7: {"spellId": 8092, "description": "心灵震爆"},
            8: {"spellId": 32379, "description": "暗言术：灭"},
            9: {"spellId": 263165, "description": "虚空洪流"},
            10: {"spellId": 228260, "description": "虚空形态"},
            11: {"spellId": 1227280, "description": "触须猛击"},
            12: {"spellId": 15286, "description": "吸血鬼的拥抱"},
            13: {"spellId": 120644, "description": "光晕"},
            14: {"spellId": 1242173, "description": "虚空齐射"},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "真言术：韧",
            "spellIDs": [21562],
        }