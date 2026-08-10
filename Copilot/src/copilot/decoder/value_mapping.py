"""摘要：把当前 Phantom 玩家与环境编码转换为规范英文业务值。

描述：本模块集中保存 `01??` 与 `06??` 输出需要的全部离散映射和数值换算。
映射只属于当前 Phantom 适配器；业务 extractor 不重复解释原始字节。未知值返回稳定的
`unknown_*` 文本或 `None`，原始 B 字节仍由字段 envelope 保留。

主要变量信息：`CLASS_NAMES` 与 `SPECIALIZATION_NAMES` 描述职业/专精；其余映射表按
Phantom Cell 的紧凑编码反向解释职责、英雄天赋、难度和首领战。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
UPSTREAM COMMIT: 643fbc525f2173e80d571af7f43f739e6eaeb229
"""

from __future__ import annotations

UPSTREAM_COMMIT = "643fbc525f2173e80d571af7f43f739e6eaeb229"

CLASS_NAMES = {
    1: "WARRIOR",
    2: "PALADIN",
    3: "HUNTER",
    4: "ROGUE",
    5: "PRIEST",
    6: "DEATH_KNIGHT",
    7: "SHAMAN",
    8: "MAGE",
    9: "WARLOCK",
    10: "MONK",
    11: "DRUID",
    12: "DEMON_HUNTER",
    13: "EVOKER",
}

SPECIALIZATION_NAMES = {
    1: {1: "ARMS", 2: "FURY", 3: "PROTECTION"},
    2: {1: "HOLY", 2: "PROTECTION", 3: "RETRIBUTION"},
    3: {1: "BEAST_MASTERY", 2: "MARKSMANSHIP", 3: "SURVIVAL"},
    4: {1: "ASSASSINATION", 2: "OUTLAW", 3: "SUBTLETY"},
    5: {1: "DISCIPLINE", 2: "HOLY", 3: "SHADOW"},
    6: {1: "BLOOD", 2: "FROST", 3: "UNHOLY"},
    7: {1: "ELEMENTAL", 2: "ENHANCEMENT", 3: "RESTORATION"},
    8: {1: "ARCANE", 2: "FIRE", 3: "FROST"},
    9: {1: "AFFLICTION", 2: "DEMONOLOGY", 3: "DESTRUCTION"},
    10: {1: "BREWMASTER", 2: "MISTWEAVER", 3: "WINDWALKER"},
    11: {1: "BALANCE", 2: "FERAL", 3: "GUARDIAN", 4: "RESTORATION"},
    12: {1: "HAVOC", 2: "VENGEANCE", 3: "DEVOURER"},
    13: {1: "DEVASTATION", 2: "PRESERVATION", 3: "AUGMENTATION"},
}

ROLE_NAMES = {0: "NONE", 10: "TANK", 20: "HEALER", 30: "DAMAGER"}

HERO_TALENT_NAMES = {
    1: {0: "NONE", 1: "COLOSSUS", 2: "SLAYER", 3: "MOUNTAIN_THANE"},
    2: {0: "NONE", 1: "HERALD_OF_THE_SUN", 2: "LIGHTSMITH", 3: "TEMPLAR"},
    3: {0: "NONE", 1: "DARK_RANGER", 2: "PACK_LEADER", 3: "SENTINEL"},
    4: {0: "NONE", 1: "DEATHSTALKER", 2: "FATEBOUND", 3: "TRICKSTER"},
    5: {0: "NONE", 1: "ORACLE", 2: "VOIDWEAVER", 3: "ARCHON"},
    6: {0: "NONE", 1: "DEATHBRINGER", 2: "SANLAYN", 3: "RIDER_OF_THE_APOCALYPSE"},
    7: {0: "NONE", 1: "FARSEER", 2: "STORMBRINGER", 3: "TOTEMIC"},
    8: {0: "NONE", 1: "SPELLSLINGER", 2: "SUNFURY", 3: "FROSTFIRE"},
    9: {0: "NONE", 1: "HELLCALLER", 2: "SOUL_HARVESTER", 3: "DIABOLIST"},
    10: {0: "NONE", 1: "MASTER_OF_HARMONY", 2: "SHADO_PAN", 3: "CONDUIT_OF_THE_CELESTIALS"},
    11: {0: "NONE", 1: "ELUNES_CHOSEN", 2: "KEEPER_OF_THE_GROVE", 3: "DRUID_OF_THE_CLAW", 4: "WILDSTALKER"},
    12: {0: "NONE", 1: "ALDRACHI_REAVER", 2: "FEL_SCARRED", 3: "ANNIHILATOR"},
    13: {
        0: "NONE",
        1: "FLAMESHAPER",
        2: "SCALECOMMANDER_OR_CHRONOWARDEN",
    },
}

