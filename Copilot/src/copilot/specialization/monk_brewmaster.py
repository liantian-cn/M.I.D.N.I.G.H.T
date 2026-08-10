# 摘要：酒仙武僧专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/monk_brewmaster.lua 的 SpellList、ChargeList、PlayerBuff 字段。表 key 统一为整数 1..n。
# 上游 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：20 项；index 2-5 醉酿投/活血酒/天神酒/天神灌注具备 charge。
# charge_list：4 项充能项，maxValue 均为 8（上游为 Phantom 0..8 fallback）。
# player_buff：活力苏醒、清空地窖两项玩家增益。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/monk_brewmaster.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class MonkBrewmaster(SpecTemplate):
    spec_name = "酒仙武僧"
    spec_base = "MONK"
    spec_id = 1

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 121253, "description": "醉酿投", "charge": True},
            3: {"spellId": 119582, "description": "活血酒", "charge": True},
            4: {"spellId": 322507, "description": "天神酒", "charge": True},
            5: {"spellId": 1241059, "description": "天神灌注", "charge": True},
            6: {"spellId": 322109, "description": "轮回之触"},
            7: {"spellId": 119381, "description": "扫堂腿"},
            8: {"spellId": 322101, "description": "移花接木"},
            9: {"spellId": 101643, "description": "魂体双分"},
            10: {"spellId": 119996, "description": "魂体双分：转移"},
            11: {"spellId": 116705, "description": "切喉手"},
            12: {"spellId": 115181, "description": "火焰之息"},
            13: {"spellId": 123986, "description": "真气爆裂"},
            14: {"spellId": 325153, "description": "爆炸酒桶"},
            15: {"spellId": 198898, "description": "赤精之歌"},
            16: {"spellId": 115399, "description": "玄牛酒"},
            17: {"spellId": 116844, "description": "平心之环"},
            18: {"spellId": 115078, "description": "分筋错骨"},
            19: {"spellId": 132578, "description": "玄牛下凡"},
            20: {"spellId": 205523, "description": "幻灭踢"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 121253, "description": "醉酿投", "minValue": 0, "maxValue": 8},
            2: {"spellId": 119582, "description": "活血酒", "minValue": 0, "maxValue": 8},
            3: {"spellId": 322507, "description": "天神酒", "minValue": 0, "maxValue": 8},
            4: {"spellId": 1241059, "description": "天神灌注", "minValue": 0, "maxValue": 8},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "活力苏醒", "spellIDs": [392883]},
            2: {"description": "清空地窖", "spellIDs": [1262768]},
        }