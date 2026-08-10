# 摘要：野性德鲁伊专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/druid_feral.lua 的 SpellList、PartyBuff 字段。表 key 统一为整数 1..n。
# 上游 ChargeList、PlayerBuff、TargetDebuff 为空表或未设，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：6 项；index 1 为公共冷却。
# party_buff：野性印记单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/druid_feral.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DruidFeral(SpecTemplate):
    spec_name = "野性德鲁伊"
    spec_base = "DRUID"
    spec_id = 2

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
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "野性印记",
            "spellIDs": [1126, 432661],
        }