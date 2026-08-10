"""摘要：构造绑定当前 Phantom commit 的纯内存 Matrix 测试帧。

描述：按一基 Matrix 坐标写入状态单元、小队/团队状态与 HOT、技能格、充能条、固定 AuraSlot、
动态 AuraGroup、辅助图标和 UTF 标题，为解码器与提取器测试提供可精确控制的协议输入。
主要变量信息：matrix 表示 RGB 测试帧；x、y 和 index 均遵循上游一基坐标与索引约定。
修改记录：2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 需求新增 AuraSlot fixture。
2026-08-02，根据 Phase 2.9 Matrix Decoder 需求新增动态 AuraGroup fixture。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 需求新增小队 fixture。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 需求新增团队 fixture。
2026-08-02，根据 Phase 2.12 Matrix Decoder 需求新增辅助图标与 UTF fixture。
"""

from __future__ import annotations

import numpy as np

from copilot.decoder.matrix import EXPECTED_SHAPE


def set_cell(
    matrix: np.ndarray,
    x: int,
    y: int,
    color: tuple[int, int, int],
) -> None:
    left = (x - 1) * 4
    top = (y - 1) * 4
    matrix[top : top + 4, left : left + 4] = color


def set_icon_cell(
    matrix: np.ndarray,
    x: int,
    y: int,
    center: np.ndarray,
    border_color: tuple[int, int, int],
) -> None:
    if center.shape != (6, 6, 3) or center.dtype != np.uint8:
        raise ValueError("center 必须是 6x6x3 uint8 RGB 数组")
    top = (y - 1) * 4
    left = (x - 1) * 4
    matrix[top : top + 8, left : left + 8] = border_color
    matrix[top + 1 : top + 7, left + 1 : left + 7] = center


def set_utf_text(
    matrix: np.ndarray,
    text: str,
    x: int = 43,
    y: int = 16,
    length: int = 16,
) -> None:
    characters = list(text)
    if len(characters) > length:
        raise ValueError("UTF 文本字符数超过 Cell 容量")
    for offset in range(length):
        if offset >= len(characters):
            color = (0, 0, 0)
        else:
            encoded = list(characters[offset].encode("utf-8"))
            if len(encoded) > 3:
                raise ValueError("单个 UTF 字符不能超过三个字节")
            encoded.extend([0] * (3 - len(encoded)))
            color = encoded[0], encoded[1], encoded[2]
        set_cell(matrix, x + offset, y, color)


def set_assisted_combat_icon(
    matrix: np.ndarray,
    center: np.ndarray,
    border_color: tuple[int, int, int] = (64, 158, 210),
) -> None:
    set_icon_cell(matrix, 31, 5, center, border_color)


def set_interrupt_blacklist_icon(
    matrix: np.ndarray,
    slot_index: int,
    center: np.ndarray,
    border_color: tuple[int, int, int] = (255, 255, 60),
) -> None:
    if slot_index < 1 or slot_index > 10:
        raise ValueError("打断黑名单槽位必须在 1..10")
    set_icon_cell(matrix, 1 + 2 * (slot_index - 1), 16, center, border_color)


def set_badge_utf_output(
    matrix: np.ndarray,
    center: np.ndarray,
    title: str,
    border_color: tuple[int, int, int] = (64, 158, 210),
) -> None:
    set_icon_cell(matrix, 41, 16, center, border_color)
    set_utf_text(matrix, f"*#{title}*#")


