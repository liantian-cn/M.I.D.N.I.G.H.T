"""摘要：验证截图几何、RGB 所有权和严格双标记定位。

描述：使用纯内存帧及 Win32 读取替身覆盖半开区域校验、BGRA 到 RGB 通道顺序、结果
独立所有权、恰好两个标记及 Cell 几何成功和其他标记数量或不对齐几何失败，不访问真实
GUI 或项目入口。

主要变量信息：``MARKER_TEMPLATE`` 是当前 Phantom commit 对应的动态测试夹具。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增捕获测试；
2026-08-01，根据 audit finding 增加 marker 区域宽高不对齐测试。
"""

from __future__ import annotations

import ctypes
import unittest

import numpy as np

from copilot.capture.locator import locate_matrix
from copilot.capture.phantom_adapter import MARKER_TEMPLATE
from copilot.capture.win32 import (
    MonitorRegion,
    _absolute_capture_rect,
    _read_owned_rgb,
)


class CaptureGeometryTests(unittest.TestCase):
    def test_relative_half_open_region_becomes_absolute(self) -> None:
        monitor = MonitorRegion(-100, 20, 300, 220)
        self.assertEqual(
            _absolute_capture_rect(monitor, (10, 15, 110, 115)),
            MonitorRegion(-90, 35, 10, 135),
        )

    def test_invalid_regions_are_rejected(self) -> None:
        monitor = MonitorRegion(0, 0, 100, 100)
        for bounds in [(-1, 0, 10, 10), (0, 0, 0, 10), (0, 0, 101, 10)]:
            with self.subTest(bounds=bounds), self.assertRaises(ValueError):
                _absolute_capture_rect(monitor, bounds)

    def test_bgra_conversion_has_rgb_order_and_owned_memory(self) -> None:
        class FakeGdi:
            @staticmethod
            def GetDIBits(_dc, _bitmap, _start, height, buffer, _info, _usage):
                for index, value in enumerate((30, 20, 10, 255, 60, 50, 40, 255)):
                    buffer[index] = value
                return height

        frame = _read_owned_rgb(FakeGdi(), 1, 1, 2, 1)
        self.assertEqual(frame.tolist(), [[[10, 20, 30], [40, 50, 60]]])
        self.assertTrue(frame.flags.owndata)


class MatrixLocatorTests(unittest.TestCase):
    def _frame_with_markers(self, positions: list[tuple[int, int]]) -> np.ndarray:
        frame = np.zeros((80, 120, 3), dtype=np.uint8)
        height, width = MARKER_TEMPLATE.shape[:2]
        for left, top in positions:
            frame[top : top + height, left : left + width] = MARKER_TEMPLATE
        return frame

    def test_exactly_two_markers_form_complete_bounds(self) -> None:
        self.assertEqual(
            locate_matrix(self._frame_with_markers([(4, 8), (84, 60)])),
            (4, 8, 92, 68),
        )

    def test_other_marker_counts_fail(self) -> None:
        for positions in [[], [(4, 8)], [(4, 8), (40, 30), (84, 60)]]:
            with self.subTest(count=len(positions)):
                self.assertIsNone(locate_matrix(self._frame_with_markers(positions)))

    def test_two_markers_with_unaligned_width_or_height_fail(self) -> None:
        for positions in [[(4, 8), (85, 60)], [(4, 8), (84, 61)]]:
            with self.subTest(positions=positions):
                self.assertIsNone(locate_matrix(self._frame_with_markers(positions)))

    def test_invalid_inputs_are_rejected(self) -> None:
        with self.assertRaises(TypeError):
            locate_matrix(object())  # type: ignore[arg-type]
        with self.assertRaises(ValueError):
            locate_matrix(np.zeros((10, 10), dtype=np.uint8))


if __name__ == "__main__":
    unittest.main()
