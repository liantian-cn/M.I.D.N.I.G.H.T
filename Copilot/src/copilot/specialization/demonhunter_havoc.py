# 摘要：浩劫恶魔猎手专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/demonhunter_havoc.lua 的 SpellList 与 ChargeList 字段。表 key 统一为整数 1..n。
# 上游 PlayerBuff 与 TargetDebuff 为空表，PartyHots/PartyBuff/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：17 项；index 4 投掷利刃具备 charge。
# charge_list：投掷利刃 maxValue=8（上游为 Phantom 0..8 fallback）。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/demonhunter_havoc.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DemonhunterHavoc(SpecTemplate):
    spec_name = "浩劫恶魔猎手"
    spec_base = "DEMONHUNTER"
    spec_id = 1

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
            8: {"spellId": 179057, "description": "混乱新星"},
            9: {"spellId": 191427, "description": "恶魔变形"},
            10: {"spellId": 232893, "description": "邪能之刃"},
            11: {"spellId": 188499, "description": "刃舞"},
            12: {"spellId": 162794, "description": "混乱打击"},
            13: {"spellId": 198589, "description": "疾影"},
            14: {"spellId": 370965, "description": "恶魔追击"},
            15: {"spellId": 198013, "description": "眼棱"},
            16: {"spellId": 195072, "description": "邪能冲撞"},
            17: {"spellId": 258860, "description": "精华破碎"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 185123, "description": "投掷利刃", "minValue": 0, "maxValue": 8},
        }