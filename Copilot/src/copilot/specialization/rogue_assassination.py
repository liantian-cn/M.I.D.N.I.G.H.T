# 摘要：刺杀潜行者专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/rogue_assassination.lua 的 SpellList 字段。表 key 统一为整数 1..n。
# 上游 ChargeList 为空表，PlayerBuff 与 TargetDebuff 为空表未设，PartyHots/PartyBuff/无用字段未定义，
# 沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：21 项；index 1 为公共冷却。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/rogue_assassination.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class RogueAssassination(SpecTemplate):
    spec_name = "刺杀潜行者"
    spec_base = "ROGUE"
    spec_id = 1

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 5938, "description": "毒刃"},
            3: {"spellId": 2094, "description": "致盲"},
            4: {"spellId": 1966, "description": "佯攻"},
            5: {"spellId": 1856, "description": "消失"},
            6: {"spellId": 1833, "description": "偷袭"},
            7: {"spellId": 114018, "description": "潜伏帷幕"},
            8: {"spellId": 381623, "description": "菊花茶"},
            9: {"spellId": 5277, "description": "闪避"},
            10: {"spellId": 185311, "description": "猩红之瓶"},
            11: {"spellId": 1725, "description": "扰乱"},
            12: {"spellId": 2983, "description": "疾跑"},
            13: {"spellId": 1776, "description": "凿击"},
            14: {"spellId": 408, "description": "肾击"},
            15: {"spellId": 31224, "description": "暗影斗篷"},
            16: {"spellId": 1766, "description": "脚踢"},
            17: {"spellId": 360194, "description": "死亡印记"},
            18: {"spellId": 1293340, "description": "死亡印记"},
            19: {"spellId": 703, "description": "锁喉"},
            20: {"spellId": 385627, "description": "君王之灾"},
            21: {"spellId": 36554, "description": "暗影步"},
        }