# 摘要：守护德鲁伊专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/druid_guardian.lua 的 SpellList、ChargeList、PlayerBuff、PartyBuff 字段。
# 表 key 统一为整数 1..n。上游 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：14 项；index 7 狂暴回复具备 charge。
# charge_list：狂暴回复 maxValue=8（上游为 Phantom 0..8 fallback）。
# player_buff：5 项玩家增益 Aura 白名单。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/druid_guardian.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DruidGuardian(SpecTemplate):
    spec_name = "守护德鲁伊"
    spec_base = "DRUID"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 22812, "description": "树皮术"},
            3: {"spellId": 132469, "description": "台风"},
            4: {"spellId": 99, "description": "夺魂咆哮"},
            5: {"spellId": 29166, "description": "激活"},
            6: {"spellId": 102793, "description": "乌索尔旋风"},
            7: {"spellId": 22842, "description": "狂暴回复", "charge": True},
            8: {"spellId": 61336, "description": "生存本能"},
            9: {"spellId": 102558, "description": "化身：乌索克的守护者"},
            10: {"spellId": 1261867, "description": "野性之心"},
            11: {"spellId": 1253799, "description": "碎甲咆哮"},
            12: {"spellId": 1252871, "description": "赤红之月"},
            13: {"spellId": 6807, "description": "重殴"},
            14: {"spellId": 77758, "description": "痛击"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 22842, "description": "狂暴回复", "minValue": 0, "maxValue": 8},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "塞纳留斯的梦境", "spellIDs": [372152]},
            2: {"description": "铁鬃", "spellIDs": [192081]},
            3: {"description": "狂暴回复", "spellIDs": [22842]},
            4: {"description": "星河守护者", "spellIDs": [213708]},
            5: {"description": "淤血", "spellIDs": [93622]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "野性印记",
            "spellIDs": [1126, 432661],
        }