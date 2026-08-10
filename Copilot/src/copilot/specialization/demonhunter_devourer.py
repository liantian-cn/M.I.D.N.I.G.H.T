# 摘要：吞噬者恶魔猎手专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/demonhunter_devourer.lua 的 SpellList 与 ChargeList 字段。表 key 统一为整数 1..n。
# 上游 PlayerBuff 与 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：18 项；index 4 投掷利刃、index 11 变换具备 charge。
# charge_list：投掷利刃 maxValue=8、变换 maxValue=8（上游为 Phantom 0..8 fallback）。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，spec_name 采用官方修译"吞噬者恶魔猎手"，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/demonhunter_devourer.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DemonhunterDevourer(SpecTemplate):
    spec_name = "吞噬者恶魔猎手"
    spec_base = "DEMONHUNTER"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 196718, "description": "黑暗"},
            3: {"spellId": 198793, "description": "复仇回避"},
            4: {"spellId": 185123, "description": "投掷利刃", "charge": True},
            5: {"spellId": 207684, "description": "悲苦咒符"},
            6: {"spellId": 217832, "description": "禁锢"},
            7: {"spellId": 258920, "description": "献祭光环"},
            8: {"spellId": 1234195, "description": "虚空新星"},
            9: {"spellId": 1217605, "description": "虚空变形"},
            10: {"spellId": 1245412, "description": "虚空之刃"},
            11: {"spellId": 1234796, "description": "变换", "charge": True},
            12: {"spellId": 1226019, "description": "收割"},
            13: {"spellId": 473662, "description": "吞噬"},
            14: {"spellId": 198589, "description": "疾影"},
            15: {"spellId": 473728, "description": "虚空射线"},
            16: {"spellId": 1246167, "description": "恶魔追击"},
            17: {"spellId": 1239123, "description": "饥渴斩击"},
            18: {"spellId": 1245453, "description": "剔除"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 185123, "description": "投掷利刃", "minValue": 0, "maxValue": 8},
            2: {"spellId": 1234796, "description": "变换", "minValue": 0, "maxValue": 8},
        }