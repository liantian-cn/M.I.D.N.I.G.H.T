"""摘要：验证当前状态、环境、队伍、技能、充能、Aura 与辅助图标的业务映射。

描述：通过纯内存 Matrix、专精 mock 和图标标题管理器覆盖整帧提取流程，重点验证固定
Aura 的配置槽位和动态 AuraGroup 的图标、活动值、黑项与单项损坏协议边界。
主要变量信息：matrix 表示 RGB 测试帧；spec 表示专精配置；aura_list 表示按配置槽位索引
升序返回的 Aura 解码结果。
修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-01，根据 Phase 2.6 Target and Focus Matrix Decoder 冻结计划新增 target/focus 覆盖。
2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划新增 spell 覆盖。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划新增 charge 覆盖。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划新增固定 Aura 覆盖。
2026-08-02，根据 Aura Duration Direct Ratio 冻结计划更新持续时间直接比例映射覆盖。
2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划新增动态 AuraGroup 覆盖。
2026-08-02，根据槽位解码容错计划覆盖单槽协议异常跳过与后续槽继续解码。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划新增小队状态与 HOT 覆盖。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 冻结计划新增团队状态与 HOT 覆盖。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划新增辅助图标与 UTF 学习覆盖。
"""

from __future__ import annotations

from datetime import datetime
import unittest
from unittest.mock import Mock, call, patch

import numpy as np

from copilot.decoder.extractor import (
    decode_aura_group_container,
    decode_aura_slot_container,
    decode_horizontal_icon_list,
    decode_optional_icon,
    decode_party_container,
    decode_raid_container,
    decode_spell_cell,
    decode_spell_charge_bar,
    extract_matrix,
    learn_badge_utf_title,
)
from copilot.decoder.matrix import MatrixDecoder
from copilot.decoder.title_manager import icon_hash
from copilot.decoder.value_mapping import specialization_name
from tests.matrix_fixture import (
    build_valid_matrix,
    set_assisted_combat_icon,
    set_aura_slot,
    set_aura_group,
    set_charge_bar,
    set_environment_value,
    set_focus_cast_icon,
    set_focus_value,
    set_player_cast_icon,
    set_player_value,
    set_party_hot_bar,
    set_party_member,
    raid_member_origin,
    set_raid_hot_cell,
    set_raid_member,
    set_badge_utf_output,
    set_cell,
    set_interrupt_blacklist_icon,
    set_spell_cell,
    set_target_cast_icon,
    set_target_value,
    set_utf_text,
)


class FakeTitleManager:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []
        self.learning_calls: list[tuple[str, str, str]] = []

    def resolve(
        self,
        _valid_array: np.ndarray,
        category: str,
        expected_hash: str,
    ) -> str:
        self.calls.append((category, expected_hash))
        return "Known Spell"

    def add_record_if_absent(
        self,
        _valid_array: np.ndarray,
        category: str,
        title: str,
        expected_hash: str,
    ) -> bool:
        self.learning_calls.append((category, title, expected_hash))
        return True


class HashTitleManager(FakeTitleManager):
    def resolve(
        self,
        _valid_array: np.ndarray,
        category: str,
        expected_hash: str,
    ) -> str:
        self.calls.append((category, expected_hash))
        return expected_hash


EXPECTED_RAID_ORIGINS = [
    (31, 8), (37, 8), (43, 8), (49, 8), (55, 8),
    (31, 10), (37, 10), (43, 10), (49, 10), (55, 10),
    (1, 12), (7, 12), (13, 12), (19, 12), (25, 12),
    (31, 12), (37, 12), (43, 12), (49, 12), (55, 12),
    (1, 14), (7, 14), (13, 14), (19, 14), (25, 14),
    (31, 14), (37, 14), (43, 14), (49, 14), (55, 14),
]