def build_valid_matrix() -> np.ndarray:
    matrix = np.zeros(EXPECTED_SHAPE, dtype=np.uint8)
    deep = (15, 25, 20)
    light = (25, 15, 20)
    for x, y in [(1, 1), (2, 2), (59, 16), (60, 17)]:
        set_cell(matrix, x, y, deep)
    for x, y in [(1, 2), (2, 1), (59, 17), (60, 16)]:
        set_cell(matrix, x, y, light)
    # 玩家状态头行写在 (1..27, 7)，R 通道为 PLAYER_STATUS(5)，便于 extractor 校验。
    for index in range(1, 28):
        set_cell(matrix, index, 7, (5, index, 0))
    # 目标状态头行按 0201..0211 写在 (33..43, 7)，R 通道为 TARGET_STATUS(10)。
    for index in range(1, 12):
        set_cell(matrix, 32 + index, 7, (10, index, 0))
    # 焦点状态头行按 0301..0311 写在 (47..57, 7)，R 通道为 FOCUS_TARGET(15)。
    for index in range(1, 12):
        set_cell(matrix, 46 + index, 7, (15, index, 0))
    # 默认四名成员均不存在；exists Cell 仍保留当前分类与成员 index。
    for member_index in range(1, 5):
        set_cell(matrix, 1, 7 + member_index, (100, member_index, 0))
    # 默认三十名团队成员均不存在；团队协议 index 为成员编号加 10。
    for member_index in range(1, 31):
        base_x, row_y = raid_member_origin(member_index)
        set_cell(matrix, base_x, row_y, (100, member_index + 10, 0))
    environment_positions = {
        1: 39,
        2: 40,
        3: 41,
        4: 42,
        5: 43,
        6: 44,
        7: 45,
        19: 57,
        20: 58,
        21: 59,
        22: 60,
    }
    for index, x in environment_positions.items():
        set_cell(matrix, x, 5, (50, index, 0))
    # spell 头行按 0401_spell 写在 (3..54, 1..2)，每槽位 2x2，R 通道为对应 SPELL_* 分类。
    for index in range(1, 27):
        base_x = 2 * index + 1
        set_cell(matrix, base_x, 1, (65, index, 0))
        set_cell(matrix, base_x + 1, 1, (70, index, 0))
        set_cell(matrix, base_x, 2, (75, index, 0))
        set_cell(matrix, base_x + 1, 2, (80, index, 0))
    return matrix


def set_player_value(matrix: np.ndarray, index: int, value: int) -> None:
    set_cell(matrix, index, 7, (5, index, value))


def set_environment_value(matrix: np.ndarray, index: int, value: int) -> None:
    positions = {1: 39, 2: 40, 3: 41, 4: 42, 5: 43, 6: 44, 7: 45, 19: 57, 20: 58, 21: 59, 22: 60}
    set_cell(matrix, positions[index], 5, (50, index, value))


def set_target_value(matrix: np.ndarray, index: int, value: int) -> None:
    set_cell(matrix, 32 + index, 7, (10, index, value))


def set_focus_value(matrix: np.ndarray, index: int, value: int) -> None:
    set_cell(matrix, 46 + index, 7, (15, index, value))


def set_party_member(
    matrix: np.ndarray,
    member_index: int,
    *,
    exists: int,
    target: int,
    role: int,
    in_range: int,
    health: int,
    damage_absorb: int,
    heal_absorb: int,
    buff: int,
    dispellable: int,
    big_defensive: int,
) -> None:
    """设置一个成员的十项 party 状态 Cell。"""

    if member_index < 1 or member_index > 4:
        raise ValueError("member_index 必须在 1..4")
    classifications = (100, 105, 110, 115, 120, 125, 130, 135, 140, 145)
    values = (
        exists,
        target,
        role,
        in_range,
        health,
        damage_absorb,
        heal_absorb,
        buff,
        dispellable,
        big_defensive,
    )
    for x, (classification, value) in enumerate(zip(classifications, values), start=1):
        set_cell(matrix, x, 7 + member_index, (classification, member_index, value))


def set_party_hot_bar(
    matrix: np.ndarray,
    member_index: int,
    hot_index: int,
    filled_steps: int,
    classification: int | None = None,
    encoded_index: int | None = None,
) -> None:
    """设置一个非黑 party HOT DurationBar；不调用即保留全黑槽。"""

    if member_index < 1 or member_index > 4:
        raise ValueError("member_index 必须在 1..4")
    if hot_index < 1 or hot_index > 5:
        raise ValueError("hot_index 必须在 1..5")
    if filled_steps < 0 or filled_steps > 16:
        raise ValueError("filled_steps 必须在 0..16")
    left = (11 + 4 * (hot_index - 1) - 1) * 4
    top = (7 + member_index - 1) * 4
    matrix[top : top + 4, left : left + 16] = (
        145 + 5 * hot_index if classification is None else classification,
        member_index if encoded_index is None else encoded_index,
        0,
    )
    if filled_steps:
        matrix[top : top + 4, left : left + filled_steps, 2] = 255


