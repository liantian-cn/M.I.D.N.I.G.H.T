"""摘要：从当前 Phantom Matrix 提取状态、环境、技能、充能、Aura、队伍与辅助信息。

描述：直接构造 MatrixDecoder，逐项读取当前 `01??`/`02??`/`03??`/`06??_*.lua` 坐标，
验证普通 Cell 的 classification/index，并把原始字节交给 value_mapping 生成规范英文
业务值。玩家/目标/焦点施法 IconCell 通过可选 TitleManager 完成三级识别；空图标返回
None。target/focus 各字段按上游 `0201..0211`、`0301..0311` 列出，复用现有
`cell_record`/`icon_record` 辅助函数；二者在 `extract_matrix` 返回顶层平铺字段，
不沿用 player 的 `status` 级嵌套。spell 字段按上游 `0401_spell.lua` 的 26 槽位 2x2
布局（cooldown/usable/overlayed/known）解码，经 `resolve_specialization` 路由到本地
SPEC 对象取得 description/spellId；未知 (class_id, spec_id) 返回空 list 字段级降级。
charge 字段按 `0402_charge.lua` 的垂直 Bar 布局解码，用 SPEC charge_list 的 min/max
把 Bar 占比映射为实际充能值；未知专精同样返回空 list。
player_buff/target_debuff 按 `0501`/`0502` 的固定 AuraSlot 布局解码；player_debuff 按
`0503` 的动态 AuraGroup 布局解码。固定 AuraSlot 每槽读取上层 DurationBar 与下层
ApplicationBar，并用 SPEC Aura 元数据解释名称、spellIDs 与层数上限；spell、charge 和
固定 AuraSlot 的单个非黑配置槽若出现 classification/index 协议异常则跳过该槽并继续读取。
动态 AuraGroup 使用 IconCell 结果作为名称，跳过全黑或单项协议异常并继续读取后续物理项。
完整全黑固定槽表示未激活 Aura，保留配置行并归零。party 按四个固定成员行读取十项状态；
不存在成员只保留 exists，状态协议异常只省略对应成员。party HOT 按专精固定槽读取单条
DurationBar，全黑配置槽归零，非黑协议异常槽省略。
raid 按 Phantom 的四段不规则布局读取三十个 6x2 成员块；raid HOT 使用单 Cell 只判断
存在，不计算持续时间。assisted_combat 读取单个可选 IconCell；interrupt_blacklist
逐槽跳过全黑项并返回最多十项；badge UTF 只在图标与包裹标题均有效时学习新标题。

主要变量信息：`decoder` 是当前帧访问器；`title_manager` 由 DecoderWorker 线程拥有；
`player_class_id` 用于专精和英雄天赋的组合映射。`cell_record` 组装普通 Cell 的带类型
结果信封，`derived_cell_record` 在已有信封上派生新映射，`icon_record` 集中处理图标
IconCell 的三级识别和 Other 降级，便于复用到 player/target/focus 等图标。
`decode_spell_cell` 按 (class_id, spec_id) 路由 SPEC 并解码 spell 2x2 cell 组。
`decode_spell_charge_bar` 按相同路由解码已配置的一基 charge 槽位。
`decode_aura_slot_container` 按 list_type 解码已配置的一基固定 Aura 槽位。
`decode_aura_group_container` 解码连续物理 AuraGroup 项。
`decode_party_container` 解码四个小队成员及其专精固定 HOT 槽。
`decode_raid_container` 解码三十个团队成员及其专精 HOT 存在 Cell。
`decode_optional_icon` 与 `decode_horizontal_icon_list` 提供辅助图标的字段级容错；
`learn_badge_utf_title` 在 worker 所有的标题库中仅新增有效 UTF 配对。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划修正未知图标降级行为。
2026-08-01，根据代码优化计划重命名辅助函数、展开布尔字段流水账并抽取图标记录函数。
2026-08-01，根据 Phase 2.6 Target and Focus Matrix Decoder 冻结计划新增 target/focus。
2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划新增 decode_spell_cell 与 spell 字段。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划新增 charge Bar 解码与 charge 字段。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划新增固定 AuraSlot 解码。
2026-08-02，根据 Aura Duration Direct Ratio 冻结计划调整持续时间为剩余比例直接映射。
2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划新增动态 AuraGroup 解码。
2026-08-02，根据槽位解码容错计划跳过 spell、charge 与固定 Aura 的单槽协议异常。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划新增小队状态与 HOT 解码。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 冻结计划新增团队状态与 HOT 解码。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划新增辅助图标与 UTF 标题学习。
UPSTREAM COMMIT: 41d782953370e3ada31eeefb137bac48d11a1e3f
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import datetime
from typing import Any

import numpy as np

from .cell import Cell
from .icon_cell import IconCell
from .matrix import MatrixDecoder
from .title_manager import IconTitleManager
from .value_mapping import (
    boolean,
    boss_encounter_name,
    cast_target_name,
    class_name,
    group_type_name,
    hero_talent_name,
    instance_difficulty_name,
    percentage,
    raid_index,
    role_name,
    scaled_integer,
    specialization_name,
)

from ..specialization import resolve_specialization

UPSTREAM_COMMIT = "41d782953370e3ada31eeefb137bac48d11a1e3f"
Converter = Callable[[int], Any]


def cell_record(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    classification: str,
    index: int,
    converter: Converter,
) -> dict[str, Any]:
    cell = decoder.get_cell(x, y)
    validate_cell(cell, classification, index)
    return cell_record_from_cell(cell, converter)


def cell_record_from_cell(cell: Cell, converter: Converter) -> dict[str, Any]:
    return {
        "type": "Cell",
        "classification": cell.classification,
        "index": cell.index,
        "raw_value": cell.raw_value,
        "result": converter(cell.raw_value),
    }


def matches_cell_protocol(cell: Cell, classification: str, index: int) -> bool:
    return cell.classification == classification and cell.index == index


def derived_cell_record(
    source: dict[str, Any],
    converter: Converter,
) -> dict[str, Any]:
    raw_value = int(source["raw_value"])
    return {
        "type": "Cell",
        "classification": source["classification"],
        "index": source["index"],
        "raw_value": raw_value,
        "result": converter(raw_value),
    }


def validate_cell(cell: Cell, classification: str, index: int) -> None:
    if cell.classification != classification or cell.index != index:
        raise ValueError(
            f"Cell ({cell.x}, {cell.y}) 协议不匹配: "
            f"{cell.classification}/{cell.index}, 预期 {classification}/{index}"
        )


def icon_record_from_cell(
    cell: IconCell,
    title_manager: IconTitleManager | None,
) -> dict[str, Any]:
    icon_result: str | None = None
    if not cell.is_blank:
        icon_category = cell.icon_category
        icon_hash_value = cell.icon_hash
        if icon_hash_value is None:
            raise ValueError("非空图标缺少 hash")
        if title_manager is None:
            icon_result = icon_hash_value
        elif icon_category is not None:
            icon_result = title_manager.resolve(cell.valid_array, icon_category, icon_hash_value)
        else:
            title_manager.cache_other(cell.valid_array, cell.icon_type or "UNKNOWN", icon_hash_value)
            icon_result = icon_hash_value
    return {
        "type": "IconCell",
        "icon_hash": cell.icon_hash,
        "icon_category": cell.icon_category,
        "result": icon_result,
    }


def icon_record(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    title_manager: IconTitleManager | None,
) -> dict[str, Any]:
    return icon_record_from_cell(decoder.get_icon_cell(x, y), title_manager)


def decode_optional_icon(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    title_manager: IconTitleManager | None,
    allowed_categories: tuple[str, ...],
) -> dict[str, Any] | None:
    """解码限定类别的可选 IconCell；坏槽返回 None。"""

    cell = decoder.get_icon_cell(x, y)
    if (
        cell.is_blank
        or cell.icon_hash is None
        or (
            cell.icon_category is not None
            and cell.icon_category not in allowed_categories
        )
    ):
        return None
    return icon_record_from_cell(cell, title_manager)


def decode_horizontal_icon_list(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    length: int,
    title_manager: IconTitleManager | None,
    allowed_categories: tuple[str, ...],
) -> list[dict[str, Any]]:
    """按两格步长读取水平 IconCell 列表并省略空项。"""

    records: list[dict[str, Any]] = []
    for index in range(length):
        record = decode_optional_icon(
            decoder,
            x + 2 * index,
            y,
            title_manager,
            allowed_categories,
        )
        if record is not None:
            records.append(record)
    return records


def learn_badge_utf_title(
    decoder: MatrixDecoder,
    title_manager: IconTitleManager | None,
    icon_x: int = 41,
    icon_y: int = 16,
    utf_x: int = 43,
    utf_y: int = 16,
    utf_length: int = 16,
) -> bool:
    """从 badge UTF 传输区学习一个尚未持久化的图标标题。"""

    if title_manager is None:
        return False
    icon = decoder.get_icon_cell(icon_x, icon_y)
    icon_hash_value = icon.icon_hash
    icon_category = icon.icon_category
    if (
        icon.is_blank
        or icon_hash_value is None
        or icon_category
        not in ("PLAYER_SPELL", "ENEMY_SPELL_INTERRUPTIBLE")
    ):
        return False
    title = decoder.read_utf_title(utf_x, utf_y, utf_length)
    if title is None:
        return False
    return title_manager.add_record_if_absent(
        icon.valid_array,
        icon_category,
        title,
        icon_hash_value,
    )


def decode_spell_cell(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    length: int,
    class_id: int,
    spec_id: int,
) -> list[dict[str, Any]]:
    """按 (class_id, spec_id) 路由到 SPEC，解码 spell 矩阵 2x2 cell 组。

    每个 spell 槽位 index 对应 base_x = x + 2*(index-1)，四格布局为：
    cooldown (base_x, y) / usable (base_x+1, y) / overlayed (base_x, y+1) / known (base_x+1, y+1)。
    仅遍历 spec.spell_list 中 1..length 范围的 key；无匹配 SPEC 或 spell_list 为空返回 []。
    单个非黑配置槽位的四格 classification/index 任一不匹配时省略该槽，后续槽位继续解码；
    完整全黑配置槽保持原有帧级失败行为。
    """

    spec = resolve_specialization(class_id, spec_id)
    if spec is None:
        return []
    spells: list[dict[str, Any]] = []
    for index in sorted(spec.spell_list):
        if index < 1 or index > length:
            continue
        base_x = x + 2 * (index - 1)
        cooldown_cell = decoder.get_cell(base_x, y)
        usable_cell = decoder.get_cell(base_x + 1, y)
        overlayed_cell = decoder.get_cell(base_x, y + 1)
        known_cell = decoder.get_cell(base_x + 1, y + 1)
        if not (
            matches_cell_protocol(cooldown_cell, "SPELL_COOLDOWN", index)
            and matches_cell_protocol(usable_cell, "SPELL_USABLE", index)
            and matches_cell_protocol(overlayed_cell, "SPELL_OVERLAYED", index)
            and matches_cell_protocol(known_cell, "SPELL_KNOWN", index)
        ):
            cells = (cooldown_cell, usable_cell, overlayed_cell, known_cell)
            if any(np.any(cell.pix_array) for cell in cells):
                continue
            validate_cell(cooldown_cell, "SPELL_COOLDOWN", index)
        spell_info = spec.spell_list[index]
        spells.append({
            "type": "spell",
            "index": index,
            "description": spell_info["description"],
            "spellId": spell_info["spellId"],
            "cooldown": cell_record_from_cell(cooldown_cell, percentage),
            "usable": cell_record_from_cell(usable_cell, boolean),
            "overlayed": cell_record_from_cell(overlayed_cell, boolean),
            "known": cell_record_from_cell(known_cell, boolean),
        })
    return spells


def decode_spell_charge_bar(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    length: int,
    class_id: int,
    spec_id: int,
) -> list[dict[str, Any]]:
    """按 SPEC charge_list 的原始槽位解码垂直 ChargeBar。

    先完整校验所有 key，再读取任一 Bar，确保超限配置遵循上游整组不创建的失败语义，
    不产生部分结果。范围内允许稀疏 key，只读取实际配置槽位，不读取中间黑色区域。
    已配置非黑 ChargeBar 的 classification/index 不匹配时省略该槽，后续槽位继续解码；
    完整全黑配置槽保持原有帧级失败行为。
    """

    spec = resolve_specialization(class_id, spec_id)
    if spec is None:
        return []

    indexes = list(spec.charge_list)
    for index in indexes:
        if isinstance(index, bool) or not isinstance(index, int) or index < 1:
            raise ValueError("charge_list key 必须是一基正整数")
        if index > length:
            raise ValueError(f"charge_list 槽位 {index} 超过上限 {length}")

    charges: list[dict[str, Any]] = []
    for index in sorted(indexes):
        bar = decoder.get_charge_bar(x + index - 1, y)
        if bar.classification != "SPELL_CHARGE" or bar.index != index:
            if np.any(bar.pix_array):
                continue
            raise ValueError(
                f"ChargeBar ({bar.x}, {bar.y}) 协议不匹配: "
                f"{bar.classification}/{bar.index}, 预期 SPELL_CHARGE/{index}"
            )
        charge_info = spec.charge_list[index]
        raw_value = float(bar.ratio)
        result = float(
            charge_info["minValue"]
            + (charge_info["maxValue"] - charge_info["minValue"]) * raw_value
        )
        charges.append({
            "type": "charge",
            "index": index,
            "description": charge_info["description"],
            "spellId": charge_info["spellId"],
            "minValue": charge_info["minValue"],
            "maxValue": charge_info["maxValue"],
            "raw_value": raw_value,
            "result": result,
        })
    return charges


def decode_aura_slot_container(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    length: int,
    class_id: int,
    spec_id: int,
    list_type: str,
) -> list[dict[str, Any]]:
    """按专精配置解码固定 AuraSlot 容器。

    先完整校验配置 key，再按原始一基槽位读取 Bar，避免超限配置产生部分结果。完整
    4x2 黑色区域是 Phantom 隐藏未激活 Aura 后的正常状态；其余槽位若任一 Bar 的
    分类或 index 协议不匹配，则省略该槽并继续后续配置槽位。持续时间编码表示剩余时间
    比例，因此结果直接换算为百分比；
    层数默认映射到 0..2，并允许专精配置覆盖上限。完整黑槽是未激活状态，两项结果都
    直接归零。
    """

    if list_type == "player_buff":
        duration_classification = "PLAYER_BUFF_DURATION"
        application_classification = "PLAYER_BUFF_COUNT"
    elif list_type == "target_debuff":
        duration_classification = "TARGET_DEBUFF_DURATION"
        application_classification = "TARGET_DEBUFF_COUNT"
    else:
        raise ValueError("list_type 必须是 player_buff 或 target_debuff")

    spec = resolve_specialization(class_id, spec_id)
    if spec is None:
        return []
    aura_list = (
        spec.player_buff if list_type == "player_buff" else spec.target_debuff
    )

    indexes = list(aura_list)
    for index in indexes:
        if isinstance(index, bool) or not isinstance(index, int) or index < 1:
            raise ValueError(f"{list_type} key 必须是一基正整数")
        if index > length:
            raise ValueError(f"{list_type} 槽位 {index} 超过上限 {length}")

    aura_slots: list[dict[str, Any]] = []
    for index in sorted(indexes):
        base_x = x + 4 * (index - 1)
        duration_bar = decoder.get_duration_bar(base_x, y)
        application_bar = decoder.get_application_bar(base_x, y + 1)
        aura_info = aura_list[index]
        min_value = 0
        max_value = aura_info.get("maxApplications", 2)

        inactive = not np.any(duration_bar.pix_array) and not np.any(
            application_bar.pix_array
        )
        if inactive:
            duration_raw_value = 0.0
            duration_result = 0.0
            application_raw_value = 0.0
            application_result = 0.0
        else:
            if (
                duration_bar.classification != duration_classification
                or duration_bar.index != index
            ):
                continue
            if (
                application_bar.classification != application_classification
                or application_bar.index != index
            ):
                continue
            duration_raw_value = float(duration_bar.ratio)
            duration_result = float(100.0 * duration_raw_value)
            application_raw_value = float(application_bar.ratio)
            application_result = float(
                min_value + (max_value - min_value) * application_raw_value
            )

        aura_slots.append({
            "type": "aura_slot",
            "index": index,
            "description": aura_info["description"],
            "spellId": list(aura_info["spellIDs"]),
            "duration": {
                "raw_value": duration_raw_value,
                "result": duration_result,
            },
            "application": {
                "raw_value": application_raw_value,
                "minValue": min_value,
                "maxValue": max_value,
                "result": application_result,
            },
        })
    return aura_slots


def decode_aura_group_container(
    decoder: MatrixDecoder,
    x: int,
    y: int,
    length: int,
    title_manager: IconTitleManager | None = None,
) -> list[dict[str, Any]]:
    """按动态 AuraGroup 的连续 6x2 物理项读取玩家减益。

    每个物理项左侧是 2x2 IconCell，右侧上下各一个 4x1 Bar。完整黑色项表示没有
    Aura；非黑项若图标为空或两条 Bar 的分类/index 不匹配，则只丢弃当前物理项，继续
    读取后续项。图标标题识别仍沿用现有三级数据库路径，相关基础设施异常保持整帧失败。
    """

    if isinstance(length, bool) or not isinstance(length, int) or length < 0:
        raise ValueError("aura_group length 必须是非负整数")

    aura_groups: list[dict[str, Any]] = []
    for physical_index in range(1, length + 1):
        base_x = x + 6 * (physical_index - 1)
        icon = decoder.get_icon_cell(base_x, y)
        duration_bar = decoder.get_duration_bar(base_x + 2, y)
        application_bar = decoder.get_application_bar(base_x + 2, y + 1)

        if not np.any(icon.pix_array) and not np.any(duration_bar.pix_array) and not np.any(
            application_bar.pix_array
        ):
            continue
        if icon.is_blank:
            continue
        if (
            duration_bar.classification != "PLAYER_DEBUFF_DURATION"
            or duration_bar.index != physical_index
            or application_bar.classification != "PLAYER_DEBUFF_COUNT"
            or application_bar.index != physical_index
        ):
            continue

        duration_raw_value = float(duration_bar.ratio)
        application_raw_value = float(application_bar.ratio)
        aura_groups.append({
            "type": "aura_group",
            "icon": icon_record(decoder, base_x, y, title_manager),
            "duration": {
                "raw_value": duration_raw_value,
                "result": float(100.0 * duration_raw_value),
            },
            "application": {
                "raw_value": application_raw_value,
                "minValue": 0,
                "maxValue": 4,
                "result": float(4.0 * application_raw_value),
            },
        })
    return aura_groups


def decode_party_container(
    decoder: MatrixDecoder,
    class_id: int,
    spec_id: int,
    x: int = 1,
    y: int = 8,
) -> list[dict[str, Any]]:
    """解码四个固定小队成员行及其专精 HOT 槽。"""

    spec = resolve_specialization(class_id, spec_id)
    hot_indexes = list(spec.party_hots) if spec is not None else []
    for hot_index in hot_indexes:
        if isinstance(hot_index, bool) or not isinstance(hot_index, int) or hot_index < 1:
            raise ValueError("party_hots key 必须是一基正整数")
        if hot_index > 5:
            raise ValueError(f"party_hots 槽位 {hot_index} 超过上限 5")

    status_fields: tuple[tuple[str, str, Converter], ...] = (
        ("exists", "PARTY_EXIST", boolean),
        ("target", "PARTY_TARGET", boolean),
        ("role", "PARTY_ROLE", role_name),
        ("range", "PARTY_RANGE", boolean),
        ("health", "PARTY_HEALTH", percentage),
        ("damage_absorb", "PARTY_DAMAGE_ABSORB", boolean),
        ("heal_absorb", "PARTY_HEAL_ABSORB", boolean),
        ("buff", "PARTY_BUFF", boolean),
        ("dispellable", "PARTY_DISPELLABLE", boolean),
        ("big_defensive", "PARTY_BIG_DEFENSIVE", boolean),
    )

    party: list[dict[str, Any]] = []
    for member_index in range(1, 5):
        row_y = y + member_index - 1
        exists_cell = decoder.get_cell(x, row_y)
        if not matches_cell_protocol(exists_cell, "PARTY_EXIST", member_index):
            continue
        exists = cell_record_from_cell(exists_cell, boolean)
        member: dict[str, Any] = {
            "type": "party_info",
            "index": member_index,
            "exists": exists,
        }
        if not exists["result"]:
            member.update({field: None for field, _classification, _converter in status_fields[1:]})
            member["hots"] = None
            party.append(member)
            continue

        status_cells = [
            decoder.get_cell(x + offset, row_y)
            for offset in range(1, len(status_fields))
        ]
        if any(
            not matches_cell_protocol(cell, classification, member_index)
            for cell, (_field, classification, _converter) in zip(
                status_cells, status_fields[1:]
            )
        ):
            continue
        for cell, (field, _classification, converter) in zip(
            status_cells, status_fields[1:]
        ):
            member[field] = cell_record_from_cell(cell, converter)

        hots: list[dict[str, Any]] = []
        if spec is not None:
            for hot_index in sorted(hot_indexes):
                bar = decoder.get_duration_bar(x + 10 + 4 * (hot_index - 1), row_y)
                if not np.any(bar.pix_array):
                    raw_value = 0.0
                    result = 0.0
                elif (
                    bar.classification != f"PARTY_HOT{hot_index}"
                    or bar.index != member_index
                ):
                    continue
                else:
                    raw_value = float(bar.ratio)
                    result = float(100.0 * raw_value)
                hot_info = spec.party_hots[hot_index]
                hots.append({
                    "index": hot_index,
                    "description": hot_info["description"],
                    "spellIDs": list(hot_info["spellIDs"]),
                    "duration_raw_value": raw_value,
                    "duration_result": result,
                })
        member["hots"] = hots
        party.append(member)
    return party


def decode_raid_container(
    decoder: MatrixDecoder,
    class_id: int,
    spec_id: int,
) -> list[dict[str, Any]]:
    """解码 Phantom 四段布局中的三十个团队成员块。"""

    # 先校验专精 HOT 配置，确保所有配置槽都落在上游固定的五槽范围内。
    spec = resolve_specialization(class_id, spec_id)
    hot_config = spec.party_hots if spec is not None else {}
    hot_indexes = list(hot_config)
    for hot_index in hot_indexes:
        if isinstance(hot_index, bool) or not isinstance(hot_index, int) or hot_index < 1:
            raise ValueError("party_hots key 必须是一基正整数")
        if hot_index > 5:
            raise ValueError(f"party_hots 槽位 {hot_index} 超过上限 5")

    status_fields: tuple[tuple[str, str, Converter], ...] = (
        ("exists", "PARTY_EXIST", boolean),
        ("target", "PARTY_TARGET", boolean),
        ("role", "PARTY_ROLE", role_name),
        ("range", "PARTY_RANGE", boolean),
        ("health", "PARTY_HEALTH", percentage),
        ("damage_absorb", "PARTY_DAMAGE_ABSORB", boolean),
        ("dispellable", "PARTY_DISPELLABLE", boolean),
    )

    raid: list[dict[str, Any]] = []
    # 按上游四段布局计算块起点，并使用团队编号加十作为 Cell 协议 index。
    for member_index in range(1, 31):
        if member_index <= 10:
            base_x = 31 + ((member_index - 1) % 5) * 6
            row_y = 8 if member_index <= 5 else 10
        else:
            base_x = 1 + ((member_index - 11) % 10) * 6
            row_y = 12 if member_index <= 20 else 14
        protocol_index = member_index + 10

        # 先读存在 Cell；缺席成员不读取块内其余状态或 HOT。
        exists_cell = decoder.get_cell(base_x, row_y)
        if not matches_cell_protocol(exists_cell, "PARTY_EXIST", protocol_index):
            continue
        exists = cell_record_from_cell(exists_cell, boolean)
        member: dict[str, Any] = {
            "type": "raid_info",
            "index": member_index,
            "exists": exists,
        }
        if not exists["result"]:
            member.update({
                field: None
                for field, _classification, _converter in status_fields[1:]
            })
            member["hots"] = None
            raid.append(member)
            continue

        # 基础状态按整名成员校验，任一协议异常只省略当前成员。
        status_cells = [
            decoder.get_cell(base_x + offset, row_y)
            for offset in range(1, len(status_fields) - 1)
        ]
        dispellable_cell = decoder.get_cell(base_x, row_y + 1)
        status_cells.append(dispellable_cell)
        if any(
            not matches_cell_protocol(cell, classification, protocol_index)
            for cell, (_field, classification, _converter) in zip(
                status_cells, status_fields[1:]
            )
        ):
            continue
        for cell, (field, _classification, converter) in zip(
            status_cells, status_fields[1:]
        ):
            member[field] = cell_record_from_cell(cell, converter)

        # HOT 是单 Cell 存在标记；单个 HOT 协议异常只省略当前槽位。
        hots: list[dict[str, Any]] = []
        for hot_index in sorted(hot_indexes):
            hot_cell = decoder.get_cell(base_x + hot_index, row_y + 1)
            if not matches_cell_protocol(
                hot_cell, f"PARTY_HOT{hot_index}", protocol_index
            ):
                continue
            hot_info = hot_config[hot_index]
            hots.append({
                "index": hot_index,
                "description": hot_info["description"],
                "spellIDs": list(hot_info["spellIDs"]),
                "cell": cell_record_from_cell(hot_cell, boolean),
            })
        member["hots"] = hots
        raid.append(member)
    return raid


def extract_matrix(
    matrix: np.ndarray,
    title_manager: IconTitleManager | None = None,
) -> dict[str, Any]:
    """返回内部 datetime 时间戳和当前玩家/环境完整字典。"""

    decoder = MatrixDecoder(matrix)
    player: dict[str, dict[str, Any]] = {}

    # 玩家状态字段按上游 index 1..27 顺序流水读取，布尔字段共用 boolean 映射。
    player["is_alive"] = cell_record(decoder, 1, 7, "PLAYER_STATUS", 1, boolean)
    player["class_id"] = cell_record(decoder, 2, 7, "PLAYER_STATUS", 2, class_name)
    player_class_id = scaled_integer(player["class_id"]["raw_value"], 10)
    player["specialization_index"] = cell_record(decoder, 3, 7, "PLAYER_STATUS", 3, lambda raw: specialization_name(player_class_id, raw),)
    player["role"] = cell_record(decoder, 4, 7, "PLAYER_STATUS", 4, role_name)
    player["health_pct"] = cell_record(decoder, 5, 7, "PLAYER_STATUS", 5, percentage)
    player["power_pct"] = cell_record(decoder, 6, 7, "PLAYER_STATUS", 6, percentage)
    player["in_combat"] = cell_record(decoder, 7, 7, "PLAYER_STATUS", 7, boolean)
    player["is_player_target"] = cell_record(decoder, 8, 7, "PLAYER_STATUS", 8, boolean)
    player["is_moving"] = cell_record(decoder, 9, 7, "PLAYER_STATUS", 9, boolean)
    player["in_vehicle_or_mounted"] = cell_record(decoder, 10, 7, "PLAYER_STATUS", 10, boolean)
    player["melee_enemies_count"] = cell_record(decoder, 11, 7, "PLAYER_STATUS", 11, lambda raw: scaled_integer(raw, 5),)
    player["is_targeting_spell"] = cell_record(decoder, 12, 7, "PLAYER_STATUS", 12, boolean)
    player["is_chatting"] = cell_record(decoder, 13, 7, "PLAYER_STATUS", 13, boolean)
    player["in_group"] = cell_record(decoder, 14, 7, "PLAYER_STATUS", 14, boolean)
    player["trinket_13_ready"] = cell_record(decoder, 15, 7, "PLAYER_STATUS", 15, boolean)
    player["trinket_14_ready"] = cell_record(decoder, 16, 7, "PLAYER_STATUS", 16, boolean)
    player["healthstone_ready"] = cell_record(decoder, 17, 7, "PLAYER_STATUS", 17, boolean)
    player["heal_potion_ready"] = cell_record(decoder, 18, 7, "PLAYER_STATUS", 18, boolean)
    player["cast_progress"] = cell_record(decoder, 19, 7, "PLAYER_STATUS", 19, percentage)
    player["cast_empowered"] = cell_record(decoder, 20, 7, "PLAYER_STATUS", 20, boolean)
    player["cast_target"] = cell_record(decoder, 21, 7, "PLAYER_STATUS", 21, cast_target_name)
    player["has_big_defensive"] = cell_record(decoder, 22, 7, "PLAYER_STATUS", 22, boolean)
    player["has_dispellable_debuff"] = cell_record(decoder, 23, 7, "PLAYER_STATUS", 23, boolean)
    player["hero_talent_code"] = cell_record(decoder, 24, 7, "PLAYER_STATUS", 24, lambda raw: hero_talent_name(player_class_id, raw),)
    player["damage_absorb_over_threshold"] = cell_record(decoder, 25, 7, "PLAYER_STATUS", 25, boolean)
    player["heal_absorb_over_threshold"] = cell_record(decoder, 26, 7, "PLAYER_STATUS", 26, boolean)
    player["has_party_buff"] = cell_record(decoder, 27, 7, "PLAYER_STATUS", 27, boolean)

    # 玩家施法图标使用独立纹理/边框协议和三级标题识别。
    player["cast_icon"] = icon_record(decoder, 33, 5, title_manager)

    # 环境字段按稀疏 index 布局读取，并派生团队中的玩家索引。
    environment: dict[str, dict[str, Any]] = {}
    environment["group_member_count"] = cell_record(decoder, 39, 5, "ENVIRONMENT", 1, int)
    environment["group_type"] = cell_record(decoder, 40, 5, "ENVIRONMENT", 2, group_type_name)
    environment["player_raid_index"] = derived_cell_record(environment["group_type"], raid_index)
    environment["boss_encounter_code"] = cell_record(decoder, 41, 5, "ENVIRONMENT", 3, boss_encounter_name)
    environment["instance_difficulty_id"] = cell_record(decoder, 42, 5, "ENVIRONMENT", 4, instance_difficulty_name)
    environment["combat_time_seconds"] = cell_record(decoder, 43, 5, "ENVIRONMENT", 5, int)
    environment["use_mouse"] = cell_record(decoder, 44, 5, "ENVIRONMENT", 6, boolean)
    environment["spell_queue_window_ms"] = cell_record(decoder, 45, 5, "ENVIRONMENT", 7, lambda raw: raw * 10,)
    environment["flash"] = cell_record(decoder, 57, 5, "ENVIRONMENT", 19, boolean)
    environment["delayed_update"] = cell_record(decoder, 58, 5, "ENVIRONMENT", 20, boolean)
    environment["burst_remaining_seconds"] = cell_record(decoder, 59, 5, "ENVIRONMENT", 21, lambda raw: raw / 5.0,)
    environment["enabled"] = cell_record(decoder, 60, 5, "ENVIRONMENT", 22, boolean)

    # 目标状态字段按上游 target_status index 1..11 顺序流水读取，施法图标复用 icon_record。
    target: dict[str, dict[str, Any]] = {}
    target["is_exists"] = cell_record(decoder, 33, 7, "TARGET_STATUS", 1, boolean)
    target["is_alive"] = cell_record(decoder, 34, 7, "TARGET_STATUS", 2, boolean)
    target["health_pct"] = cell_record(decoder, 35, 7, "TARGET_STATUS", 3, percentage)
    target["is_enemy"] = cell_record(decoder, 36, 7, "TARGET_STATUS", 4, boolean)
    target["can_attack"] = cell_record(decoder, 37, 7, "TARGET_STATUS", 5, boolean)
    target["in_ranged"] = cell_record(decoder, 38, 7, "TARGET_STATUS", 6, boolean)
    target["in_melee"] = cell_record(decoder, 39, 7, "TARGET_STATUS", 7, boolean)
    target["in_combat"] = cell_record(decoder, 40, 7, "TARGET_STATUS", 8, boolean)
    target["cast_progress"] = cell_record(decoder, 41, 7, "TARGET_STATUS", 9, percentage)
    target["cast_interruptible"] = cell_record(decoder, 42, 7, "TARGET_STATUS", 10, boolean)
    target["has_dispellable_buff"] = cell_record(decoder, 43, 7, "TARGET_STATUS", 11, boolean)
    target["cast_icon"] = icon_record(decoder, 35, 5, title_manager)

    # 焦点状态字段按上游 focus_target index 1..11 顺序流水读取，施法图标复用 icon_record。
    focus: dict[str, dict[str, Any]] = {}
    focus["is_exists"] = cell_record(decoder, 47, 7, "FOCUS_TARGET", 1, boolean)
    focus["is_alive"] = cell_record(decoder, 48, 7, "FOCUS_TARGET", 2, boolean)
    focus["health_pct"] = cell_record(decoder, 49, 7, "FOCUS_TARGET", 3, percentage)
    focus["is_enemy"] = cell_record(decoder, 50, 7, "FOCUS_TARGET", 4, boolean)
    focus["can_attack"] = cell_record(decoder, 51, 7, "FOCUS_TARGET", 5, boolean)
    focus["in_ranged"] = cell_record(decoder, 52, 7, "FOCUS_TARGET", 6, boolean)
    focus["in_melee"] = cell_record(decoder, 53, 7, "FOCUS_TARGET", 7, boolean)
    focus["in_combat"] = cell_record(decoder, 54, 7, "FOCUS_TARGET", 8, boolean)
    focus["cast_progress"] = cell_record(decoder, 55, 7, "FOCUS_TARGET", 9, percentage)
    focus["cast_interruptible"] = cell_record(decoder, 56, 7, "FOCUS_TARGET", 10, boolean)
    focus["has_dispellable_buff"] = cell_record(decoder, 57, 7, "FOCUS_TARGET", 11, boolean)
    focus["cast_icon"] = icon_record(decoder, 37, 5, title_manager)

    # spell 字段按 0401_spell.lua 的 26 槽位 2x2 布局解码，spec_id 来自 specialization_index。
    spec_id = scaled_integer(player["specialization_index"]["raw_value"], 10)
    spells = decode_spell_cell(decoder, 3, 1, 26, player_class_id, spec_id)
    charges = decode_spell_charge_bar(decoder, 55, 1, 6, player_class_id, spec_id)
    player_buffs = decode_aura_slot_container(
        decoder, 1, 3, 9, player_class_id, spec_id, "player_buff"
    )
    target_debuffs = decode_aura_slot_container(
        decoder, 37, 3, 6, player_class_id, spec_id, "target_debuff"
    )
    player_debuffs = decode_aura_group_container(decoder, 1, 5, 5, title_manager)
    party = decode_party_container(decoder, player_class_id, spec_id)
    raid = decode_raid_container(decoder, player_class_id, spec_id)
    assisted_combat = decode_optional_icon(
        decoder,
        31,
        5,
        title_manager,
        ("PLAYER_SPELL",),
    )
    interrupt_blacklist = decode_horizontal_icon_list(
        decoder,
        1,
        16,
        10,
        title_manager,
        ("ENEMY_SPELL_INTERRUPTIBLE",),
    )
    learn_badge_utf_title(decoder, title_manager)

    return {
        "timestamp": datetime.now(),
        "player": {"status": player},
        "environment": environment,
        "target": target,
        "focus": focus,
        "spell": spells,
        "charge": charges,
        "player_buff": player_buffs,
        "target_debuff": target_debuffs,
        "player_debuff": player_debuffs,
        "party": party,
        "raid": raid,
        "assisted_combat": assisted_combat,
        "interrupt_blacklist": interrupt_blacklist,
    }


__all__ = [
    "UPSTREAM_COMMIT",
    "decode_aura_group_container",
    "decode_aura_slot_container",
    "decode_horizontal_icon_list",
    "decode_optional_icon",
    "decode_party_container",
    "decode_raid_container",
    "decode_spell_cell",
    "decode_spell_charge_bar",
    "extract_matrix",
    "learn_badge_utf_title",
]
