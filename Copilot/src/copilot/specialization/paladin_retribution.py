# 摘要：惩戒圣骑士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/paladin_retribution.lua 的 SpellList、ChargeList、PlayerBuff、PartyBuff 字段。表 key 统一为
# 整数 1..n。上游 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：15 项；index 10 审判具备 charge。
# charge_list：审判 maxValue=8（上游为 Phantom 0..8 fallback）。
# player_buff：3 项玩家增益，含组合 spellIDs。
# party_buff：虔诚光环单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/paladin_retribution.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class PaladinRetribution(SpecTemplate):
    spec_name = "惩戒圣骑士"
    spec_base = "PALADIN"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 115750, "description": "盲目之光"},
            3: {"spellId": 853, "description": "制裁之锤"},
            4: {"spellId": 642, "description": "圣盾术"},
            5: {"spellId": 6940, "description": "牺牲祝福"},
            6: {"spellId": 1044, "description": "自由祝福"},
            7: {"spellId": 1022, "description": "保护祝福"},
            8: {"spellId": 633, "description": "圣疗术"},
            9: {"spellId": 213644, "description": "清毒术"},
            10: {"spellId": 20271, "description": "审判", "charge": True},
            11: {"spellId": 375576, "description": "圣洁鸣钟"},
            12: {"spellId": 184575, "description": "公正之剑"},
            13: {"spellId": 343527, "description": "处决宣判"},
            14: {"spellId": 255937, "description": "灰烬觉醒"},
            15: {"spellId": 31884, "description": "复仇之怒"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 20271, "description": "审判", "minValue": 0, "maxValue": 8},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "神圣意志", "spellIDs": [223819, 408458]},
            2: {"description": "复仇之怒", "spellIDs": [31884]},
            3: {"description": "圣光之锤", "spellIDs": [427441, 1246643]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "虔诚光环",
            "spellIDs": [465],
        }