class ExtractorTests(unittest.TestCase):
    def build_populated_matrix(self) -> np.ndarray:
        matrix = build_valid_matrix()
        values = {
            1: 255,
            2: 10,
            3: 20,
            4: 10,
            5: 128,
            6: 64,
            7: 255,
            10: 255,
            11: 15,
            19: 127,
            20: 255,
            21: 7,
            24: 1,
            25: 255,
            27: 255,
        }
        for index, value in values.items():
            set_player_value(matrix, index, value)
        environment_values = {
            1: 5,
            2: 3,
            3: 51,
            4: 8,
            5: 123,
            6: 255,
            7: 40,
            19: 255,
            20: 255,
            21: 255,
            22: 255,
        }
        for index, value in environment_values.items():
            set_environment_value(matrix, index, value)
        center = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        set_player_cast_icon(matrix, center)
        return matrix

    def test_extracts_all_current_player_and_environment_fields(self) -> None:
        manager = FakeTitleManager()
        result = extract_matrix(self.build_populated_matrix(), manager)  # type: ignore[arg-type]
        self.assertIsInstance(result["timestamp"], datetime)
        player = result["player"]["status"]
        environment = result["environment"]
        self.assertEqual(len(player), 28)
        self.assertEqual(len(environment), 12)
        self.assertEqual(player["is_alive"]["result"], True)
        self.assertEqual(player["class_id"]["result"], "WARRIOR")
        self.assertEqual(player["specialization_index"]["result"], "FURY")
        self.assertEqual(player["role"]["result"], "TANK")
        self.assertAlmostEqual(player["health_pct"]["result"], 128 / 255 * 100)
        self.assertEqual(player["melee_enemies_count"]["result"], 3)
        self.assertEqual(player["cast_target"]["result"], "raid2")
        self.assertEqual(player["hero_talent_code"]["result"], "COLOSSUS")
        self.assertEqual(player["cast_icon"]["type"], "IconCell")
        self.assertEqual(player["cast_icon"]["icon_category"], "PLAYER_SPELL")
        self.assertEqual(player["cast_icon"]["result"], "Known Spell")
        self.assertEqual(environment["group_type"]["result"], "raid")
        self.assertEqual(environment["player_raid_index"]["result"], 3)
        self.assertEqual(
            environment["boss_encounter_code"]["result"],
            "DUNGEON_ENCOUNTER_51",
        )
        self.assertEqual(environment["instance_difficulty_id"]["result"], "MYTHIC_KEYSTONE")
        self.assertEqual(environment["spell_queue_window_ms"]["result"], 400)
        self.assertEqual(environment["burst_remaining_seconds"]["result"], 51.0)
        self.assertEqual(environment["enabled"]["result"], True)
        self.assertEqual(manager.calls[0][0], "PLAYER_SPELL")

        expected_player_results = {
            "is_alive": True,
            "class_id": "WARRIOR",
            "specialization_index": "FURY",
            "role": "TANK",
            "health_pct": 128 / 255 * 100,
            "power_pct": 64 / 255 * 100,
            "in_combat": True,
            "is_player_target": False,
            "is_moving": False,
            "in_vehicle_or_mounted": True,
            "melee_enemies_count": 3,
            "is_targeting_spell": False,
            "is_chatting": False,
            "in_group": False,
            "trinket_13_ready": False,
            "trinket_14_ready": False,
            "healthstone_ready": False,
            "heal_potion_ready": False,
            "cast_progress": 127 / 255 * 100,
            "cast_empowered": True,
            "cast_target": "raid2",
            "has_big_defensive": False,
            "has_dispellable_debuff": False,
            "hero_talent_code": "COLOSSUS",
            "damage_absorb_over_threshold": True,
            "heal_absorb_over_threshold": False,
            "has_party_buff": True,
        }
        for field_name, expected_result in expected_player_results.items():
            with self.subTest(field=field_name):
                actual = player[field_name]["result"]
                expected_index = player[field_name]["index"]
                expected_raw = {
                    1: 255,
                    2: 10,
                    3: 20,
                    4: 10,
                    5: 128,
                    6: 64,
                    7: 255,
                    10: 255,
                    11: 15,
                    19: 127,
                    20: 255,
                    21: 7,
                    24: 1,
                    25: 255,
                    27: 255,
                }.get(expected_index, 0)
                self.assertEqual(player[field_name]["raw_value"], expected_raw)
                if isinstance(expected_result, float):
                    self.assertAlmostEqual(actual, expected_result)
                else:
                    self.assertEqual(actual, expected_result)

    def test_decodes_optional_assisted_combat_and_sparse_interrupt_list(self) -> None:
        matrix = build_valid_matrix()
        assisted_center = np.full((6, 6, 3), 31, dtype=np.uint8)
        first_center = np.full((6, 6, 3), 32, dtype=np.uint8)
        third_center = np.full((6, 6, 3), 33, dtype=np.uint8)
        set_assisted_combat_icon(matrix, assisted_center)
        set_interrupt_blacklist_icon(matrix, 1, first_center)
        set_interrupt_blacklist_icon(matrix, 3, third_center)
        manager = FakeTitleManager()
        decoder = MatrixDecoder(matrix)

        assisted = decode_optional_icon(
            decoder,
            31,
            5,
            manager,  # type: ignore[arg-type]
            ("PLAYER_SPELL",),
        )
        blacklist = decode_horizontal_icon_list(
            decoder,
            1,
            16,
            10,
            manager,  # type: ignore[arg-type]
            ("ENEMY_SPELL_INTERRUPTIBLE",),
        )

        assert assisted is not None
        self.assertEqual(assisted["result"], "Known Spell")
        self.assertEqual(len(blacklist), 2)
        self.assertEqual(
            [record["result"] for record in blacklist],
            ["Known Spell", "Known Spell"],
        )
        self.assertEqual(
            [record["icon_hash"] for record in blacklist],
            [icon_hash(first_center), icon_hash(third_center)],
        )
        self.assertIsNone(
            decode_optional_icon(
                MatrixDecoder(build_valid_matrix()),
                31,
                5,
                manager,  # type: ignore[arg-type]
                ("PLAYER_SPELL",),
            )
        )
        self.assertEqual(
            decode_horizontal_icon_list(
                MatrixDecoder(build_valid_matrix()),
                1,
                16,
                10,
                manager,  # type: ignore[arg-type]
                ("ENEMY_SPELL_INTERRUPTIBLE",),
            ),
            [],
        )

    def test_auxiliary_icon_category_mismatch_is_skipped(self) -> None:
        matrix = build_valid_matrix()
        wrong_assisted = np.full((6, 6, 3), 90, dtype=np.uint8)
        wrong_interrupt = np.full((6, 6, 3), 91, dtype=np.uint8)
        valid_interrupt = np.full((6, 6, 3), 92, dtype=np.uint8)
        unknown_interrupt = np.full((6, 6, 3), 93, dtype=np.uint8)
        set_assisted_combat_icon(matrix, wrong_assisted, (255, 255, 60))
        set_interrupt_blacklist_icon(matrix, 1, wrong_interrupt, (64, 158, 210))
        set_interrupt_blacklist_icon(matrix, 2, valid_interrupt)
        set_interrupt_blacklist_icon(matrix, 3, unknown_interrupt, (1, 2, 3))
        decoder = MatrixDecoder(matrix)

        assisted = decode_optional_icon(
            decoder,
            31,
            5,
            None,
            ("PLAYER_SPELL",),
        )
        records = decode_horizontal_icon_list(
            decoder,
            1,
            16,
            10,
            None,
            ("ENEMY_SPELL_INTERRUPTIBLE",),
        )

        self.assertIsNone(assisted)
        self.assertEqual(len(records), 2)
        self.assertEqual(
            [record["icon_hash"] for record in records],
            [icon_hash(valid_interrupt), icon_hash(unknown_interrupt)],
        )
        self.assertEqual(records[1]["result"], records[1]["icon_hash"])

    def test_badge_utf_learning_requires_valid_icon_category_and_wrapper(self) -> None:
        matrix = build_valid_matrix()
        center = np.full((6, 6, 3), 63, dtype=np.uint8)
        set_badge_utf_output(matrix, center, "自动技能")
        manager = FakeTitleManager()

        self.assertTrue(learn_badge_utf_title(MatrixDecoder(matrix), manager))  # type: ignore[arg-type]
        self.assertEqual(manager.learning_calls[0][0:2], ("PLAYER_SPELL", "自动技能"))

        set_utf_text(matrix, "abcdefghijklmnop")
        self.assertFalse(learn_badge_utf_title(MatrixDecoder(matrix), manager))  # type: ignore[arg-type]
        self.assertEqual(len(manager.learning_calls), 1)

        set_badge_utf_output(matrix, center, "错误分类", (255, 60, 60))
        self.assertFalse(learn_badge_utf_title(MatrixDecoder(matrix), manager))  # type: ignore[arg-type]
        self.assertEqual(len(manager.learning_calls), 1)

    def test_extract_matrix_includes_auxiliary_fields(self) -> None:
        matrix = build_valid_matrix()
        set_assisted_combat_icon(matrix, np.full((6, 6, 3), 41, dtype=np.uint8))
        set_interrupt_blacklist_icon(matrix, 10, np.full((6, 6, 3), 42, dtype=np.uint8))

        result = extract_matrix(matrix)

        self.assertIsNotNone(result["assisted_combat"])
        self.assertEqual(len(result["interrupt_blacklist"]), 1)

    def test_cell_envelopes_keep_protocol_metadata(self) -> None:
        result = extract_matrix(self.build_populated_matrix())
        record = result["player"]["status"]["health_pct"]
        self.assertEqual(
            set(record),
            {"type", "classification", "index", "raw_value", "result"},
        )
        self.assertEqual(record["type"], "Cell")
        self.assertEqual(record["classification"], "PLAYER_STATUS")
        self.assertEqual(record["index"], 5)
        self.assertEqual(record["raw_value"], 128)

    def test_blank_icon_returns_none(self) -> None:
        result = extract_matrix(build_valid_matrix())
        icon = result["player"]["status"]["cast_icon"]
        self.assertIsNone(icon["icon_hash"])
        self.assertIsNone(icon["icon_category"])
        self.assertIsNone(icon["result"])

    def test_protocol_mismatch_fails_whole_frame(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 5, 100)
        top = (7 - 1) * 4
        left = (5 - 1) * 4
        matrix[top : top + 4, left : left + 4, 0] = 50
        with self.assertRaises(ValueError):
            extract_matrix(matrix)

    def test_unknown_icon_border_returns_hash_without_failing_frame(self) -> None:
        matrix = build_valid_matrix()
        center = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        set_player_cast_icon(matrix, center, (1, 2, 3))
        result = extract_matrix(matrix)
        icon = result["player"]["status"]["cast_icon"]
        self.assertIsNotNone(icon["icon_hash"])
        self.assertIsNone(icon["icon_category"])
        self.assertEqual(icon["result"], icon["icon_hash"])
        self.assertIn("is_alive", result["player"]["status"])

    def test_every_current_player_cell_keeps_its_upstream_index(self) -> None:
        player = extract_matrix(build_valid_matrix())["player"]["status"]
        expected_indices = {
            "is_alive": 1,
            "class_id": 2,
            "specialization_index": 3,
            "role": 4,
            "health_pct": 5,
            "power_pct": 6,
            "in_combat": 7,
            "is_player_target": 8,
            "is_moving": 9,
            "in_vehicle_or_mounted": 10,
            "melee_enemies_count": 11,
            "is_targeting_spell": 12,
            "is_chatting": 13,
            "in_group": 14,
            "trinket_13_ready": 15,
            "trinket_14_ready": 16,
            "healthstone_ready": 17,
            "heal_potion_ready": 18,
            "cast_progress": 19,
            "cast_empowered": 20,
            "cast_target": 21,
            "has_big_defensive": 22,
            "has_dispellable_debuff": 23,
            "hero_talent_code": 24,
            "damage_absorb_over_threshold": 25,
            "heal_absorb_over_threshold": 26,
            "has_party_buff": 27,
        }
        self.assertEqual(set(player), set(expected_indices) | {"cast_icon"})
        for field_name, expected_index in expected_indices.items():
            with self.subTest(field=field_name):
                self.assertEqual(player[field_name]["classification"], "PLAYER_STATUS")
                self.assertEqual(player[field_name]["index"], expected_index)

    def test_all_current_class_specializations_have_readable_names(self) -> None:
        expected = {
            1: ("ARMS", "FURY", "PROTECTION"),
            2: ("HOLY", "PROTECTION", "RETRIBUTION"),
            3: ("BEAST_MASTERY", "MARKSMANSHIP", "SURVIVAL"),
            4: ("ASSASSINATION", "OUTLAW", "SUBTLETY"),
            5: ("DISCIPLINE", "HOLY", "SHADOW"),
            6: ("BLOOD", "FROST", "UNHOLY"),
            7: ("ELEMENTAL", "ENHANCEMENT", "RESTORATION"),
            8: ("ARCANE", "FIRE", "FROST"),
            9: ("AFFLICTION", "DEMONOLOGY", "DESTRUCTION"),
            10: ("BREWMASTER", "MISTWEAVER", "WINDWALKER"),
            11: ("BALANCE", "FERAL", "GUARDIAN", "RESTORATION"),
            12: ("HAVOC", "VENGEANCE", "DEVOURER"),
            13: ("DEVASTATION", "PRESERVATION", "AUGMENTATION"),
        }
        for class_id, names in expected.items():
            for specialization_index, name in enumerate(names, start=1):
                with self.subTest(class_id=class_id, index=specialization_index):
                    self.assertEqual(
                        specialization_name(class_id, specialization_index * 10),
                        name,
                    )

    def _populate_target_values(self, matrix: np.ndarray) -> dict[int, int]:
        values = {
            1: 255,
            2: 255,
            3: 200,
            4: 255,
            5: 255,
            6: 255,
            7: 100,
            8: 255,
            9: 127,
            10: 0,
            11: 255,
        }
        for index, value in values.items():
            set_target_value(matrix, index, value)
        return values

    def _populate_focus_values(self, matrix: np.ndarray) -> dict[int, int]:
        values = {
            1: 255,
            2: 0,
            3: 64,
            4: 0,
            5: 0,
            6: 0,
            7: 255,
            8: 0,
            9: 50,
            10: 255,
            11: 0,
        }
        for index, value in values.items():
            set_focus_value(matrix, index, value)
        return values

    def test_extracts_all_current_target_and_focus_fields(self) -> None:
        manager = FakeTitleManager()
        matrix = build_valid_matrix()
        target_values = self._populate_target_values(matrix)
        focus_values = self._populate_focus_values(matrix)
        set_target_cast_icon(matrix, np.full((6, 6, 3), 88, dtype=np.uint8))
        set_focus_cast_icon(matrix, np.full((6, 6, 3), 99, dtype=np.uint8))
        result = extract_matrix(matrix, manager)  # type: ignore[arg-type]

        target = result["target"]
        focus = result["focus"]
        self.assertEqual(len(target), 12)
        self.assertEqual(len(focus), 12)

        expected_target_results = {
            "is_exists": True,
            "is_alive": True,
            "health_pct": 200 / 255 * 100,
            "is_enemy": True,
            "can_attack": True,
            "in_ranged": True,
            "in_melee": True,
            "in_combat": True,
            "cast_progress": 127 / 255 * 100,
            "cast_interruptible": False,
            "has_dispellable_buff": True,
        }
        for field_name, expected_result in expected_target_results.items():
            with self.subTest(unit="target", field=field_name):
                envelope = target[field_name]
                self.assertEqual(envelope["classification"], "TARGET_STATUS")
                self.assertEqual(envelope["raw_value"], target_values[envelope["index"]])
                if isinstance(expected_result, float):
                    self.assertAlmostEqual(envelope["result"], expected_result)
                else:
                    self.assertEqual(envelope["result"], expected_result)

        expected_focus_results = {
            "is_exists": True,
            "is_alive": False,
            "health_pct": 64 / 255 * 100,
            "is_enemy": False,
            "can_attack": False,
            "in_ranged": False,
            "in_melee": True,
            "in_combat": False,
            "cast_progress": 50 / 255 * 100,
            "cast_interruptible": True,
            "has_dispellable_buff": False,
        }
        for field_name, expected_result in expected_focus_results.items():
            with self.subTest(unit="focus", field=field_name):
                envelope = focus[field_name]
                self.assertEqual(envelope["classification"], "FOCUS_TARGET")
                self.assertEqual(envelope["raw_value"], focus_values[envelope["index"]])
                if isinstance(expected_result, float):
                    self.assertAlmostEqual(envelope["result"], expected_result)
                else:
                    self.assertEqual(envelope["result"], expected_result)

        for cast_icon, expected_category in (
            (target["cast_icon"], "ENEMY_SPELL_INTERRUPTIBLE"),
            (focus["cast_icon"], "ENEMY_SPELL_INTERRUPTIBLE"),
        ):
            self.assertEqual(cast_icon["type"], "IconCell")
            self.assertEqual(cast_icon["icon_category"], expected_category)
            self.assertEqual(cast_icon["result"], "Known Spell")
        # 该用例未播玩家施法图标（默认 blank），故 manager.calls 仅包含 target/focus 两次识别。
        self.assertEqual(len(manager.calls), 2)
        self.assertEqual(manager.calls[0][0], "ENEMY_SPELL_INTERRUPTIBLE")
        self.assertEqual(manager.calls[1][0], "ENEMY_SPELL_INTERRUPTIBLE")

    def test_blank_target_and_focus_icons_return_none(self) -> None:
        result = extract_matrix(build_valid_matrix())
        for unit_name in ("target", "focus"):
            with self.subTest(unit=unit_name):
                icon = result[unit_name]["cast_icon"]
                self.assertIsNone(icon["icon_hash"])
                self.assertIsNone(icon["icon_category"])
                self.assertIsNone(icon["result"])

    def test_every_current_target_and_focus_cell_keeps_its_upstream_index(self) -> None:
        result = extract_matrix(build_valid_matrix())
        expected_indices = {
            "is_exists": 1,
            "is_alive": 2,
            "health_pct": 3,
            "is_enemy": 4,
            "can_attack": 5,
            "in_ranged": 6,
            "in_melee": 7,
            "in_combat": 8,
            "cast_progress": 9,
            "cast_interruptible": 10,
            "has_dispellable_buff": 11,
        }
        for unit_name, expected_classification in (
            ("target", "TARGET_STATUS"),
            ("focus", "FOCUS_TARGET"),
        ):
            unit = result[unit_name]
            self.assertEqual(set(unit), set(expected_indices) | {"cast_icon"})
            for field_name, expected_index in expected_indices.items():
                with self.subTest(unit=unit_name, field=field_name):
                    self.assertEqual(unit[field_name]["classification"], expected_classification)
                    self.assertEqual(unit[field_name]["index"], expected_index)

    def test_target_protocol_mismatch_fails_whole_frame(self) -> None:
        matrix = build_valid_matrix()
        set_target_value(matrix, 5, 100)
        top = (7 - 1) * 4
        left = (37 - 1) * 4
        matrix[top : top + 4, left : left + 4, 0] = 50
        with self.assertRaises(ValueError):
            extract_matrix(matrix)

    def test_unknown_target_icon_border_returns_hash_without_failing_frame(self) -> None:
        matrix = build_valid_matrix()
        center = np.full((6, 6, 3), 77, dtype=np.uint8)
        set_target_cast_icon(matrix, center, border_color=(1, 2, 3))
        result = extract_matrix(matrix)
        icon = result["target"]["cast_icon"]
        self.assertIsNotNone(icon["icon_hash"])
        self.assertIsNone(icon["icon_category"])
        self.assertEqual(icon["result"], icon["icon_hash"])
        self.assertIn("is_exists", result["target"])

    def test_extracts_spell_list_for_known_specialization(self) -> None:
        matrix = self.build_populated_matrix()
        # build_populated_matrix 设置 player value 2=10, 3=20，对应 class_id=1(WARRIOR), spec_id=2(FURY)。
        set_spell_cell(matrix, 1, cooldown=247, usable=255, overlayed=0, known=255)
        set_spell_cell(matrix, 2, cooldown=0, usable=0, overlayed=255, known=255)
        result = extract_matrix(matrix)
        spells = result["spell"]
        self.assertEqual(len(spells), 12)
        first = spells[0]
        self.assertEqual(first["type"], "spell")
        self.assertEqual(first["index"], 1)
        self.assertEqual(first["description"], "公共冷却")
        self.assertEqual(first["spellId"], 61304)
        self.assertEqual(first["cooldown"]["type"], "Cell")
        self.assertEqual(first["cooldown"]["classification"], "SPELL_COOLDOWN")
        self.assertEqual(first["cooldown"]["index"], 1)
        self.assertEqual(first["cooldown"]["raw_value"], 247)
        self.assertAlmostEqual(first["cooldown"]["result"], 247 / 255 * 100)
        self.assertEqual(first["usable"]["classification"], "SPELL_USABLE")
        self.assertEqual(first["usable"]["result"], True)
        self.assertEqual(first["overlayed"]["classification"], "SPELL_OVERLAYED")
        self.assertEqual(first["overlayed"]["result"], False)
        self.assertEqual(first["known"]["classification"], "SPELL_KNOWN")
        self.assertEqual(first["known"]["result"], True)
        second = spells[1]
        self.assertEqual(second["index"], 2)
        self.assertEqual(second["description"], "胜利在望")
        self.assertEqual(second["spellId"], 202168)
        self.assertEqual(second["usable"]["result"], False)
        self.assertEqual(second["overlayed"]["result"], True)

    def test_unknown_specialization_returns_empty_spell(self) -> None:
        # build_valid_matrix 的 player value 默认 0，class_id=0 不在 SPEC_BASE_BY_CLASS_ID。
        result = extract_matrix(build_valid_matrix())
        self.assertEqual(result["spell"], [])
        self.assertIn("is_alive", result["player"]["status"])

    def test_spell_protocol_mismatch_skips_slot_and_continues_frame(self) -> None:
        mismatch_cases = (
            (3, 1, 0, 50),
            (4, 1, 1, 2),
            (3, 2, 0, 50),
            (4, 2, 1, 2),
        )
        for x, y, channel, value in mismatch_cases:
            with self.subTest(x=x, y=y, channel=channel):
                matrix = self.build_populated_matrix()
                top = (y - 1) * 4
                left = (x - 1) * 4
                matrix[top : top + 4, left : left + 4, channel] = value

                spells = extract_matrix(matrix)["spell"]

                self.assertEqual(
                    [spell["index"] for spell in spells],
                    list(range(2, 13)),
                )

    def test_all_black_configured_spell_slot_keeps_frame_failure(self) -> None:
        matrix = self.build_populated_matrix()
        matrix[0:8, 8:16] = 0

        with self.assertRaises(ValueError):
            extract_matrix(matrix)

    def test_extracts_charge_list_for_vengeance_specialization(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 2, 120)
        set_player_value(matrix, 3, 20)
        set_charge_bar(matrix, 1, 4)
        set_charge_bar(matrix, 2, 8)
        set_charge_bar(matrix, 3, 2)
        set_charge_bar(matrix, 4, 0)

        charges = extract_matrix(matrix)["charge"]

        self.assertEqual(len(charges), 4)
        first = charges[0]
        self.assertEqual(
            set(first),
            {"type", "index", "description", "spellId", "minValue", "maxValue", "raw_value", "result"},
        )
        self.assertEqual(first["type"], "charge")
        self.assertEqual(first["index"], 1)
        self.assertEqual(first["description"], "投掷利刃")
        self.assertEqual(first["spellId"], 185123)
        self.assertEqual(first["minValue"], 0)
        self.assertEqual(first["maxValue"], 2)
        self.assertEqual(first["raw_value"], 0.5)
        self.assertIsInstance(first["raw_value"], float)
        self.assertEqual(first["result"], 1.0)
        self.assertIsInstance(first["result"], float)
        self.assertEqual(charges[1]["result"], 2.0)
        self.assertEqual(charges[2]["result"], 0.5)
        self.assertEqual(charges[3]["result"], 0.0)

    def test_unknown_specialization_returns_empty_charge(self) -> None:
        result = extract_matrix(build_valid_matrix())
        self.assertEqual(result["charge"], [])
        self.assertIn("is_alive", result["player"]["status"])

    def test_charge_protocol_mismatch_skips_slot_and_continues_frame(self) -> None:
        for mismatch in ("classification", "index"):
            with self.subTest(mismatch=mismatch):
                matrix = build_valid_matrix()
                set_player_value(matrix, 2, 120)
                set_player_value(matrix, 3, 20)
                for index in range(1, 5):
                    set_charge_bar(matrix, index, index)
                if mismatch == "classification":
                    set_charge_bar(matrix, 1, 4, classification=50)
                else:
                    set_charge_bar(matrix, 1, 4, encoded_index=2)

                charges = extract_matrix(matrix)["charge"]

                self.assertEqual([charge["index"] for charge in charges], [2, 3, 4])

    def test_all_black_configured_charge_slot_keeps_frame_failure(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 2, 120)
        set_player_value(matrix, 3, 20)
        for index in range(2, 5):
            set_charge_bar(matrix, index, 0)

        with self.assertRaises(ValueError):
            extract_matrix(matrix)

    def test_charge_list_rejects_invalid_or_above_limit_keys(self) -> None:
        decoder = Mock()
        for invalid_key in (True, 0, "1", 7):
            with self.subTest(key=invalid_key):
                spec = Mock()
                spec.charge_list = {
                    invalid_key: {
                        "description": "测试",
                        "spellId": 1,
                        "minValue": 0,
                        "maxValue": 1,
                    }
                }
                with patch(
                    "copilot.decoder.extractor.resolve_specialization",
                    return_value=spec,
                ):
                    with self.assertRaises(ValueError):
                        decode_spell_charge_bar(decoder, 55, 1, 6, 1, 1)
                decoder.get_charge_bar.assert_not_called()

        spec = Mock()
        spec.charge_list = {
            1: {"description": "有效", "spellId": 1, "minValue": 0, "maxValue": 1},
            7: {"description": "超限", "spellId": 2, "minValue": 0, "maxValue": 1},
        }
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            with self.assertRaises(ValueError):
                decode_spell_charge_bar(decoder, 55, 1, 6, 1, 1)
        decoder.get_charge_bar.assert_not_called()

    def test_charge_list_preserves_sparse_slot_indexes(self) -> None:
        matrix = build_valid_matrix()
        set_charge_bar(matrix, 1, 8)
        set_charge_bar(matrix, 3, 4)
        spec = Mock()
        spec.charge_list = {
            1: {"description": "槽位一", "spellId": 1, "minValue": 0, "maxValue": 2},
            3: {"description": "槽位三", "spellId": 3, "minValue": 0, "maxValue": 2},
        }
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            charges = decode_spell_charge_bar(MatrixDecoder(matrix), 55, 1, 6, 1, 1)

        self.assertEqual([charge["index"] for charge in charges], [1, 3])
        self.assertEqual([charge["result"] for charge in charges], [2.0, 1.0])

    def test_extracts_configured_druid_aura_slots(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 2, 110)
        set_player_value(matrix, 3, 40)
        set_charge_bar(matrix, 1, 0)
        set_aura_slot(matrix, 1, 3, 1, 14, 8, 20, 25)
        set_aura_slot(matrix, 37, 3, 1, 8, 4, 30, 35)

        result = extract_matrix(matrix)

        self.assertEqual(len(result["player_buff"]), 9)
        self.assertEqual(len(result["target_debuff"]), 2)
        player_buff = result["player_buff"][0]
        self.assertEqual(
            set(player_buff),
            {"type", "index", "description", "spellId", "duration", "application"},
        )
        self.assertEqual(player_buff["type"], "aura_slot")
        self.assertEqual(player_buff["index"], 1)
        self.assertEqual(player_buff["description"], "爪子")
        self.assertEqual(player_buff["spellId"], [1126, 432661])
        self.assertEqual(player_buff["duration"], {"raw_value": 0.875, "result": 87.5})
        self.assertEqual(
            player_buff["application"],
            {"raw_value": 0.5, "minValue": 0, "maxValue": 2, "result": 1.0},
        )
        self.assertEqual(result["target_debuff"][0]["description"], "月火术")
        self.assertEqual(result["target_debuff"][0]["duration"]["result"], 50.0)
        self.assertEqual(result["target_debuff"][0]["application"]["result"], 0.5)

    def test_inactive_aura_slots_are_retained_and_zeroed(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 2, 110)
        set_player_value(matrix, 3, 40)
        set_charge_bar(matrix, 1, 0)

        result = extract_matrix(matrix)

        self.assertEqual(len(result["player_buff"]), 9)
        self.assertEqual(
            result["player_buff"][0]["duration"],
            {"raw_value": 0.0, "result": 0.0},
        )
        self.assertEqual(
            result["player_buff"][0]["application"],
            {"raw_value": 0.0, "minValue": 0, "maxValue": 2, "result": 0.0},
        )

    def test_aura_uses_max_applications_override(self) -> None:
        matrix = build_valid_matrix()
        set_aura_slot(matrix, 1, 3, 1, 16, 8, 20, 25)
        spec = Mock()
        spec.player_buff = {
            1: {
                "description": "白骨之盾",
                "spellIDs": [195181],
                "maxApplications": 12,
            }
        }
        spec.target_debuff = {}
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            aura = decode_aura_slot_container(
                MatrixDecoder(matrix), 1, 3, 9, 6, 1, "player_buff"
            )[0]

        self.assertEqual(aura["application"]["maxValue"], 12)
        self.assertEqual(aura["application"]["result"], 6.0)

    def test_unknown_specialization_returns_empty_aura_lists(self) -> None:
        result = extract_matrix(build_valid_matrix())
        self.assertEqual(result["player_buff"], [])
        self.assertEqual(result["target_debuff"], [])
        self.assertIn("spell", result)
        self.assertIn("charge", result)

    def test_aura_rejects_invalid_type_and_keys_before_reading(self) -> None:
        decoder = Mock()
        with self.assertRaises(ValueError):
            decode_aura_slot_container(decoder, 1, 3, 9, 0, 0, "player_debuff")
        decoder.get_duration_bar.assert_not_called()

        for invalid_key in (True, 0, "1", 10):
            with self.subTest(key=invalid_key):
                spec = Mock()
                spec.player_buff = {
                    invalid_key: {"description": "测试", "spellIDs": [1]}
                }
                spec.target_debuff = {}
                with patch(
                    "copilot.decoder.extractor.resolve_specialization",
                    return_value=spec,
                ):
                    with self.assertRaises(ValueError):
                        decode_aura_slot_container(
                            decoder, 1, 3, 9, 1, 1, "player_buff"
                        )
                decoder.get_duration_bar.assert_not_called()

        spec = Mock()
        spec.player_buff = {
            1: {"description": "有效槽位", "spellIDs": [1]},
            10: {"description": "超限槽位", "spellIDs": [10]},
        }
        spec.target_debuff = {}
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            with self.assertRaises(ValueError):
                decode_aura_slot_container(decoder, 1, 3, 9, 1, 1, "player_buff")
        decoder.get_duration_bar.assert_not_called()
        decoder.get_application_bar.assert_not_called()

    def test_aura_preserves_sparse_configured_indexes(self) -> None:
        matrix = build_valid_matrix()
        set_aura_slot(matrix, 1, 3, 1, 16, 8, 20, 25)
        set_aura_slot(matrix, 1, 3, 3, 8, 4, 20, 25)
        spec = Mock()
        spec.player_buff = {
            1: {"description": "槽位一", "spellIDs": [1]},
            3: {"description": "槽位三", "spellIDs": [3]},
        }
        spec.target_debuff = {}
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            aura_list = decode_aura_slot_container(
                MatrixDecoder(matrix), 1, 3, 9, 1, 1, "player_buff"
            )

        self.assertEqual([aura["index"] for aura in aura_list], [1, 3])
        self.assertEqual(
            [aura["duration"]["result"] for aura in aura_list],
            [100.0, 50.0],
        )

    def test_aura_protocol_mismatch_skips_slot_and_continues_frame(self) -> None:
        mismatch_cases = (
            ("player_buff", 1, 3, 9, 21, 25, None, None),
            ("player_buff", 1, 3, 9, 20, 25, None, 2),
            ("target_debuff", 37, 3, 6, 30, 35, 2, None),
            ("target_debuff", 37, 3, 6, 30, 36, None, None),
        )
        for (
            list_type,
            x,
            y,
            length,
            duration_classification,
            application_classification,
            duration_encoded_index,
            application_encoded_index,
        ) in mismatch_cases:
            with self.subTest(list_type=list_type, case=(
                duration_classification,
                application_classification,
                duration_encoded_index,
                application_encoded_index,
            )):
                matrix = build_valid_matrix()
                set_aura_slot(
                    matrix,
                    x,
                    y,
                    1,
                    8,
                    4,
                    duration_classification,
                    application_classification,
                    duration_encoded_index,
                    application_encoded_index,
                )
                valid_duration_classification = (
                    20 if list_type == "player_buff" else 30
                )
                valid_application_classification = (
                    25 if list_type == "player_buff" else 35
                )
                set_aura_slot(
                    matrix,
                    x,
                    y,
                    2,
                    16,
                    8,
                    valid_duration_classification,
                    valid_application_classification,
                )
                spec = Mock()
                spec.player_buff = (
                    {
                        1: {"description": "损坏槽", "spellIDs": [1]},
                        2: {"description": "有效槽", "spellIDs": [2]},
                    }
                    if list_type == "player_buff"
                    else {}
                )
                spec.target_debuff = (
                    {
                        1: {"description": "损坏槽", "spellIDs": [1]},
                        2: {"description": "有效槽", "spellIDs": [2]},
                    }
                    if list_type == "target_debuff"
                    else {}
                )
                with patch(
                    "copilot.decoder.extractor.resolve_specialization",
                    return_value=spec,
                ):
                    aura_list = decode_aura_slot_container(
                        MatrixDecoder(matrix), x, y, length, 1, 1, list_type
                    )

                self.assertEqual([aura["index"] for aura in aura_list], [2])

    def test_partially_black_aura_slot_is_skipped(self) -> None:
        matrix = build_valid_matrix()
        set_aura_slot(matrix, 1, 3, 1, 0, 0, 20, 25)
        top = (4 - 1) * 4
        matrix[top : top + 4, :16] = 0
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=Mock(
                player_buff={1: {"description": "测试", "spellIDs": [1]}},
                target_debuff={},
            ),
        ):
            aura_list = decode_aura_slot_container(
                MatrixDecoder(matrix), 1, 3, 9, 1, 1, "player_buff"
            )

        self.assertEqual(aura_list, [])

    def test_slot_decoder_access_errors_remain_frame_level(self) -> None:
        spec = Mock(
            spell_list={
                1: {"description": "技能", "spellId": 1},
            },
            charge_list={
                1: {
                    "description": "充能",
                    "spellId": 1,
                    "minValue": 0,
                    "maxValue": 1,
                },
            },
            player_buff={
                1: {"description": "增益", "spellIDs": [1]},
            },
            target_debuff={},
        )
        with patch(
            "copilot.decoder.extractor.resolve_specialization",
            return_value=spec,
        ):
            spell_decoder = Mock()
            spell_decoder.get_cell.side_effect = RuntimeError("spell access")
            with self.assertRaisesRegex(RuntimeError, "spell access"):
                decode_spell_cell(spell_decoder, 3, 1, 26, 1, 1)

            charge_decoder = Mock()
            charge_decoder.get_charge_bar.side_effect = RuntimeError("charge access")
            with self.assertRaisesRegex(RuntimeError, "charge access"):
                decode_spell_charge_bar(charge_decoder, 55, 1, 6, 1, 1)

            aura_decoder = Mock()
            aura_decoder.get_duration_bar.side_effect = RuntimeError("aura access")
            with self.assertRaisesRegex(RuntimeError, "aura access"):
                decode_aura_slot_container(
                    aura_decoder, 1, 3, 9, 1, 1, "player_buff"
                )

    def test_decodes_dynamic_aura_group_with_fixed_mappings(self) -> None:
        matrix = build_valid_matrix()
        center = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        set_aura_group(matrix, 1, center, 12, 8)
        manager = FakeTitleManager()

        aura_list = decode_aura_group_container(
            MatrixDecoder(matrix), 1, 5, 5, manager  # type: ignore[arg-type]
        )

        self.assertEqual(len(aura_list), 1)
        aura = aura_list[0]
        self.assertEqual(set(aura), {"type", "icon", "duration", "application"})
        self.assertEqual(aura["type"], "aura_group")
        self.assertEqual(aura["icon"]["icon_category"], "DEBUFF_ON_FRIENDLY")
        self.assertEqual(aura["icon"]["result"], "Known Spell")
        self.assertEqual(aura["duration"], {"raw_value": 0.75, "result": 75.0})
        self.assertEqual(
            aura["application"],
            {"raw_value": 0.5, "minValue": 0, "maxValue": 4, "result": 2.0},
        )
        self.assertEqual(manager.calls[0][0], "DEBUFF_ON_FRIENDLY")

    def test_dynamic_aura_group_skips_black_and_malformed_entries(self) -> None:
        mismatch_cases = (
            (41, 2, 45, 2),
            (40, 1, 45, 2),
            (40, 2, 46, 2),
            (40, 2, 45, 1),
        )
        for duration_class, duration_index, application_class, application_index in mismatch_cases:
            with self.subTest(mismatch=(
                duration_class,
                duration_index,
                application_class,
                application_index,
            )):
                matrix = build_valid_matrix()
                center = np.full((6, 6, 3), 88, dtype=np.uint8)
                set_aura_group(matrix, 1, center, 4, 4)
                set_aura_group(
                    matrix,
                    2,
                    center,
                    8,
                    8,
                    duration_classification=duration_class,
                    application_classification=application_class,
                    duration_encoded_index=duration_index,
                    application_encoded_index=application_index,
                )
                set_aura_group(matrix, 3, None, 8, 4)
                set_aura_group(matrix, 4, center, 16, 16)

                aura_list = decode_aura_group_container(
                    MatrixDecoder(matrix), 1, 5, 5
                )

                self.assertEqual(len(aura_list), 2)
                self.assertEqual(
                    [aura["duration"]["result"] for aura in aura_list],
                    [25.0, 100.0],
                )
                self.assertEqual(
                    [aura["application"]["result"] for aura in aura_list],
                    [1.0, 4.0],
                )

    def test_dynamic_aura_group_unknown_icon_uses_hash(self) -> None:
        matrix = build_valid_matrix()
        center = np.full((6, 6, 3), 77, dtype=np.uint8)
        set_aura_group(matrix, 1, center, 8, 4)
        manager = HashTitleManager()

        aura = decode_aura_group_container(
            MatrixDecoder(matrix), 1, 5, 5, manager  # type: ignore[arg-type]
        )[0]

        self.assertIsNotNone(aura["icon"]["icon_hash"])
        self.assertEqual(aura["icon"]["icon_category"], "DEBUFF_ON_FRIENDLY")
        self.assertEqual(aura["icon"]["result"], aura["icon"]["icon_hash"])
        self.assertEqual(manager.calls, [
            ("DEBUFF_ON_FRIENDLY", aura["icon"]["icon_hash"])
        ])

    def test_dynamic_aura_group_title_failure_remains_frame_level(self) -> None:
        matrix = build_valid_matrix()
        center = np.full((6, 6, 3), 77, dtype=np.uint8)
        set_aura_group(matrix, 1, center, 8, 4)
        manager = Mock()
        manager.resolve.side_effect = RuntimeError("title database failed")

        with self.assertRaisesRegex(RuntimeError, "title database failed"):
            decode_aura_group_container(
                MatrixDecoder(matrix), 1, 5, 5, manager
            )

    def test_decodes_party_status_absent_member_and_fixed_hots(self) -> None:
        matrix = build_valid_matrix()
        set_party_member(
            matrix,
            1,
            exists=255,
            target=255,
            role=20,
            in_range=255,
            health=128,
            damage_absorb=255,
            heal_absorb=0,
            buff=255,
            dispellable=0,
            big_defensive=255,
        )
        set_party_hot_bar(matrix, 1, 1, 8)

        party = decode_party_container(MatrixDecoder(matrix), 11, 4)

        self.assertEqual(len(party), 4)
        member = party[0]
        self.assertEqual(member["type"], "party_info")
        self.assertEqual(member["index"], 1)
        self.assertTrue(member["exists"]["result"])
        self.assertTrue(member["target"]["result"])
        self.assertEqual(member["role"]["result"], "HEALER")
        self.assertTrue(member["range"]["result"])
        self.assertAlmostEqual(member["health"]["result"], 128 / 255 * 100)
        self.assertTrue(member["damage_absorb"]["result"])
        self.assertFalse(member["heal_absorb"]["result"])
        self.assertTrue(member["buff"]["result"])
        self.assertFalse(member["dispellable"]["result"])
        self.assertTrue(member["big_defensive"]["result"])
        self.assertEqual([hot["index"] for hot in member["hots"]], [1, 2, 3, 4, 5])
        self.assertEqual(member["hots"][0]["description"], "萌芽")
        self.assertEqual(member["hots"][0]["spellIDs"], [155777])
        self.assertEqual(member["hots"][0]["duration_raw_value"], 0.5)
        self.assertEqual(member["hots"][0]["duration_result"], 50.0)
        self.assertEqual(member["hots"][1]["duration_result"], 0.0)

        absent = party[1]
        self.assertFalse(absent["exists"]["result"])
        self.assertIsNone(absent["target"])
        self.assertIsNone(absent["hots"])

    def test_absent_party_members_read_only_exists_cells(self) -> None:
        decoder = Mock(wraps=MatrixDecoder(build_valid_matrix()))

        party = decode_party_container(decoder, 11, 4)

        self.assertEqual(len(party), 4)
        self.assertEqual(
            decoder.get_cell.call_args_list,
            [call(1, row_y) for row_y in range(8, 12)],
        )
        decoder.get_duration_bar.assert_not_called()

    def test_party_status_mismatch_omits_only_malformed_members(self) -> None:
        for malformed_color in ((121, 1, 255), (120, 2, 255)):
            with self.subTest(malformed_color=malformed_color):
                matrix = build_valid_matrix()
                set_party_member(
                    matrix,
                    1,
                    exists=255,
                    target=0,
                    role=10,
                    in_range=255,
                    health=255,
                    damage_absorb=0,
                    heal_absorb=0,
                    buff=0,
                    dispellable=0,
                    big_defensive=0,
                )
                set_cell(matrix, 5, 8, malformed_color)

                party = decode_party_container(MatrixDecoder(matrix), 11, 4)

                self.assertEqual([member["index"] for member in party], [2, 3, 4])

        matrix = build_valid_matrix()
        for member_index in range(1, 5):
            set_cell(matrix, 1, 7 + member_index, (101, member_index, 255))
        self.assertEqual(decode_party_container(MatrixDecoder(matrix), 11, 4), [])

    def test_party_hot_malformed_nonblack_slot_is_omitted(self) -> None:
        mismatch_cases = ({"classification": 156}, {"encoded_index": 2})
        for mismatch in mismatch_cases:
            with self.subTest(mismatch=mismatch):
                matrix = build_valid_matrix()
                set_party_member(
                    matrix,
                    1,
                    exists=255,
                    target=0,
                    role=10,
                    in_range=255,
                    health=255,
                    damage_absorb=0,
                    heal_absorb=0,
                    buff=0,
                    dispellable=0,
                    big_defensive=0,
                )
                set_party_hot_bar(matrix, 1, 2, 8, **mismatch)
                set_party_hot_bar(matrix, 1, 4, 4)

                hots = decode_party_container(MatrixDecoder(matrix), 11, 4)[0]["hots"]

                self.assertEqual([hot["index"] for hot in hots], [1, 3, 4, 5])
                self.assertEqual(
                    [hot["duration_result"] for hot in hots],
                    [0.0, 0.0, 25.0, 0.0],
                )

    def test_party_unknown_spec_and_sparse_hot_config(self) -> None:
        matrix = build_valid_matrix()
        set_party_member(
            matrix,
            1,
            exists=255,
            target=0,
            role=10,
            in_range=255,
            health=255,
            damage_absorb=0,
            heal_absorb=0,
            buff=0,
            dispellable=0,
            big_defensive=0,
        )
        self.assertEqual(
            decode_party_container(MatrixDecoder(matrix), 0, 0)[0]["hots"], []
        )

        spec = Mock()
        spec.party_hots = {2: {"description": "测试HOT", "spellIDs": [123]}}
        with patch("copilot.decoder.extractor.resolve_specialization", return_value=spec):
            hots = decode_party_container(MatrixDecoder(matrix), 1, 1)[0]["hots"]
        self.assertEqual(hots, [{
            "index": 2,
            "description": "测试HOT",
            "spellIDs": [123],
            "duration_raw_value": 0.0,
            "duration_result": 0.0,
        }])

    def test_party_hot_config_keys_are_validated_before_bar_access(self) -> None:
        for invalid_key in (True, 0, 6, "1"):
            with self.subTest(invalid_key=invalid_key):
                spec = Mock()
                spec.party_hots = {
                    invalid_key: {"description": "坏配置", "spellIDs": []}
                }
                decoder = Mock()
                with patch(
                    "copilot.decoder.extractor.resolve_specialization", return_value=spec
                ), self.assertRaises(ValueError):
                    decode_party_container(decoder, 1, 1)
                decoder.get_cell.assert_not_called()

    def test_extract_matrix_publishes_party(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 2, 110)
        set_player_value(matrix, 3, 40)
        set_charge_bar(matrix, 1, 0)
        set_party_member(
            matrix,
            1,
            exists=255,
            target=0,
            role=20,
            in_range=255,
            health=255,
            damage_absorb=0,
            heal_absorb=0,
            buff=0,
            dispellable=0,
            big_defensive=0,
        )
        set_party_hot_bar(matrix, 1, 5, 2)

        party = extract_matrix(matrix)["party"]

        self.assertEqual([member["index"] for member in party], [1, 2, 3, 4])
        self.assertEqual(party[0]["hots"][4]["duration_result"], 12.5)

    def test_decodes_all_raid_layout_bands_and_protocol_indexes(self) -> None:
        matrix = build_valid_matrix()
        populated_indexes = (1, 6, 11, 21, 30)
        for member_index in populated_indexes:
            set_raid_member(
                matrix,
                member_index,
                exists=255,
                target=255,
                role=20,
                in_range=255,
                health=128,
                damage_absorb=255,
                dispellable=0,
            )
        for hot_index in range(1, 6):
            set_raid_hot_cell(
                matrix,
                30,
                hot_index,
                255 if hot_index == 1 else 0,
            )

        raid = decode_raid_container(MatrixDecoder(matrix), 11, 4)

        self.assertEqual(len(raid), 30)
        by_index = {member["index"]: member for member in raid}
        for member_index in populated_indexes:
            with self.subTest(member_index=member_index):
                member = by_index[member_index]
                self.assertEqual(member["type"], "raid_info")
                self.assertTrue(member["exists"]["result"])
                self.assertEqual(member["exists"]["index"], member_index + 10)
                self.assertEqual(member["role"]["result"], "HEALER")
                self.assertAlmostEqual(member["health"]["result"], 128 / 255 * 100)
        self.assertEqual(raid_member_origin(1), (31, 8))
        self.assertEqual(raid_member_origin(6), (31, 10))
        self.assertEqual(raid_member_origin(11), (1, 12))
        self.assertEqual(raid_member_origin(21), (1, 14))
        self.assertEqual(raid_member_origin(30), (55, 14))
        self.assertEqual([hot["index"] for hot in by_index[30]["hots"]], [1, 2, 3, 4, 5])
        first_hot = by_index[30]["hots"][0]
        self.assertEqual(first_hot["description"], "萌芽")
        self.assertEqual(first_hot["spellIDs"], [155777])
        self.assertEqual(first_hot["cell"], {
            "type": "Cell",
            "classification": "PARTY_HOT1",
            "index": 40,
            "raw_value": 255,
            "result": True,
        })
        self.assertFalse(by_index[30]["hots"][1]["cell"]["result"])

    def test_absent_raid_members_read_only_exists_cells(self) -> None:
        decoder = Mock(wraps=MatrixDecoder(build_valid_matrix()))

        raid = decode_raid_container(decoder, 11, 4)

        self.assertEqual(len(raid), 30)
        self.assertEqual(
            decoder.get_cell.call_args_list,
            [call(*origin) for origin in EXPECTED_RAID_ORIGINS],
        )
        self.assertTrue(all(member["type"] == "raid_info" for member in raid))
        self.assertTrue(all(member["exists"]["result"] is False for member in raid))
        self.assertTrue(all(member["target"] is None for member in raid))
        self.assertTrue(all(member["hots"] is None for member in raid))

    def test_malformed_raid_exists_omits_member_without_reading_its_block(self) -> None:
        for malformed_color in ((101, 11, 0), (100, 99, 0)):
            with self.subTest(malformed_color=malformed_color):
                matrix = build_valid_matrix()
                set_cell(matrix, 31, 8, malformed_color)
                decoder = Mock(wraps=MatrixDecoder(matrix))

                raid = decode_raid_container(decoder, 11, 4)

                self.assertNotIn(1, [member["index"] for member in raid])
                self.assertEqual(
                    decoder.get_cell.call_args_list,
                    [call(*origin) for origin in EXPECTED_RAID_ORIGINS],
                )

    def test_raid_protocol_mismatch_omits_member_or_single_hot(self) -> None:
        matrix = build_valid_matrix()
        for member_index in (1, 2):
            set_raid_member(
                matrix,
                member_index,
                exists=255,
                target=0,
                role=10,
                in_range=255,
                health=255,
                damage_absorb=0,
                dispellable=0,
            )
            for hot_index in range(1, 6):
                set_raid_hot_cell(matrix, member_index, hot_index, 0)
        first_x, first_y = raid_member_origin(1)
        set_cell(matrix, first_x + 4, first_y, (121, 11, 255))
        set_raid_hot_cell(matrix, 2, 2, 255, encoded_index=99)

        raid = decode_raid_container(MatrixDecoder(matrix), 11, 4)

        self.assertNotIn(1, [member["index"] for member in raid])
        member_two = next(member for member in raid if member["index"] == 2)
        self.assertEqual([hot["index"] for hot in member_two["hots"]], [1, 3, 4, 5])

    def test_raid_unknown_and_sparse_specialization_hots(self) -> None:
        matrix = build_valid_matrix()
        set_raid_member(
            matrix,
            1,
            exists=255,
            target=0,
            role=10,
            in_range=255,
            health=255,
            damage_absorb=0,
            dispellable=0,
        )
        self.assertEqual(
            decode_raid_container(MatrixDecoder(matrix), 0, 0)[0]["hots"], []
        )

        set_raid_hot_cell(matrix, 1, 2, 255)
        spec = Mock()
        spec.party_hots = {2: {"description": "测试HOT", "spellIDs": [123]}}
        with patch("copilot.decoder.extractor.resolve_specialization", return_value=spec):
            hots = decode_raid_container(MatrixDecoder(matrix), 1, 1)[0]["hots"]
        self.assertEqual(hots, [{
            "index": 2,
            "description": "测试HOT",
            "spellIDs": [123],
            "cell": {
                "type": "Cell",
                "classification": "PARTY_HOT2",
                "index": 11,
                "raw_value": 255,
                "result": True,
            },
        }])

    def test_extract_matrix_publishes_raid(self) -> None:
        raid = extract_matrix(build_valid_matrix())["raid"]

        self.assertEqual([member["index"] for member in raid], list(range(1, 31)))
        self.assertTrue(all(member["exists"]["result"] is False for member in raid))

    def test_extract_matrix_publishes_dynamic_player_debuff(self) -> None:
        matrix = build_valid_matrix()
        center = np.full((6, 6, 3), 66, dtype=np.uint8)
        set_aura_group(matrix, 5, center, 2, 6)

        result = extract_matrix(matrix)

        self.assertEqual(len(result["player_debuff"]), 1)
        self.assertEqual(result["player_debuff"][0]["duration"]["result"], 12.5)
        self.assertEqual(result["player_debuff"][0]["application"]["result"], 1.5)


if __name__ == "__main__":
    unittest.main()
