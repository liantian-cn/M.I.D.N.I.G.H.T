# 摘要：织雾武僧专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/monk_mistweaver.lua 的 SpellList、ChargeList、PlayerBuff 字段。表 key 统一为整数 1..n。
# 上游 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：16 项；index 2 雷光聚神茶、index 3 复苏之雾具备 charge。
# charge_list：雷光聚神茶、复苏之雾两项，maxValue 均为 8（上游为 Phantom 0..8 fallback）。
# player_buff：6 项玩家增益 Aura 白名单。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/monk_mistweaver.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class MonkMistweaver(SpecTemplate):
    spec_name = "织雾武僧"
    spec_base = "MONK"
    spec_id = 2

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 116680, "description": "雷光聚神茶", "charge": True},
            3: {"spellId": 115151, "description": "复苏之雾", "charge": True},
            4: {"spellId": 115310, "description": "还魂术"},
            5: {"spellId": 116849, "description": "作茧缚命"},
            6: {"spellId": 115450, "description": "清创生血"},
            7: {"spellId": 443028, "description": "天神御身"},
            8: {"spellId": 322109, "description": "轮回之触"},
            9: {"spellId": 119381, "description": "扫堂腿"},
            10: {"spellId": 1270621, "description": "宁神茶"},
            11: {"spellId": 101643, "description": "魂体双分"},
            12: {"spellId": 119996, "description": "魂体双分：转移"},
            13: {"spellId": 107428, "description": "旭日东升踢"},
            14: {"spellId": 100784, "description": "幻灭踢"},
            15: {"spellId": 116844, "description": "平心之环"},
            16: {"spellId": 115078, "description": "分筋错骨"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 116680, "description": "雷光聚神茶", "minValue": 0, "maxValue": 8},
            2: {"spellId": 115151, "description": "复苏之雾", "minValue": 0, "maxValue": 8},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "生生不息1", "spellIDs": [197919]},
            2: {"description": "生生不息2", "spellIDs": [197916]},
            3: {"description": "灵泉", "spellIDs": [1260565]},
            4: {"description": "玄牛之力", "spellIDs": [443112]},
            5: {"description": "青龙之心", "spellIDs": [443421, 443616]},
            6: {"description": "活力苏醒", "spellIDs": [392883]},
        }