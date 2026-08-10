"""摘要：验证 Cell、IconCell、Bar 与 MatrixDecoder 的当前协议原语。

描述：覆盖像素采样、分类与索引解码、图标结构、UTF 标题，以及 Duration、Application、
Charge 三类 Bar 的方向和比例计算。
主要变量信息：matrix 表示固定尺寸 RGB 帧；bar 表示从帧中截取的协议条形区域。
修改记录：2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 需求新增 ApplicationBar 覆盖。
2026-08-02，根据 Phase 2.12 Matrix Decoder 需求新增 UTF 标题覆盖。
"""

from __future__ import annotations

import unittest

import numpy as np

from copilot.decoder import (
    ApplicationBar,
    ChargeBar,
    DurationBar,
    IconCell,
    MatrixDecoder,
)
from copilot.decoder.cell import Cell
from copilot.decoder.color import COLOR
from copilot.decoder.matrix import EXPECTED_SHAPE
from tests.matrix_fixture import build_valid_matrix, set_badge_utf_output, set_cell, set_utf_text


class DecoderPrimitiveTests(unittest.TestCase):
    def test_cell_uses_center_two_by_two_and_decodes_channels(self) -> None:
        pixels = np.full((4, 4, 3), 255, dtype=np.uint8)
        pixels[1:3, 1:3] = (5, 7, 128)
        cell = Cell(7, 7, pixels)
        self.assertEqual(cell.channel_values, (5, 7, 128))
        self.assertEqual(cell.classification, "PLAYER_STATUS")
        self.assertEqual(cell.index, 7)
        self.assertEqual(cell.raw_value, 128)
        self.assertTrue(cell.is_pure)
        self.assertEqual(cell.remaining, cell.percent)

    def test_matrix_requires_current_geometry_and_markers(self) -> None:
        decoder = MatrixDecoder(build_valid_matrix())
        self.assertEqual(decoder.get_cell(1, 1).channel_values, (15, 25, 20))
        with self.assertRaises(ValueError):
            MatrixDecoder(np.zeros(EXPECTED_SHAPE, dtype=np.uint8))
        with self.assertRaises(ValueError):
            MatrixDecoder(np.zeros((10, 10, 3), dtype=np.uint8))

    def test_matrix_uses_one_based_bounds(self) -> None:
        decoder = MatrixDecoder(build_valid_matrix())
        with self.assertRaises(ValueError):
            decoder.get_cell(0, 1)
        with self.assertRaises(IndexError):
            decoder.get_icon_cell(60, 17)
        for invalid_x in (True, 1.5, "1"):
            with self.subTest(x=invalid_x), self.assertRaises(TypeError):
                decoder.get_cell(invalid_x, 1)  # type: ignore[arg-type]
        self.assertEqual(decoder.get_cell(np.int64(60), 17).x, 60)

    def test_icon_hashes_center_and_reads_border_category(self) -> None:
        pixels = np.full((8, 8, 3), (64, 158, 210), dtype=np.uint8)
        center = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        pixels[1:7, 1:7] = center
        icon = IconCell(31, 5, pixels)
        self.assertEqual(icon.valid_array.tolist(), center.tolist())
        self.assertEqual(icon.icon_category, "PLAYER_SPELL")
        self.assertIsNotNone(icon.icon_hash)
        pixels[0, 0] = 0
        self.assertEqual(icon.icon_hash, icon.icon_hash)

    def test_blank_icon_has_no_hash_or_category(self) -> None:
        icon = IconCell(31, 5, np.zeros((8, 8, 3), dtype=np.uint8))
        self.assertTrue(icon.is_blank)
        self.assertIsNone(icon.icon_hash)
        self.assertIsNone(icon.icon_category)

    def test_all_icon_colors_map_to_copilot_business_groups(self) -> None:
        cases = {
            "PLAYER_SPELL": ("PLAYER_SPELL", "PLAYER_SPELL"),
            "ENEMY_SPELL_INTERRUPTIBLE": (
                "ENEMY_SPELL_INTERRUPTIBLE",
                "ENEMY_SPELL_INTERRUPTIBLE",
            ),
            "ENEMY_SPELL_NOT_INTERRUPTIBLE": (
                "ENEMY_SPELL_NOT_INTERRUPTIBLE",
                "ENEMY_SPELL_NOT_INTERRUPTIBLE",
            ),
            "MAGIC": ("MAGIC", "DEBUFF_ON_FRIENDLY"),
            "CURSE": ("CURSE", "DEBUFF_ON_FRIENDLY"),
            "DISEASE": ("DISEASE", "DEBUFF_ON_FRIENDLY"),
            "POISON": ("POISON", "DEBUFF_ON_FRIENDLY"),
            "ENRAGE": ("ENRAGE", "DEBUFF_ON_FRIENDLY"),
            "BLEED": ("BLEED", "DEBUFF_ON_FRIENDLY"),
            "DEBUFF_ON_FRIENDLY": (
                "DEBUFF_ON_FRIENDLY",
                "DEBUFF_ON_FRIENDLY",
            ),
            "BUFF_ON_FRIENDLY": ("BUFF_ON_FRIENDLY", None),
            "DEBUFF_ON_ENEMY": ("DEBUFF_ON_ENEMY", None),
            "NONE": ("NONE", None),
        }
        center = np.ones((6, 6, 3), dtype=np.uint8)
        for color_name, expected in cases.items():
            with self.subTest(color=color_name):
                pixels = np.full((8, 8, 3), COLOR[color_name], dtype=np.uint8)
                pixels[1:7, 1:7] = center
                icon = IconCell(1, 1, pixels)
                self.assertEqual((icon.icon_type, icon.icon_category), expected)

        unknown = np.full((8, 8, 3), (1, 2, 3), dtype=np.uint8)
        unknown[1:7, 1:7] = center
        icon = IconCell(1, 1, unknown)
        self.assertEqual(icon.icon_type, "UNKNOWN")
        self.assertIsNone(icon.icon_category)

    def test_transparent_footnote_does_not_outvote_visible_border_color(self) -> None:
        pixels = np.zeros((8, 8, 3), dtype=np.uint8)
        pixels[1:7, 1:7] = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        pixels[-1, -1] = COLOR["PLAYER_SPELL"]
        icon = IconCell(1, 1, pixels)
        self.assertEqual(icon.icon_type, "PLAYER_SPELL")
        self.assertEqual(icon.icon_category, "PLAYER_SPELL")

    def test_matrix_reads_only_valid_wrapped_utf_title(self) -> None:
        matrix = build_valid_matrix()
        center = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
        set_badge_utf_output(matrix, center, "炎爆术")
        decoder = MatrixDecoder(matrix)
        self.assertEqual(decoder.read_utf_title(43, 16, 16), "炎爆术")

        set_utf_text(matrix, "abcdefghijklmnop")
        self.assertIsNone(decoder.read_utf_title(43, 16, 16))
        set_utf_text(matrix, "*#\x00*#")
        self.assertIsNone(decoder.read_utf_title(43, 16, 16))
        set_utf_text(matrix, "*#\x01*#")
        self.assertIsNone(decoder.read_utf_title(43, 16, 16))
        set_cell(matrix, 43, 16, (255, 255, 255))
        self.assertIsNone(decoder.read_utf_title(43, 16, 16))
        set_cell(matrix, 43, 16, (42, 0, 0))
        matrix[(16 - 1) * 4 + 1, (43 - 1) * 4 + 1] = (43, 0, 0)
        self.assertIsNone(decoder.read_utf_title(43, 16, 16))

    def test_duration_bar_uses_center_rows_and_sixteen_steps(self) -> None:
        pixels = np.zeros((4, 16, 3), dtype=np.uint8)
        pixels[:] = (20, 2, 0)
        pixels[1:3, :5, 2] = 255
        pixels[0, 5:, 2] = 255
        bar = DurationBar(1, 3, pixels)
        self.assertEqual(bar.classification, "PLAYER_BUFF_DURATION")
        self.assertEqual(bar.index, 2)
        self.assertEqual(bar.filled_steps, 5)
        self.assertEqual(bar.ratio, 5 / 16)
        self.assertEqual(bar.percent, 31.25)

    def test_application_bar_reuses_horizontal_duration_geometry(self) -> None:
        matrix = build_valid_matrix()
        top = (4 - 1) * 4
        matrix[top : top + 4, :16] = (25, 1, 0)
        matrix[top : top + 4, :8, 2] = 255

        bar = MatrixDecoder(matrix).get_application_bar(1, 4)

        self.assertIsInstance(bar, ApplicationBar)
        self.assertIsInstance(bar, DurationBar)
        self.assertEqual(bar.classification, "PLAYER_BUFF_COUNT")
        self.assertEqual(bar.index, 1)
        self.assertEqual(bar.ratio, 0.5)

    def test_charge_bar_uses_center_columns_and_eight_steps(self) -> None:
        pixels = np.zeros((8, 4, 3), dtype=np.uint8)
        pixels[:] = (85, 3, 0)
        pixels[5:, 1:3, 2] = 255
        pixels[:5, 0, 2] = 255
        bar = ChargeBar(57, 1, pixels)
        self.assertEqual(bar.classification, "SPELL_CHARGE")
        self.assertEqual(bar.index, 3)
        self.assertEqual(bar.filled_steps, 3)
        self.assertEqual(bar.ratio, 3 / 8)
        self.assertEqual(bar.percent, 37.5)


if __name__ == "__main__":
    unittest.main()
