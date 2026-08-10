# 摘要：恢复萨满祭司专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/shaman_restoration.lua 的 SpellList、ChargeList、PlayerBuff、PartyBuff 字段。
# 表 key 统一为整数 1..n。上游 TargetDebuff 为空表，PartyHots/无用字段未定义，沿用模板默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：23 项；index 13 熔岩爆裂、index 14 激流、index 15 治疗之泉图腾具备 charge。
# charge_list：熔岩爆裂 maxValue=8（fallback）、激流 maxValue=2、治疗之泉图腾 maxValue=4。
# player_buff：6 项玩家增益。
# party_buff：天怒单对象。

# 修改记录：
# 2026-08-01：按冻结 plan 从上游同步，整数 key 与文件头。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/shaman_restoration.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class ShamanRestoration(SpecTemplate):
    spec_name = "恢复萨满祭司"
    spec_base = "SHAMAN"
    spec_id = 3

    def __init__(self):
        super().__init__()
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list = {  # 等效lua的addonTable.SPEC.SpellList
            1: {"spellId": 61304, "description": "公共冷却", "isGCD": True},
            2: {"spellId": 57994, "description": "风剪"},
            3: {"spellId": 198103, "description": "土元素"},
            4: {"spellId": 192058, "description": "电能图腾"},
            5: {"spellId": 378081, "description": "自然迅捷"},
            6: {"spellId": 108287, "description": "图腾投射"},
            7: {"spellId": 51514, "description": "妖术"},
            8: {"spellId": 378773, "description": "强化净化术"},
            9: {"spellId": 8143, "description": "战栗图腾"},
            10: {"spellId": 383013, "description": "清毒图腾"},
            11: {"spellId": 192063, "description": "阵风"},
            12: {"spellId": 58875, "description": "幽魂步"},
            13: {"spellId": 51505, "description": "熔岩爆裂", "charge": True},
            14: {"spellId": 61295, "description": "激流", "charge": True},
            15: {"spellId": 5394, "description": "治疗之泉图腾", "charge": True},
            16: {"spellId": 470411, "description": "烈焰震击"},
            17: {"spellId": 77130, "description": "净化灵魂"},
            18: {"spellId": 73685, "description": "生命释放"},
            19: {"spellId": 443454, "description": "先祖迅捷"},
            20: {"spellId": 444995, "description": "涌动图腾"},
            21: {"spellId": 98008, "description": "灵魂链接图腾"},
            22: {"spellId": 114052, "description": "升腾"},
            23: {"spellId": 108280, "description": "治疗之潮图腾"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 51505, "description": "熔岩爆裂", "minValue": 0, "maxValue": 8},
            2: {"spellId": 61295, "description": "激流", "minValue": 0, "maxValue": 2},
            3: {"spellId": 5394, "description": "治疗之泉图腾", "minValue": 0, "maxValue": 4},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "飞旋之土", "spellIDs": [453406]},
            2: {"description": "潮汐奔涌", "spellIDs": [53390]},
            3: {"description": "风暴涌流图腾", "spellIDs": [1267089]},
            4: {"description": "生命释放", "spellIDs": [73685]},
            5: {"description": "升腾", "spellIDs": [114052]},
            6: {"description": "倾盆大雨", "spellIDs": [462488]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "天怒",
            "spellIDs": [462854],
        }