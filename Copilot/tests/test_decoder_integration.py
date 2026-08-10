"""验证 DecoderWorker 标题学习和 MainWindow 最新帧、快照与旧值展示链路。"""

from __future__ import annotations

from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import MagicMock

from PySide6.QtWidgets import QApplication

from copilot.decoder.database import prepare_icon_database
from copilot.ui import MainWindow
from copilot.workers import DecoderWorker
from tests.matrix_fixture import build_valid_matrix, set_badge_utf_output, set_player_value

import numpy as np


class DecoderWorkerTests(unittest.TestCase):
    def test_decode_learns_badge_utf_once_without_overwriting(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            prepare_icon_database(path, lambda _reason: False)
            worker = DecoderWorker(path)
            snapshots: list[dict] = []
            worker.title_records_ready.connect(snapshots.append)
            matrix = build_valid_matrix()
            center = np.full((6, 6, 3), 54, dtype=np.uint8)
            set_badge_utf_output(matrix, center, "首次学习")

            worker.decode(matrix)
            worker.request_title_records()
            self.assertEqual(snapshots[-1]["database"][0]["title"], "首次学习")

            set_badge_utf_output(matrix, center, "不应覆盖")
            worker.decode(matrix)
            worker.request_title_records()
            self.assertEqual(snapshots[-1]["database"][0]["title"], "首次学习")
            worker.shutdown()

    def test_success_and_failure_signals(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            prepare_icon_database(path, lambda _reason: False)
            worker = DecoderWorker(path)
            successes: list[dict] = []
            failures: list[str] = []
            worker.decode_succeeded.connect(successes.append)
            worker.decode_failed.connect(failures.append)
            worker.decode(build_valid_matrix())
            worker.decode(object())
            self.assertEqual(len(successes), 1)
            self.assertEqual(len(failures), 1)
            worker.shutdown()

    def test_title_operations_use_worker_manager_and_emit_snapshots(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            prepare_icon_database(path, lambda _reason: False)
            worker = DecoderWorker(path)
            snapshots: list[dict] = []
            successes: list[tuple[str, str]] = []
            failures: list[tuple[str, str]] = []
            worker.title_records_ready.connect(snapshots.append)
            worker.title_operation_succeeded.connect(
                lambda operation, detail: successes.append((operation, detail))
            )
            worker.title_operation_failed.connect(
                lambda operation, reason: failures.append((operation, reason))
            )
            array = np.full((6, 6, 3), 44, dtype=np.uint8)
            from copilot.decoder.title_manager import icon_hash

            worker.add_title_record(
                {
                    "hash": icon_hash(array),
                    "title_type": "PLAYER_SPELL",
                    "title": "Spell",
                    "valid_array": array.tolist(),
                }
            )
            self.assertEqual(successes[0][0], "add")
            self.assertEqual(snapshots[-1]["database"][0]["title"], "Spell")
            worker.set_title_threshold(0.98)
            self.assertEqual(snapshots[-1]["threshold"], 0.98)
            self.assertEqual(failures, [])
            worker.shutdown()


class MainWindowDecodeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def setUp(self) -> None:
        self.temporary_dir = tempfile.TemporaryDirectory()
        self.database_path = Path(self.temporary_dir.name) / "database.sqlite"
        prepare_icon_database(self.database_path, lambda _reason: False)
        self.window = MainWindow(self.database_path)

    def tearDown(self) -> None:
        self.window.close()
        self.app.processEvents()
        self.temporary_dir.cleanup()

    def test_single_flight_keeps_only_latest_pending_frame(self) -> None:
        frames: list[object] = []
        self.window.request_decoder_decode.connect(frames.append)
        first = build_valid_matrix()
        second = build_valid_matrix()
        third = build_valid_matrix()
        self.window.is_running = True
        self.window._queue_decode(first)
        self.window._handle_frame_ready(second)
        self.window._handle_frame_ready(third)
        self.assertEqual(frames, [first])
        self.assertIs(self.window._pending_decode_frame, third)
        self.window._handle_decode_failed("failed")
        self.assertEqual(frames, [first])
        self.assertIsNone(self.window._pending_decode_frame)
        self.assertIsNone(self.window.martix_raw)
        self.assertEqual(self.window.preview_timestamp.text(), "")
        self.window._handle_frame_ready(second)
        self.assertEqual(frames, [first, second])

    def test_success_publication_manual_stop_and_stale_gui_are_separate(self) -> None:
        matrix = build_valid_matrix()
        set_player_value(matrix, 1, 255)
        from copilot.decoder.extractor import extract_matrix

        decoded = extract_matrix(matrix)
        self.window.is_running = True
        self.window._handle_decode_succeeded(decoded)
        self.assertFalse(self.window.martix_data["error"])
        self.assertEqual(len(self.window.martix_data["party"]), 4)
        self.assertEqual(len(self.window.martix_data["raid"]), 30)
        self.assertIsNone(self.window.martix_data["assisted_combat"])
        self.assertEqual(self.window.martix_data["interrupt_blacklist"], [])
        self.assertIsInstance(self.window.martix_data["timestamp"], str)
        self.window.tabs.setCurrentWidget(self.window.player_status_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(
            self.window.player_status_tab.value_inputs["is_alive"].text(),
            "True",
        )

        self.window.stop_capture()
        self.assertTrue(self.window.martix_data["error"])
        self.assertEqual(self.window.martix_data["error_msg"], "not_ready")
        self.window._refresh_visible_tab()
        self.assertEqual(
            self.window.player_status_tab.value_inputs["is_alive"].text(),
            "True",
        )
        self.assertIn("旧数据", self.window.player_status_tab.status_label.text())

    def test_refresh_targets_only_visible_status_tab(self) -> None:
        player_refresh = MagicMock()
        environment_refresh = MagicMock()
        self.window.player_status_tab.refresh_from_decode_snapshot = player_refresh
        self.window.environment_info_tab.refresh_from_decode_snapshot = environment_refresh
        self.window.tabs.setCurrentWidget(self.window.player_status_tab)
        player_refresh.reset_mock()
        environment_refresh.reset_mock()
        self.window._refresh_visible_tab()
        player_refresh.assert_called_once()
        environment_refresh.assert_not_called()

    def test_real_decoder_thread_recovers_and_releases_database(self) -> None:
        self.window._ensure_decoder_thread()
        thread = self.window._decoder_thread
        assert thread is not None
        self.window.is_running = True
        self.window._queue_decode(build_valid_matrix()[:8, :8])
        deadline = time.monotonic() + 2.0
        while self.window.martix_data.get("error_msg") != "decode_failed" and time.monotonic() < deadline:
            self.app.processEvents()
            time.sleep(0.005)
        self.assertEqual(self.window.martix_data.get("error_msg"), "decode_failed")

        self.window._handle_frame_ready(build_valid_matrix())
        deadline = time.monotonic() + 2.0
        while self.window.martix_data.get("error", True) and time.monotonic() < deadline:
            self.app.processEvents()
            time.sleep(0.005)
        self.assertFalse(self.window.martix_data["error"])
        self.assertTrue(self.window.shutdown_decoder_worker())
        self.assertFalse(thread.isRunning())

        from copilot.decoder.title_manager import IconTitleManager

        manager = IconTitleManager(self.database_path)
        manager.close()


if __name__ == "__main__":
    unittest.main()
