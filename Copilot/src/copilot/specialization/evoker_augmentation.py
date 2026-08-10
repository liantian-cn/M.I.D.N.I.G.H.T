# 摘要：增辉唤魔师专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/evoker_augmentation.lua 的 SpellList、ChargeList、PartyBuff 字段。表 key 统一为
# 整数 1..n。上游 PlayerBuff 与 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：18 项；index 3/8/16 具备 charge。
# charge_list：黑曜鳞片、悬空、先知先觉三项，maxValue 均为 8（上游为 Phantom 0..8 fallback）。
# party_buff：青铜祝福单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/evoker_augmentation.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class EvokerAugmentation(SpecTemplate):
    spec_name = "增辉唤魔师"
    spec_base = "EVOKER"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 365585, "description": "净除"},
            3: {"spellId": 363916, "description": "黑曜鳞片", "charge": True},
            4: {"spellId": 358385, "description": "山崩"},
            5: {"spellId": 360995, "description": "青翠之拥"},
            6: {"spellId": 357210, "description": "深呼吸"},
            7: {"spellId": 374227, "description": "微风"},
            8: {"spellId": 358267, "description": "悬空", "charge": True},
            9: {"spellId": 368970, "description": "扫尾"},
            10: {"spellId": 370553, "description": "扭转天平"},
            11: {"spellId": 370665, "description": "营救"},
            12: {"spellId": 374968, "description": "时间螺旋"},
            13: {"spellId": 406732, "description": "空间悖论"},
            14: {"spellId": 357208, "description": "火焰吐息"},
            15: {"spellId": 396286, "description": "地壳激变"},
            16: {"spellId": 409311, "description": "先知先觉", "charge": True},
            17: {"spellId": 395152, "description": "黑檀之力"},
            18: {"spellId": 442204, "description": "亘古吐息"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 363916, "description": "黑曜鳞片", "minValue": 0, "maxValue": 8},
            2: {"spellId": 358267, "description": "悬空", "minValue": 0, "maxValue": 8},
            3: {"spellId": 409311, "description": "先知先觉", "minValue": 0, "maxValue": 8},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "青铜祝福",
            "spellIDs": [381748],
        }