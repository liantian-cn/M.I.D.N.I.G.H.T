# 摘要：specialization 子包入口，集中导入全部专精模块的职业类并提供路由器。

# 描述：
# 本包是 Copilot 本地专精元数据持有者，每个专精一个以 PhantomProject 上游 lua 为权威来源的 .py 模块。
# __init__.py 按 class_* 字母序分组导入 38 个职业类，并维护 (spec_base, spec_id) -> SPEC 类 的注册表。
# resolve_specialization 把 Matrix 解码得到的 class_id 经 SPEC_BASE_BY_CLASS_ID 映射为 spec_base（独立于
# value_mapping.CLASS_NAMES，因 DK/DH 在两处命名带不带下划线不同），再查注册表返回新实例；无匹配返回 None，
# 供 extractor 对未知专精做字段级降级。

# 主要变量信息：
# SPEC_BASE_BY_CLASS_ID：class_id(1..13) -> spec_base 大写英文 token，独立于 CLASS_NAMES 的 HTTP 公开值。
# _SPECIALIZATION_REGISTRY：(spec_base, spec_id) -> SPEC 类，导入后自动构建。
# resolve_specialization：按 (class_id, spec_id) 返回 SPEC 实例或 None。

# 修改记录：
# 2026-08-01：按冻结 plan 完成 38 个职业类的集中导入。
# 2026-08-02：按 Phase 2.6 Spell Matrix Decoder 冻结 plan 新增 SPEC_BASE_BY_CLASS_ID、注册表与 resolve_specialization。


from .deathknight_blood import DeathknightBlood
from .deathknight_frost import DeathknightFrost
from .deathknight_unholy import DeathknightUnholy

from .demonhunter_devourer import DemonhunterDevourer
from .demonhunter_havoc import DemonhunterHavoc
from .demonhunter_vengeance import DemonhunterVengeance

from .druid_balance import DruidBalance
from .druid_feral import DruidFeral
from .druid_guardian import DruidGuardian
from .druid_restoration import DruidRestoration

from .evoker_augmentation import EvokerAugmentation
from .evoker_devastation import EvokerDevastation
from .evoker_preservation import EvokerPreservation

from .hunter_beast_mastery import HunterBeastMastery
from .hunter_marksmanship import HunterMarksmanship
from .hunter_survival import HunterSurvival

from .mage_arcane import MageArcane
from .mage_fire import MageFire
from .mage_frost import MageFrost

from .monk_brewmaster import MonkBrewmaster
from .monk_mistweaver import MonkMistweaver
from .monk_windwalker import MonkWindwalker

from .paladin_holy import PaladinHoly
from .paladin_protection import PaladinProtection
from .paladin_retribution import PaladinRetribution

from .priest_discipline import PriestDiscipline
from .priest_holy import PriestHoly
from .priest_shadow import PriestShadow

from .rogue_assassination import RogueAssassination
from .rogue_outlaw import RogueOutlaw
from .rogue_subtlety import RogueSubtlety

from .shaman_elemental import ShamanElemental
from .shaman_enhancement import ShamanEnhancement
from .shaman_restoration import ShamanRestoration

from .warlock_affliction import WarlockAffliction
from .warlock_demonology import WarlockDemonology
from .warlock_destruction import WarlockDestruction

from .warrior_arms import WarriorArms
from .warrior_fury import WarriorFury
from .warrior_protection import WarriorProtection

from .template import SpecTemplate


# class_id 到 spec_base 的映射，独立于 value_mapping.CLASS_NAMES。
# CLASS_NAMES 用 "DEATH_KNIGHT"/"DEMON_HUNTER"（带下划线）作为 HTTP 公开值；
# spec_base 用 "DEATHKNIGHT"/"DEMONHUNTER"（无下划线）作为本地 SPEC 类属性。
SPEC_BASE_BY_CLASS_ID: dict[int, str] = {
    1: "WARRIOR",
    2: "PALADIN",
    3: "HUNTER",
    4: "ROGUE",
    5: "PRIEST",
    6: "DEATHKNIGHT",
    7: "SHAMAN",
    8: "MAGE",
    9: "WARLOCK",
    10: "MONK",
    11: "DRUID",
    12: "DEMONHUNTER",
    13: "EVOKER",
}

# 已导入的全部 SPEC 类，用于构建注册表。
_SPEC_CLASSES: tuple[type[SpecTemplate], ...] = (
    DeathknightBlood, DeathknightFrost, DeathknightUnholy,
    DemonhunterDevourer, DemonhunterHavoc, DemonhunterVengeance,
    DruidBalance, DruidFeral, DruidGuardian, DruidRestoration,
    EvokerAugmentation, EvokerDevastation, EvokerPreservation,
    HunterBeastMastery, HunterMarksmanship, HunterSurvival,
    MageArcane, MageFire, MageFrost,
    MonkBrewmaster, MonkMistweaver, MonkWindwalker,
    PaladinHoly, PaladinProtection, PaladinRetribution,
    PriestDiscipline, PriestHoly, PriestShadow,
    RogueAssassination, RogueOutlaw, RogueSubtlety,
    ShamanElemental, ShamanEnhancement, ShamanRestoration,
    WarlockAffliction, WarlockDemonology, WarlockDestruction,
    WarriorArms, WarriorFury, WarriorProtection,
)

# (spec_base, spec_id) -> SPEC 类 的注册表，供路由器查找。
_SPECIALIZATION_REGISTRY: dict[tuple[str, int], type[SpecTemplate]] = {
    (cls.spec_base, cls.spec_id): cls for cls in _SPEC_CLASSES
}


def resolve_specialization(class_id: int, spec_id: int) -> SpecTemplate | None:
    """按 (class_id, spec_id) 返回对应 SPEC 实例；无匹配返回 None。"""

    spec_base = SPEC_BASE_BY_CLASS_ID.get(class_id)
    if spec_base is None:
        return None
    spec_class = _SPECIALIZATION_REGISTRY.get((spec_base, spec_id))
    if spec_class is None:
        return None
    return spec_class()


__all__ = ["SPEC_BASE_BY_CLASS_ID", "resolve_specialization"]