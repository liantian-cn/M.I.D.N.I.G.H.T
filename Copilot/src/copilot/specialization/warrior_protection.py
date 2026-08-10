# 摘要：防护战士专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/warrior_protection.lua 的 SpellList、ChargeList、PlayerBuff、PartyBuff 字段。表 key 统一为
# 整数 1..n。上游 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：16 项；index 11 盾牌格挡具备 charge。
# charge_list：盾牌格挡 maxValue=8（上游为 Phantom 0..8 fallback）。
# player_buff：盾牌格挡玩家增益。
# party_buff：战斗怒吼单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/warrior_protection.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class WarriorProtection(SpecTemplate):
    spec_name = "防护战士"
    spec_base = "WARRIOR"
    spec_id = 3

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
            11: {"spellId": 2565, "description": "盾牌格挡", "charge": True},
            12: {"spellId": 385952, "description": "盾牌冲锋"},
            13: {"spellId": 107574, "description": "天神下凡"},
            14: {"spellId": 1160, "description": "挫志怒吼"},
            15: {"spellId": 6552, "description": "拳击"},
            16: {"spellId": 190456, "description": "无视苦痛"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 2565, "description": "盾牌格挡", "minValue": 0, "maxValue": 8},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "盾牌格挡", "spellIDs": [132404]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "战斗怒吼",
            "spellIDs": [6673],
        }