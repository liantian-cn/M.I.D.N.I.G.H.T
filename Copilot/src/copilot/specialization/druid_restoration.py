# 摘要：恢复德鲁伊专精定义，迁移自 PhantomProject 上游 lua 并按本地容器约定重写。

# 描述：
# 同步上游 src/class/druid_restoration.lua 的 SpellList、ChargeList、PlayerBuff、PartyHots、
# PartyBuff、DISPEL_TYPES、PartyRangeSpellIDs 与 TargetDebuff 字段。表 key 统一为整数 1..n，
# 与上游 1-based 索引对齐。PartyBuff 是单对象 dict，DISPEL_TYPES 与 PartyRangeSpellIDs 为本地
# set/list 表达。本专精不定义 ranged_spell/melee_spell，沿用模板 None 默认值。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash。
# spell_list：13 项技能冷却表，index 1 为公共冷却（spellId 61304, isGCD）。
# charge_list：迅捷治療充能项，minValue=0 maxValue=2。
# player_buff：9 项玩家增益 Aura 白名单。
# target_debuff：月火术、阳炎术两项目标减益。
# party_hots：5 项小队 HOT 监控。
# party_buff：野性印记单对象，spellIDs 含玩家自身与施加他人两 Aura ID。
# dispel_types：{Magic, Curse, Poison} 驱散类型集合。
# party_range_spell_ids：[8936, 774] 优先愈合、回退回春的距离候选。

# 修改记录：
# 2026-08-01：按冻结 plan 将字符串 key 改为整数 key、补齐 dispel_types 与 party_range_spell_ids、
#   调用 super().__init__() 重置默认值后覆盖、补齐文件头并更新 SPEC_GIT_COMMIT_HASH。


from .template import SpecTemplate

# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/druid_restoration.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class DruidRestoration(SpecTemplate):
    spec_name = "恢复德鲁伊"
    spec_base = "DRUID"
    spec_id = 4

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
            7: {"spellId": 18562, "description": "迅捷治愈", "charge": True},
            8: {"spellId": 48438, "description": "野性成长"},
            9: {"spellId": 391528, "description": "万灵之召"},
            10: {"spellId": 88423, "description": "自然之愈"},
            11: {"spellId": 102342, "description": "铁木树皮"},
            12: {"spellId": 132158, "description": "自然迅捷"},
            13: {"spellId": 1261867, "description": "野性之心"},
        }
        self.charge_list = {  # 等效lua的addonTable.SPEC.ChargeList
            1: {"spellId": 18562, "description": "迅捷治愈", "minValue": 0, "maxValue": 2},
        }
        self.player_buff = {  # 等效lua的addonTable.SPEC.PlayerBuff
            1: {"description": "爪子", "spellIDs": [1126, 432661]},
            2: {"description": "萌芽", "spellIDs": [155777]},
            3: {"description": "回春", "spellIDs": [778, 774]},
            4: {"description": "愈合", "spellIDs": [8936, 8938]},
            5: {"description": "野性成长", "spellIDs": [48438]},
            6: {"description": "生命绽放", "spellIDs": [33763]},
            7: {"description": "清晰预兆", "spellIDs": [16870, 16872]},
            8: {"description": "树皮术", "spellIDs": [22812]},
            9: {"description": "自然迅捷", "spellIDs": [132158]},
        }
        self.target_debuff = {  # 等效lua的addonTable.SPEC.TargetDebuff
            1: {"description": "月火术", "spellIDs": [164812, 8921]},
            2: {"description": "阳炎术", "spellIDs": [93402, 164815]},
        }
        self.party_hots = {  # 等效lua的addonTable.SPEC.PartyHots
            1: {"description": "萌芽", "spellIDs": [155777]},
            2: {"description": "回春", "spellIDs": [778, 774]},
            3: {"description": "愈合", "spellIDs": [8936, 8938]},
            4: {"description": "野性成长", "spellIDs": [48438]},
            5: {"description": "生命绽放", "spellIDs": [33763]},
        }
        self.party_buff = {  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
            "description": "野性印记",
            "spellIDs": [1126, 432661],
        }
        self.dispel_types = {  # 等效lua的addonTable.SPEC.DISPEL_TYPES ,计划中在Copilot中无用.
            "Magic", "Curse", "Poison",
        }
        self.party_range_spell_ids = [  # 等效lua的addonTable.SPEC.PartyRangeSpellIDs ,计划中在Copilot中无用.
            8936, 774,
        ]