def raid_member_origin(member_index: int) -> tuple[int, int]:
    """返回当前 Phantom 四段团队布局中的成员块起点。"""

    if member_index < 1 or member_index > 30:
        raise ValueError("member_index 必须在 1..30")
    if member_index <= 10:
        return (
            31 + ((member_index - 1) % 5) * 6,
            8 if member_index <= 5 else 10,
        )
    return (
        1 + ((member_index - 11) % 10) * 6,
        12 if member_index <= 20 else 14,
    )


def set_raid_member(
    matrix: np.ndarray,
    member_index: int,
    *,
    exists: int,
    target: int,
    role: int,
    in_range: int,
    health: int,
    damage_absorb: int,
    dispellable: int,
) -> None:
    """设置一个团队成员的七项状态 Cell。"""

    base_x, row_y = raid_member_origin(member_index)
    protocol_index = member_index + 10
    first_row = (
        (100, exists),
        (105, target),
        (110, role),
        (115, in_range),
        (120, health),
        (125, damage_absorb),
    )
    for offset, (classification, value) in enumerate(first_row):
        set_cell(
            matrix,
            base_x + offset,
            row_y,
            (classification, protocol_index, value),
        )
    set_cell(matrix, base_x, row_y + 1, (140, protocol_index, dispellable))


def set_raid_hot_cell(
    matrix: np.ndarray,
    member_index: int,
    hot_index: int,
    value: int,
    classification: int | None = None,
    encoded_index: int | None = None,
) -> None:
    """设置一个团队 HOT 存在 Cell。"""

    base_x, row_y = raid_member_origin(member_index)
    if hot_index < 1 or hot_index > 5:
        raise ValueError("hot_index 必须在 1..5")
    set_cell(
        matrix,
        base_x + hot_index,
        row_y + 1,
        (
            145 + 5 * hot_index if classification is None else classification,
            member_index + 10 if encoded_index is None else encoded_index,
            value,
        ),
    )


def set_spell_cell(
    matrix: np.ndarray,
    index: int,
    cooldown: int = 0,
    usable: int = 0,
    overlayed: int = 0,
    known: int = 0,
) -> None:
    """设置 spell 槽位 index 的 4 个 cell 值（cooldown/usable/overlayed/known）。"""
    base_x = 2 * index + 1
    set_cell(matrix, base_x, 1, (65, index, cooldown))
    set_cell(matrix, base_x + 1, 1, (70, index, usable))
    set_cell(matrix, base_x, 2, (75, index, overlayed))
    set_cell(matrix, base_x + 1, 2, (80, index, known))


def set_charge_bar(
    matrix: np.ndarray,
    index: int,
    filled_steps: int,
    classification: int = 85,
    encoded_index: int | None = None,
) -> None:
    """设置 charge 槽位的垂直 1x2 Cell Bar 和底部填充步数。"""

    if filled_steps < 0 or filled_steps > 8:
        raise ValueError("filled_steps 必须在 0..8")
    left = (55 + index - 2) * 4
    top = 0
    matrix[top : top + 8, left : left + 4] = (
        classification,
        index if encoded_index is None else encoded_index,
        0,
    )
    if filled_steps:
        matrix[top + 8 - filled_steps : top + 8, left : left + 4, 2] = 255


