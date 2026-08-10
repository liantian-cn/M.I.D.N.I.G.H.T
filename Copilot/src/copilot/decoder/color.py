"""摘要：把 Phantom 当前技能与 Aura 边框颜色转换为 Copilot 图标类别。

描述：保留当前上游颜色语义，将玩家技能、两类敌方施法和七种友方减益聚合为四个
可持久化类别；UNKNOWN、NONE、友方增益和敌方减益归入只读 Other 组。RGB 别名采用
Aura 名称作为数据库规范类别，动态颜色仍绑定当前上游提交。

主要变量信息：`ICON_TYPE_BY_COLOR` 反向当前颜色；`ICON_CATEGORY_BY_TYPE` 执行四类
聚合；`OTHER_ICON_TYPES` 列出不可持久化类型。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增；
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划完善类别聚合和 Other 分流。
UPSTREAM COMMIT: 643fbc525f2173e80d571af7f43f739e6eaeb229
"""

from __future__ import annotations

from collections.abc import Iterable

UPSTREAM_COMMIT = "643fbc525f2173e80d571af7f43f739e6eaeb229"

COLOR = {
    # "PLAYER": (64, 158, 210),
    # "INTERRUPTIBLE": (255, 255, 60),
    # "NOT_INTERRUPTIBLE": (200, 0, 0),
    "MAGIC": (60, 100, 220),
    "CURSE": (100, 0, 120),
    "DISEASE": (160, 120, 60),
    "POISON": (154, 205, 50),
    "ENRAGE": (230, 120, 20),
    "BLEED": (80, 0, 20),
    "DEBUFF_ON_FRIENDLY": (255, 60, 60),
    "BUFF_ON_FRIENDLY": (80, 220, 120),
    "PLAYER_SPELL": (64, 158, 210),
    "ENEMY_SPELL_INTERRUPTIBLE": (255, 255, 60),
    "ENEMY_SPELL_NOT_INTERRUPTIBLE": (200, 0, 0),
    "DEBUFF_ON_ENEMY": (105, 105, 210),
    "NONE": (0, 0, 0),
}

ICON_CATEGORIES = (
    "PLAYER_SPELL",
    "ENEMY_SPELL_INTERRUPTIBLE",
    "ENEMY_SPELL_NOT_INTERRUPTIBLE",
    "DEBUFF_ON_FRIENDLY",
)

FRIENDLY_DEBUFF_TYPES = (
    "MAGIC",
    "CURSE",
    "DISEASE",
    "POISON",
    "ENRAGE",
    "BLEED",
    "DEBUFF_ON_FRIENDLY",
)
OTHER_ICON_TYPES = (
    "UNKNOWN",
    "NONE",
    "BUFF_ON_FRIENDLY",
    "DEBUFF_ON_ENEMY",
)

# RGB 别名使用标题数据库所需的规范 Aura 名称。
ICON_TYPE_BY_COLOR = {
    COLOR["PLAYER_SPELL"]: "PLAYER_SPELL",
    COLOR["ENEMY_SPELL_INTERRUPTIBLE"]: "ENEMY_SPELL_INTERRUPTIBLE",
    COLOR["ENEMY_SPELL_NOT_INTERRUPTIBLE"]: "ENEMY_SPELL_NOT_INTERRUPTIBLE",
    **{COLOR[name]: name for name in FRIENDLY_DEBUFF_TYPES},
    COLOR["BUFF_ON_FRIENDLY"]: "BUFF_ON_FRIENDLY",
    COLOR["DEBUFF_ON_ENEMY"]: "DEBUFF_ON_ENEMY",
    COLOR["NONE"]: "NONE",
}

ICON_CATEGORY_BY_TYPE = {
    "PLAYER_SPELL": "PLAYER_SPELL",
    "ENEMY_SPELL_INTERRUPTIBLE": "ENEMY_SPELL_INTERRUPTIBLE",
    "ENEMY_SPELL_NOT_INTERRUPTIBLE": "ENEMY_SPELL_NOT_INTERRUPTIBLE",
    **{name: "DEBUFF_ON_FRIENDLY" for name in FRIENDLY_DEBUFF_TYPES},
}
ICON_CATEGORY_BY_COLOR = {
    color: ICON_CATEGORY_BY_TYPE[title_type]
    for color, title_type in ICON_TYPE_BY_COLOR.items()
    if title_type in ICON_CATEGORY_BY_TYPE
}


def icon_type_from_colors(colors: Iterable[tuple[int, int, int]]) -> str:
    """返回边框中出现次数最多的当前上游标题类型。"""

    counts: dict[str, int] = {}
    for color in colors:
        title_type = ICON_TYPE_BY_COLOR.get(color)
        if title_type is not None:
            counts[title_type] = counts.get(title_type, 0) + 1
    if not counts:
        return "UNKNOWN"
    if len(counts) > 1:
        counts.pop("NONE", None)
    return max(counts.items(), key=lambda item: item[1])[0]


def icon_category_from_colors(colors: Iterable[tuple[int, int, int]]) -> str | None:
    """把当前上游边框颜色聚合为四类持久化类别。"""

    return ICON_CATEGORY_BY_TYPE.get(icon_type_from_colors(colors))


__all__ = [
    "COLOR",
    "FRIENDLY_DEBUFF_TYPES",
    "ICON_CATEGORIES",
    "ICON_CATEGORY_BY_COLOR",
    "ICON_CATEGORY_BY_TYPE",
    "ICON_TYPE_BY_COLOR",
    "OTHER_ICON_TYPES",
    "UPSTREAM_COMMIT",
    "icon_category_from_colors",
    "icon_type_from_colors",
]
