# 摘要：冰霜法师专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/mage_frost.lua 的 SpellList、PlayerBuff、PartyBuff 字段。表 key 统一为整数 1..n。
# 上游 ChargeList 与 TargetDebuff 为空表未设，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：仅 index 1 为公共冷却。
# player_buff：4 项玩家增益 Aura 白名单。
# party_buff：奥术智慧单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/mage_frost.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class MageFrost(SpecTemplate):
    spec_name = "冰霜法师"
    spec_base = "MAGE"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "热能真空", "spellIDs": [1247730]},
            2: {"description": "冰冷智慧", "spellIDs": [190446]},
            3: {"description": "冰冻之雨", "spellIDs": [270232]},
            4: {"description": "寒冰指", "spellIDs": [44544]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "奥术智慧",
            "spellIDs": [1459, 432778],
        }