INSTANCE_DIFFICULTY_NAMES = {
    0: "NONE",
    1: "NORMAL_DUNGEON",
    2: "HEROIC_DUNGEON",
    7: "LEGACY_LFR",
    8: "MYTHIC_KEYSTONE",
    9: "LEGACY_40_PLAYER_RAID",
    14: "NORMAL_RAID",
    15: "HEROIC_RAID",
    16: "MYTHIC_RAID",
    17: "LOOKING_FOR_RAID",
    23: "MYTHIC_DUNGEON",
    24: "TIMEWALKING_DUNGEON",
    33: "TIMEWALKING_RAID",
}

BOSS_ENCOUNTER_NAMES = {
    0: "NONE_OR_UNKNOWN",
    **{code: f"RAID_ENCOUNTER_{code}" for code in range(1, 14)},
    **{code: f"DUNGEON_ENCOUNTER_{code}" for code in range(51, 80)},
}


def scaled_integer(raw_value: int, scale: int) -> int:
    return int(raw_value) // scale


def percentage(raw_value: int) -> float:
    return float(raw_value) / 255.0 * 100.0


def boolean(raw_value: int) -> bool:
    return bool(raw_value)


def class_name(raw_value: int) -> str:
    class_id = scaled_integer(raw_value, 10)
    return CLASS_NAMES.get(class_id, f"UNKNOWN_CLASS_{class_id}")


def specialization_name(class_id: int, raw_value: int) -> str:
    specialization_index = scaled_integer(raw_value, 10)
    return SPECIALIZATION_NAMES.get(class_id, {}).get(
        specialization_index,
        f"UNKNOWN_SPECIALIZATION_{specialization_index}",
    )


def role_name(raw_value: int) -> str:
    return ROLE_NAMES.get(raw_value, f"UNKNOWN_ROLE_{raw_value}")


def cast_target_name(raw_value: int) -> str:
    if raw_value == 0:
        return "player"
    if 1 <= raw_value <= 4:
        return f"party{raw_value}"
    if 6 <= raw_value <= 45:
        return f"raid{raw_value - 5}"
    return "unknown"


def hero_talent_name(class_id: int, raw_value: int) -> str:
    return HERO_TALENT_NAMES.get(class_id, {}).get(
        raw_value,
        f"UNKNOWN_HERO_TALENT_{raw_value}",
    )


def group_type_name(raw_value: int) -> str:
    if raw_value == 0:
        return "solo"
    if raw_value == 46:
        return "party"
    if 1 <= raw_value <= 40:
        return "raid"
    return "unknown"


def raid_index(raw_value: int) -> int | None:
    return raw_value if 1 <= raw_value <= 40 else None


def boss_encounter_name(raw_value: int) -> str:
    return BOSS_ENCOUNTER_NAMES.get(raw_value, f"UNKNOWN_ENCOUNTER_{raw_value}")


def instance_difficulty_name(raw_value: int) -> str:
    return INSTANCE_DIFFICULTY_NAMES.get(raw_value, f"DIFFICULTY_{raw_value}")


__all__ = [
    "UPSTREAM_COMMIT",
    "boolean",
    "boss_encounter_name",
    "cast_target_name",
    "class_name",
    "group_type_name",
    "hero_talent_name",
    "instance_difficulty_name",
    "percentage",
    "raid_index",
    "role_name",
    "scaled_integer",
    "specialization_name",
]
