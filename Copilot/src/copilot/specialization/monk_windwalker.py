# 摘要：踏风武僧专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/monk_windwalker.lua 的 SpellList、ChargeList 字段。表 key 统一为整数 1..n。
# 上游 PlayerBuff 与 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：17 项；index 4 乾元之巅具备 charge。
# charge_list：乾元之巅 maxValue=2。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/monk_windwalker.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class MonkWindwalker(SpecTemplate):
    spec_name = "踏风武僧"
    spec_base = "MONK"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 122470, "description": "业报之触"},
            3: {"spellId": 107428, "description": "旭日东升踢"},
            4: {"spellId": 1249625, "description": "乾元之巅", "charge": True},
            5: {"spellId": 218164, "description": "清创生血"},
            6: {"spellId": 152175, "description": "升龙霸"},
            7: {"spellId": 101545, "description": "翔龙在天"},
            8: {"spellId": 113656, "description": "怒雷破"},
            9: {"spellId": 322109, "description": "轮回之触"},
            10: {"spellId": 119381, "description": "扫堂腿"},
            11: {"spellId": 322101, "description": "移花接木"},
            12: {"spellId": 101643, "description": "魂体双分"},
            13: {"spellId": 119996, "description": "魂体双分：转移"},
            14: {"spellId": 116705, "description": "切喉手"},
            15: {"spellId": 198898, "description": "赤精之歌"},
            16: {"spellId": 116844, "description": "平心之环"},
            17: {"spellId": 115078, "description": "分筋错骨"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 1249625, "description": "乾元之巅", "minValue": 0, "maxValue": 2},
        }