def set_aura_slot(
    matrix: np.ndarray,
    x: int,
    y: int,
    index: int,
    duration_filled_steps: int,
    application_filled_steps: int,
    duration_classification: int,
    application_classification: int,
    duration_encoded_index: int | None = None,
    application_encoded_index: int | None = None,
) -> None:
    """设置一个固定 AuraSlot 的水平 Duration/Application Bar。"""

    for filled_steps in (duration_filled_steps, application_filled_steps):
        if filled_steps < 0 or filled_steps > 16:
            raise ValueError("filled_steps 必须在 0..16")
    left = (x + 4 * (index - 1) - 1) * 4
    top = (y - 1) * 4
    duration_index = index if duration_encoded_index is None else duration_encoded_index
    application_index = (
        index if application_encoded_index is None else application_encoded_index
    )
    matrix[top : top + 4, left : left + 16] = (
        duration_classification,
        duration_index,
        0,
    )
    matrix[top + 4 : top + 8, left : left + 16] = (
        application_classification,
        application_index,
        0,
    )
    if duration_filled_steps:
        matrix[
            top : top + 4,
            left : left + duration_filled_steps,
            2,
        ] = 255
    if application_filled_steps:
        matrix[
            top + 4 : top + 8,
            left : left + application_filled_steps,
            2,
        ] = 255


def set_aura_group(
    matrix: np.ndarray,
    physical_index: int,
    center: np.ndarray | None,
    duration_filled_steps: int,
    application_filled_steps: int,
    border_color: tuple[int, int, int] = (255, 60, 60),
    duration_classification: int = 40,
    application_classification: int = 45,
    duration_encoded_index: int | None = None,
    application_encoded_index: int | None = None,
) -> None:
    """设置玩家减益容器中的一个动态 6x2 AuraGroup 物理项。"""

    for filled_steps in (duration_filled_steps, application_filled_steps):
        if filled_steps < 0 or filled_steps > 16:
            raise ValueError("filled_steps 必须在 0..16")
    base_x = 1 + 6 * (physical_index - 1)
    icon_left = (base_x - 1) * 4
    top = (5 - 1) * 4
    matrix[top : top + 8, icon_left : icon_left + 8] = border_color
    matrix[top + 1 : top + 7, icon_left + 1 : icon_left + 7] = 0
    if center is not None:
        if center.shape != (6, 6, 3) or center.dtype != np.uint8:
            raise ValueError("center 必须是 6x6x3 uint8 RGB 数组")
        matrix[top + 1 : top + 7, icon_left + 1 : icon_left + 7] = center

    bar_left = icon_left + 8
    duration_index = (
        physical_index
        if duration_encoded_index is None
        else duration_encoded_index
    )
    application_index = (
        physical_index
        if application_encoded_index is None
        else application_encoded_index
    )
    matrix[top : top + 4, bar_left : bar_left + 16] = (
        duration_classification,
        duration_index,
        0,
    )
    matrix[top + 4 : top + 8, bar_left : bar_left + 16] = (
        application_classification,
        application_index,
        0,
    )
    if duration_filled_steps:
        matrix[top : top + 4, bar_left : bar_left + duration_filled_steps, 2] = 255
    if application_filled_steps:
        matrix[
            top + 4 : top + 8,
            bar_left : bar_left + application_filled_steps,
            2,
        ] = 255


def set_player_cast_icon(
    matrix: np.ndarray,
    center: np.ndarray,
    border_color: tuple[int, int, int] = (64, 158, 210),
) -> None:
    top = (5 - 1) * 4
    left = (33 - 1) * 4
    matrix[top : top + 8, left : left + 8] = border_color
    matrix[top + 1 : top + 7, left + 1 : left + 7] = center


def set_target_cast_icon(
    matrix: np.ndarray,
    center: np.ndarray,
    border_color: tuple[int, int, int] = (255, 255, 60),
) -> None:
    top = (5 - 1) * 4
    left = (35 - 1) * 4
    matrix[top : top + 8, left : left + 8] = border_color
    matrix[top + 1 : top + 7, left + 1 : left + 7] = center


def set_focus_cast_icon(
    matrix: np.ndarray,
    center: np.ndarray,
    border_color: tuple[int, int, int] = (255, 255, 60),
) -> None:
    top = (5 - 1) * 4
    left = (37 - 1) * 4
    matrix[top : top + 8, left : left + 8] = border_color
    matrix[top + 1 : top + 7, left + 1 : left + 7] = center
