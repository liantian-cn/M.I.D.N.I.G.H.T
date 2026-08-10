"""摘要：验证 CaptureWorker 的截图顺序、FPS、停止和失败路径。

描述：用 mock 替换 Win32 与定位纯函数，确认先整屏、再定位、再区域首帧，定时器即时
采用 FPS，所有三类失败均停机且不重试；测试直接调用 worker slot，不启动项目入口。

主要变量信息：``events`` 收集 signal 结果；``monitor`` 是合成物理显示器区域。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增 worker 测试。
"""

from __future__ import annotations

import unittest
from unittest.mock import patch

import numpy as np
from PySide6.QtWidgets import QApplication

from copilot.capture import MonitorRegion
from copilot.workers.capture_worker import CaptureWorker


class CaptureWorkerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def setUp(self) -> None:
        self.monitor = MonitorRegion(0, 0, 200, 100)
        self.full_frame = np.zeros((100, 200, 3), dtype=np.uint8)
        self.region_frame = np.ones((20, 40, 3), dtype=np.uint8)

    def test_start_sequences_full_locate_region_and_stop(self) -> None:
        worker = CaptureWorker()
        frames: list[np.ndarray] = []
        started: list[object] = []
        stopped: list[bool] = []
        worker.frame_ready.connect(frames.append)
        worker.capture_started.connect(started.append)
        worker.capture_stopped.connect(lambda: stopped.append(True))
        with (
            patch("copilot.workers.capture_worker.capture_monitor", return_value=self.full_frame) as full,
            patch("copilot.workers.capture_worker.locate_matrix", return_value=(2, 3, 42, 23)) as locate,
            patch("copilot.workers.capture_worker.capture_region", return_value=self.region_frame) as region,
        ):
            worker.start_capture(self.monitor, 20)
            worker.stop_capture()
        full.assert_called_once_with(self.monitor)
        locate.assert_called_once_with(self.full_frame)
        region.assert_called_once_with(self.monitor, (2, 3, 42, 23))
        self.assertEqual(started, [(2, 3, 42, 23)])
        self.assertIs(frames[0], self.region_frame)
        self.assertEqual(stopped, [True])
        self.assertFalse(worker.is_running)

    def test_live_fps_updates_timer_interval(self) -> None:
        worker = CaptureWorker()
        worker.set_fps(40)
        self.assertEqual(worker._timer.interval(), 25)
        worker.set_fps(1)
        self.assertEqual(worker._timer.interval(), 1000)

    def test_full_capture_failure_stops(self) -> None:
        worker = CaptureWorker()
        failures: list[tuple[str, str]] = []
        worker.capture_failed.connect(lambda code, reason: failures.append((code, reason)))
        with patch(
            "copilot.workers.capture_worker.capture_monitor",
            side_effect=OSError("capture"),
        ):
            worker.start_capture(self.monitor, 30)
        self.assertFalse(worker.is_running)
        self.assertEqual(failures[0][0], "capture_failed")
        self.assertIn("整屏截图失败", failures[0][1])

    def test_localization_failure_stops_without_region_capture(self) -> None:
        worker = CaptureWorker()
        failures: list[tuple[str, str]] = []
        worker.capture_failed.connect(lambda code, reason: failures.append((code, reason)))
        with (
            patch("copilot.workers.capture_worker.capture_monitor", return_value=self.full_frame),
            patch("copilot.workers.capture_worker.locate_matrix", return_value=None),
            patch("copilot.workers.capture_worker.capture_region") as region,
        ):
            worker.start_capture(self.monitor, 30)
        region.assert_not_called()
        self.assertFalse(worker.is_running)
        self.assertEqual(failures[0][0], "matrix_not_found")
        self.assertIn("定位标记", failures[0][1])

    def test_region_failure_stops(self) -> None:
        worker = CaptureWorker()
        failures: list[tuple[str, str]] = []
        worker.capture_failed.connect(lambda code, reason: failures.append((code, reason)))
        with (
            patch("copilot.workers.capture_worker.capture_monitor", return_value=self.full_frame),
            patch("copilot.workers.capture_worker.locate_matrix", return_value=(2, 3, 42, 23)),
            patch(
                "copilot.workers.capture_worker.capture_region",
                side_effect=OSError("region"),
            ),
        ):
            worker.start_capture(self.monitor, 30)
        self.assertFalse(worker.is_running)
        self.assertEqual(failures[0][0], "capture_failed")
        self.assertIn("矩阵区域截图失败", failures[0][1])


if __name__ == "__main__":
    unittest.main()
