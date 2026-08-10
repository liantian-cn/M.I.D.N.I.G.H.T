"""摘要：以 Qt offscreen 验证应用工厂、固定布局、解码表格、日志和关闭生命周期。

描述：创建真实 QApplication 与 MainWindow，但不显示桌面窗口、不运行项目入口。测试
覆盖尺寸、标签顺序、控件边界、无显示器状态、运行状态帧门控、预览时间戳与等比缩放、
日志块上限、错误行红色渲染、滚动跟随、FPS 转发、停止/失败清空、停止后的失败门控，
辅助信息展示，以及活动会话有序停止与 QThread 实际退出确认。

主要变量信息：``window`` 是每个测试独立创建并关闭的主窗口；``frame`` 是合成 RGB 帧。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增 Qt offscreen 测试；
2026-08-01，根据 audit findings 增加活动会话 shutdown 和停止后失败回归。
2026-08-01，根据 Phase 2.6 target/focus 计划扩展 tab 顺序断言为六页角色聚类。
2026-08-01，根据 GUI Log Business Channel 冻结计划把失败门控断言改为 business_log
补丁，并增加错误行红色渲染测试。
2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划扩展 tab 顺序断言为七页，
并新增技能页表格刷新与空态/旧数据测试。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划扩展为八页并新增技能充能页测试。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划扩展为十页并新增固定 Aura 页测试。
2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划扩展为十一页并新增玩家减益页测试。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划扩展为十二页并新增小队页测试。
2026-08-02，根据小队页中文表头需求更新表头、字段映射与窗口内完整显示断言。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 冻结计划扩展为十三页并新增团队页测试。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划新增环境页辅助信息测试。
2026-08-02，根据环境页黑名单布局需求增加左侧五分之一宽度分栏测试。
2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划适配工厂测试的 HTTP worker 启动行为。
"""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

import numpy as np
from PySide6.QtCore import QThread
from PySide6.QtWidgets import QApplication, QLabel, QLineEdit, QPlainTextEdit, QWidget

from copilot.application import create_application
from copilot.capture import MonitorRegion
from copilot.decoder import IncompleteDatabaseCleanupError, prepare_icon_database
from copilot.decoder.title_manager import IconTitleManager, icon_hash
from copilot.ui import MainWindow
from copilot.ui.status_tabs import ResultStatusTab


class MainWindowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def setUp(self) -> None:
        self.temporary_dir = tempfile.TemporaryDirectory()
        database_path = Path(self.temporary_dir.name) / "database.sqlite"
        prepare_icon_database(database_path, lambda _reason: False)
        self.window = MainWindow(database_path)

    def tearDown(self) -> None:
        self.window.shutdown_capture_worker()
        self.window.close()
        self.app.processEvents()
        self.temporary_dir.cleanup()

    def test_fixed_layout_tabs_and_control_defaults(self) -> None:
        self.assertEqual((self.window.width(), self.window.height()), (960, 600))
        self.assertEqual(self.window.settings_strip.height(), 48)
        self.assertEqual(self.window.home_upper_band.height(), 100)
        self.assertEqual(self.window.preview_section.width(), 300)
        self.assertEqual(
            [self.window.tabs.tabText(index) for index in range(13)],
            [
                "Home",
                "玩家属性",
                "玩家增益",
                "玩家减益",
                "小队",
                "团队",
                "技能",
                "技能充能",
                "目标属性",
                "目标减益",
                "焦点属性",
                "环境信息",
                "高级设置",
            ],
        )
        self.assertEqual((self.window.port_spin.minimum(), self.window.port_spin.maximum()), (1, 65535))
        self.assertEqual(self.window.port_spin.value(), 65131)
        self.assertEqual((self.window.fps_slider.minimum(), self.window.fps_slider.maximum()), (1, 40))
        self.assertEqual(self.window.fps_slider.value(), 30)
        self.assertTrue(self.window.title_editor_button.isEnabled())
        self.assertEqual(
            (self.window.threshold_slider.minimum(), self.window.threshold_slider.maximum()),
            (980, 999),
        )
        self.assertEqual(self.window.threshold_value.text(), "0.999")

    def test_monitor_states_and_no_monitor_start(self) -> None:
        self.assertEqual(self.window.monitor_combo.currentText(), "未选择显示器")
        self.window.start_capture()
        self.assertFalse(self.window.is_running)
        monitor = MonitorRegion(-100, 0, 100, 100)
        self.window.set_monitors([monitor])
        self.assertIs(self.window.monitor_combo.currentData(), monitor)

    def test_runtime_gate_preview_timestamp_and_clearing(self) -> None:
        frame = np.zeros((10, 20, 3), dtype=np.uint8)
        self.window._handle_frame_ready(frame)
        self.assertIsNone(self.window.martix_raw)
        self.window.is_running = True
        self.window._handle_frame_ready(frame)
        self.assertIs(self.window.martix_raw, frame)
        self.assertRegex(
            self.window.preview_timestamp.text(),
            r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}$",
        )
        pixmap = self.window.preview_label.pixmap()
        self.assertIsNotNone(pixmap)
        self.assertEqual(pixmap.width() / pixmap.height(), 2.0)
        self.window.stop_capture()
        self.assertIsNone(self.window.martix_raw)
        self.assertEqual(self.window.preview_timestamp.text(), "")
        self.window.is_running = True
        self.window._handle_capture_failed("capture_failed", "failed")
        self.assertFalse(self.window.is_running)
        self.assertIsNone(self.window.martix_raw)

    def test_failure_queued_after_manual_stop_is_ignored(self) -> None:
        self.window.is_running = True
        self.window.stop_capture()
        with patch("copilot.ui.main_window.business_log") as business:
            self.window._handle_capture_failed("capture_failed", "late failure")
        business.assert_not_called()
        self.assertFalse(self.window.is_running)
        self.assertTrue(self.window.monitor_combo.isEnabled())
        self.assertEqual(self.window.capture_button.text(), "开始截图")

    def test_gui_log_is_bounded(self) -> None:
        for index in range(3010):
            self.window.append_gui_log(str(index))
        self.assertLessEqual(self.window.gui_log.document().blockCount(), 3000)

    def test_gui_log_error_line_is_red(self) -> None:
        from PySide6.QtGui import QTextBlock

        self.window.append_gui_log("普通事件")
        self.window.append_gui_log("错误事件", is_error=True)
        document = self.window.gui_log.document()
        normal_block = document.findBlockByNumber(0)
        error_block = document.findBlockByNumber(1)

        def first_fragment_color(block: QTextBlock) -> str | None:
            fragment_iterator = block.begin()
            while not fragment_iterator.atEnd():
                fragment = fragment_iterator.fragment()
                if fragment.isValid() and fragment.text():
                    return fragment.charFormat().foreground().color().name()
                fragment_iterator += 1
            return None

        self.assertNotEqual(
            first_fragment_color(normal_block), first_fragment_color(error_block)
        )
        self.assertEqual(first_fragment_color(error_block), "#b42318")

    def test_gui_log_append_follows_bottom_or_keeps_scroll(self) -> None:
        for index in range(100):
            self.window.append_gui_log(str(index))
        self.window.show()
        self.app.processEvents()
        scrollbar = self.window.gui_log.verticalScrollBar()
        self.assertGreater(scrollbar.maximum(), 0)
        # 位于底部时连续追加新行应持续跟随滚动到底
        scrollbar.setValue(scrollbar.maximum())
        self.app.processEvents()
        for index in range(3):
            self.window.append_gui_log(f"底部追加{index}")
            self.app.processEvents()
        self.assertEqual(scrollbar.value(), scrollbar.maximum())
        # 上翻查看历史后追加新行不应强制滚动
        scrollbar.setValue(0)
        self.app.processEvents()
        self.window.append_gui_log("上翻时追加")
        self.app.processEvents()
        self.assertEqual(scrollbar.value(), 0)

    def test_running_fps_change_is_forwarded(self) -> None:
        values: list[int] = []
        self.window.request_worker_fps.connect(values.append)
        self.window.is_running = True
        self.window.fps_slider.setValue(17)
        self.assertEqual(values, [17])
        self.assertEqual(self.window.fps_value.text(), "17")

    def test_worker_thread_shutdown_is_confirmed(self) -> None:
        self.window._ensure_worker_thread()
        thread = self.window._capture_thread
        self.assertIsNotNone(thread)
        assert thread is not None
        self.assertTrue(thread.isRunning())
        self.assertTrue(self.window.shutdown_capture_worker())
        self.assertFalse(thread.isRunning())

    def test_title_editor_is_available_before_capture_and_reused(self) -> None:
        self.assertIsNone(self.window._decoder_thread)
        self.window._open_title_editor()
        self.app.processEvents()
        dialog = self.window.title_editor_dialog
        self.assertIsNotNone(dialog)
        self.assertIsNotNone(self.window._decoder_thread)
        assert dialog is not None
        self.assertTrue(dialog.isVisible())
        self.window._open_title_editor()
        self.assertIs(self.window.title_editor_dialog, dialog)
        self.assertFalse(self.window.is_running)

    def test_threshold_control_updates_worker_without_persisting_settings(self) -> None:
        values: list[float] = []
        self.window.request_title_threshold.connect(values.append)
        self.window.threshold_slider.setValue(985)
        self.assertEqual(self.window.threshold_value.text(), "0.985")
        self.assertEqual(values, [0.985])
        self.assertIsNotNone(self.window._decoder_thread)

    def test_spell_tab_headers_and_initial_state(self) -> None:
        spell_tab = self.window.spell_tab
        self.assertEqual(
            spell_tab.HEADERS,
            ["index", "技能名称", "法术ID", "冷却", "可用", "高亮", "学会"],
        )
        self.assertEqual(spell_tab.table.columnCount(), 7)
        self.assertEqual(
            [
                spell_tab.table.horizontalHeaderItem(col).text()
                for col in range(spell_tab.table.columnCount())
            ],
            ["index", "技能名称", "法术ID", "冷却", "可用", "高亮", "学会"],
        )
        self.assertEqual(spell_tab.table.rowCount(), 0)
        self.assertEqual(spell_tab.status_label.text(), "暂无技能数据。")

    def test_spell_tab_refresh_populates_table_and_count(self) -> None:
        spell_list = [
            {
                "type": "spell",
                "index": 1,
                "description": "公共冷却",
                "spellId": 61304,
                "cooldown": {
                    "type": "Cell",
                    "classification": "SPELL_COOLDOWN",
                    "index": 1,
                    "raw_value": 247,
                    "result": 96.86,
                },
                "usable": {
                    "type": "Cell",
                    "classification": "SPELL_USABLE",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
                "overlayed": {
                    "type": "Cell",
                    "classification": "SPELL_OVERLAYED",
                    "index": 1,
                    "raw_value": 0,
                    "result": False,
                },
                "known": {
                    "type": "Cell",
                    "classification": "SPELL_KNOWN",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
            },
            {
                "type": "spell",
                "index": 2,
                "description": "胜利在望",
                "spellId": 202168,
                "cooldown": {
                    "type": "Cell",
                    "classification": "SPELL_COOLDOWN",
                    "index": 2,
                    "raw_value": 0,
                    "result": 0.0,
                },
                "usable": {
                    "type": "Cell",
                    "classification": "SPELL_USABLE",
                    "index": 2,
                    "raw_value": 0,
                    "result": False,
                },
                "overlayed": {
                    "type": "Cell",
                    "classification": "SPELL_OVERLAYED",
                    "index": 2,
                    "raw_value": 255,
                    "result": True,
                },
                "known": {
                    "type": "Cell",
                    "classification": "SPELL_KNOWN",
                    "index": 2,
                    "raw_value": 255,
                    "result": True,
                },
            },
        ]
        self.window.spell_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"spell": spell_list}, "decode_result_is_stale": False}
        )
        table = self.window.spell_tab.table
        self.assertEqual(table.rowCount(), 2)
        self.assertEqual(self.window.spell_tab.status_label.text(), "共 2 个技能。")
        # index 1 行：小数冷却保留 1 位，布尔列渲染"是/否"。
        self.assertEqual(table.item(0, 0).text(), "1")
        self.assertEqual(table.item(0, 1).text(), "公共冷却")
        self.assertEqual(table.item(0, 2).text(), "61304")
        self.assertEqual(table.item(0, 3).text(), "96.9")
        self.assertEqual(table.item(0, 4).text(), "是")
        self.assertEqual(table.item(0, 5).text(), "否")
        self.assertEqual(table.item(0, 6).text(), "是")
        # index 2 行：整数冷却显示整数。
        self.assertEqual(table.item(1, 0).text(), "2")
        self.assertEqual(table.item(1, 1).text(), "胜利在望")
        self.assertEqual(table.item(1, 2).text(), "202168")
        self.assertEqual(table.item(1, 3).text(), "0")
        self.assertEqual(table.item(1, 4).text(), "否")
        self.assertEqual(table.item(1, 5).text(), "是")
        self.assertEqual(table.item(1, 6).text(), "是")

    def test_spell_tab_empty_spell_list_clears_table(self) -> None:
        spell_list = [
            {
                "type": "spell",
                "index": 1,
                "description": "公共冷却",
                "spellId": 61304,
                "cooldown": {
                    "type": "Cell",
                    "classification": "SPELL_COOLDOWN",
                    "index": 1,
                    "raw_value": 255,
                    "result": 100.0,
                },
                "usable": {
                    "type": "Cell",
                    "classification": "SPELL_USABLE",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
                "overlayed": {
                    "type": "Cell",
                    "classification": "SPELL_OVERLAYED",
                    "index": 1,
                    "raw_value": 0,
                    "result": False,
                },
                "known": {
                    "type": "Cell",
                    "classification": "SPELL_KNOWN",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
            },
        ]
        spell_tab = self.window.spell_tab
        spell_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"spell": spell_list}, "decode_result_is_stale": False}
        )
        self.assertEqual(spell_tab.table.rowCount(), 1)
        # 再刷新为空列表，表格应清空并回到占位状态。
        spell_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"spell": []}, "decode_result_is_stale": False}
        )
        self.assertEqual(spell_tab.table.rowCount(), 0)
        self.assertEqual(spell_tab.status_label.text(), "暂无技能数据。")

    def test_spell_tab_stale_snapshot_shows_warning(self) -> None:
        spell_list = [
            {
                "type": "spell",
                "index": 1,
                "description": "公共冷却",
                "spellId": 61304,
                "cooldown": {
                    "type": "Cell",
                    "classification": "SPELL_COOLDOWN",
                    "index": 1,
                    "raw_value": 255,
                    "result": 100.0,
                },
                "usable": {
                    "type": "Cell",
                    "classification": "SPELL_USABLE",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
                "overlayed": {
                    "type": "Cell",
                    "classification": "SPELL_OVERLAYED",
                    "index": 1,
                    "raw_value": 0,
                    "result": False,
                },
                "known": {
                    "type": "Cell",
                    "classification": "SPELL_KNOWN",
                    "index": 1,
                    "raw_value": 255,
                    "result": True,
                },
            },
        ]
        self.window.spell_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"spell": spell_list}, "decode_result_is_stale": True}
        )
        self.assertEqual(self.window.spell_tab.table.rowCount(), 1)
        self.assertEqual(
            self.window.spell_tab.status_label.text(),
            "当前显示的是旧数据，最新状态不可用。",
        )

    def test_spell_tab_refreshed_via_main_window_visible_tab(self) -> None:
        # 主窗口 _refresh_visible_tab 应把 _last_success_data 中的 spell 字段刷到技能页。
        self.window._last_success_data = {
            "error": False,
            "spell": [
                {
                    "type": "spell",
                    "index": 1,
                    "description": "公共冷却",
                    "spellId": 61304,
                    "cooldown": {
                        "type": "Cell",
                        "classification": "SPELL_COOLDOWN",
                        "index": 1,
                        "raw_value": 255,
                        "result": 100.0,
                    },
                    "usable": {
                        "type": "Cell",
                        "classification": "SPELL_USABLE",
                        "index": 1,
                        "raw_value": 255,
                        "result": True,
                    },
                    "overlayed": {
                        "type": "Cell",
                        "classification": "SPELL_OVERLAYED",
                        "index": 1,
                        "raw_value": 0,
                        "result": False,
                    },
                    "known": {
                        "type": "Cell",
                        "classification": "SPELL_KNOWN",
                        "index": 1,
                        "raw_value": 255,
                        "result": True,
                    },
                },
            ],
        }
        self.window.martix_data = {"error": False}
        self.window.tabs.setCurrentWidget(self.window.spell_tab)
        self.window._refresh_visible_tab()
        table = self.window.spell_tab.table
        self.assertEqual(table.rowCount(), 1)
        self.assertEqual(table.item(0, 1).text(), "公共冷却")
        self.assertEqual(self.window.spell_tab.status_label.text(), "共 1 个技能。")

    def test_charge_tab_headers_initial_and_empty_states(self) -> None:
        charge_tab = self.window.charge_tab
        self.assertEqual(charge_tab.HEADERS, ["index", "技能名称", "法术ID", "最大", "最小", "当前"])
        self.assertEqual(charge_tab.table.columnCount(), 6)
        self.assertEqual(charge_tab.table.rowCount(), 0)
        self.assertEqual(charge_tab.status_label.text(), "暂无技能充能数据。")
        charge_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"charge": []}, "decode_result_is_stale": False}
        )
        self.assertEqual(charge_tab.table.rowCount(), 0)
        self.assertEqual(charge_tab.status_label.text(), "暂无技能充能数据。")

    def test_charge_tab_refresh_preserves_values_and_stale_state(self) -> None:
        charge = {
            "type": "charge",
            "index": 1,
            "description": "投掷利刃",
            "spellId": 185123,
            "minValue": 0,
            "maxValue": 2,
            "raw_value": 0.125,
            "result": 0.25,
        }
        charge_tab = self.window.charge_tab
        charge_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"charge": [charge]}, "decode_result_is_stale": False}
        )
        self.assertEqual(charge_tab.table.rowCount(), 1)
        self.assertEqual(
            [charge_tab.table.item(0, column).text() for column in range(6)],
            ["1", "投掷利刃", "185123", "2", "0", "0.25"],
        )
        self.assertEqual(charge_tab.status_label.text(), "共 1 个充能技能。")
        charge_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"charge": [charge]}, "decode_result_is_stale": True}
        )
        self.assertEqual(charge_tab.status_label.text(), "当前显示的是旧数据，最新状态不可用。")

    def test_charge_is_published_and_refreshed_via_main_window(self) -> None:
        charge = {
            "type": "charge",
            "index": 1,
            "description": "投掷利刃",
            "spellId": 185123,
            "minValue": 0,
            "maxValue": 2,
            "raw_value": 0.5,
            "result": 1.0,
        }
        self.window.is_running = True
        self.window._handle_decode_succeeded({"charge": [charge]})
        self.assertEqual(self.window.martix_data["charge"], [charge])
        self.assertEqual(self.window._last_success_data["charge"], [charge])
        self.window.tabs.setCurrentWidget(self.window.charge_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(self.window.charge_tab.table.rowCount(), 1)
        self.assertEqual(self.window.charge_tab.table.item(0, 5).text(), "1.0")

    def test_aura_tabs_headers_initial_and_empty_states(self) -> None:
        expected_headers = [
            "index",
            "技能名称",
            "法术ID",
            "持续时间百分比",
            "层数最小",
            "层数最大",
            "层数当前",
        ]
        cases = (
            (self.window.player_buff_tab, "暂无玩家增益数据。", "player_buff"),
            (self.window.target_debuff_tab, "暂无目标减益数据。", "target_debuff"),
        )
        for aura_tab, empty_text, data_key in cases:
            with self.subTest(data_key=data_key):
                self.assertEqual(aura_tab.HEADERS, expected_headers)
                self.assertEqual(aura_tab.table.columnCount(), 7)
                self.assertEqual(aura_tab.table.rowCount(), 0)
                self.assertEqual(aura_tab.status_label.text(), empty_text)
                aura_tab.refresh_from_decode_snapshot(
                    {"decoded_data": {data_key: []}, "decode_result_is_stale": False}
                )
                self.assertEqual(aura_tab.table.rowCount(), 0)
                self.assertEqual(aura_tab.status_label.text(), empty_text)

    def test_aura_tab_formats_values_and_stale_state(self) -> None:
        aura = {
            "type": "aura_slot",
            "index": 1,
            "description": "爪子",
            "spellId": [1126, 432661],
            "duration": {"raw_value": 0.88, "result": 12.0},
            "application": {
                "raw_value": 0.5,
                "minValue": 0,
                "maxValue": 2,
                "result": 1.0,
            },
        }
        aura_tab = self.window.player_buff_tab
        aura_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"player_buff": [aura]}, "decode_result_is_stale": False}
        )

        self.assertEqual(aura_tab.table.rowCount(), 1)
        self.assertEqual(
            [aura_tab.table.item(0, column).text() for column in range(7)],
            ["1", "爪子", "1126;432661", "12.0", "0", "2", "1.0"],
        )
        self.assertEqual(aura_tab.status_label.text(), "共 1 个玩家增益。")

        aura_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"player_buff": [aura]}, "decode_result_is_stale": True}
        )
        self.assertEqual(
            aura_tab.status_label.text(), "当前显示的是旧数据，最新状态不可用。"
        )

    def test_aura_lists_are_published_and_refreshed_via_main_window(self) -> None:
        player_buff = {
            "type": "aura_slot",
            "index": 1,
            "description": "爪子",
            "spellId": [1126, 432661],
            "duration": {"raw_value": 0.88, "result": 12.0},
            "application": {
                "raw_value": 0.5,
                "minValue": 0,
                "maxValue": 2,
                "result": 1.0,
            },
        }
        target_debuff = {
            **player_buff,
            "description": "月火术",
            "spellId": [164812, 8921],
        }
        self.window.is_running = True
        self.window._handle_decode_succeeded(
            {"player_buff": [player_buff], "target_debuff": [target_debuff]}
        )

        self.assertEqual(self.window.martix_data["player_buff"], [player_buff])
        self.assertEqual(self.window.martix_data["target_debuff"], [target_debuff])
        self.assertEqual(self.window._last_success_data["player_buff"], [player_buff])
        self.window.tabs.setCurrentWidget(self.window.target_debuff_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(self.window.target_debuff_tab.table.rowCount(), 1)
        self.assertEqual(self.window.target_debuff_tab.table.item(0, 1).text(), "月火术")

    def test_player_debuff_tab_headers_empty_values_and_stale_state(self) -> None:
        aura_tab = self.window.player_debuff_tab
        self.assertEqual(aura_tab.HEADERS, ["技能名称", "持续时间百分比", "层数当前"])
        self.assertEqual(aura_tab.table.columnCount(), 3)
        self.assertEqual(aura_tab.table.rowCount(), 0)
        self.assertEqual(aura_tab.status_label.text(), "暂无玩家减益数据。")
        aura = {
            "type": "aura_group",
            "icon": {
                "type": "IconCell",
                "icon_hash": "abc123",
                "icon_category": None,
                "result": "abc123",
            },
            "duration": {"raw_value": 0.12, "result": 12.0},
            "application": {
                "raw_value": 0.5,
                "minValue": 0,
                "maxValue": 4,
                "result": 2.0,
            },
        }
        aura_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"player_debuff": [aura]}, "decode_result_is_stale": False}
        )
        self.assertEqual(
            [aura_tab.table.item(0, column).text() for column in range(3)],
            ["abc123", "12.0", "2.0"],
        )
        self.assertEqual(aura_tab.status_label.text(), "共 1 个玩家减益。")
        aura_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"player_debuff": [aura]}, "decode_result_is_stale": True}
        )
        self.assertEqual(
            aura_tab.status_label.text(), "当前显示的是旧数据，最新状态不可用。"
        )
        aura_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"player_debuff": []}, "decode_result_is_stale": False}
        )
        self.assertEqual(aura_tab.table.rowCount(), 0)
        self.assertEqual(aura_tab.status_label.text(), "暂无玩家减益数据。")

    def test_player_debuff_is_published_and_refreshed_via_main_window(self) -> None:
        aura = {
            "type": "aura_group",
            "icon": {
                "type": "IconCell",
                "icon_hash": "hash",
                "icon_category": None,
                "result": "hash",
            },
            "duration": {"raw_value": 0.5, "result": 50.0},
            "application": {
                "raw_value": 0.25,
                "minValue": 0,
                "maxValue": 4,
                "result": 1.0,
            },
        }
        self.window.is_running = True
        self.window._handle_decode_succeeded({"player_debuff": [aura]})

        self.assertEqual(self.window.martix_data["player_debuff"], [aura])
        self.assertEqual(self.window._last_success_data["player_debuff"], [aura])
        self.window.tabs.setCurrentWidget(self.window.player_debuff_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(self.window.player_debuff_tab.table.rowCount(), 1)
        self.assertEqual(self.window.player_debuff_tab.table.item(0, 0).text(), "hash")

    def test_party_tab_fixed_headers_values_empty_columns_and_stale_state(self) -> None:
        party_tab = self.window.party_tab
        self.assertEqual(party_tab.table.columnCount(), 16)
        self.assertEqual(
            party_tab.HEADERS,
            [
                "单位", "存在", "目标", "职责", "range", "血量", "吸收",
                "吸奶", "buff", "可驱", "减伤", "hot1", "hot2", "hot3",
                "hot4", "hot5",
            ],
        )
        visible_headers = []
        for column in range(party_tab.table.columnCount()):
            header_item = party_tab.table.horizontalHeaderItem(column)
            self.assertIsNotNone(header_item)
            visible_headers.append(header_item.text() if header_item is not None else "")
        self.assertEqual(visible_headers, party_tab.HEADERS)
        self.assertEqual(
            party_tab.STATUS_FIELDS,
            [
                "exists", "target", "role", "range", "health", "damage_absorb",
                "heal_absorb", "buff", "dispellable", "big_defensive",
            ],
        )
        self.assertEqual(party_tab.table.rowCount(), 0)
        self.assertEqual(party_tab.status_label.text(), "暂无小队数据。")
        self.window.show()
        self.window.tabs.setCurrentWidget(party_tab)
        self.app.processEvents()
        self.assertLessEqual(
            sum(party_tab.COLUMN_WIDTHS), party_tab.table.viewport().width()
        )

        def cell(result: object) -> dict[str, object]:
            return {"result": result}

        member = {
            "type": "party_info",
            "index": 1,
            "exists": cell(True),
            "target": cell(False),
            "role": cell("HEALER"),
            "range": cell(True),
            "health": cell(99.5),
            "damage_absorb": cell(False),
            "heal_absorb": cell(False),
            "buff": cell(True),
            "dispellable": cell(False),
            "big_defensive": cell(True),
            "hots": [
                {"index": 1, "duration_result": 12.0},
                {"index": 4, "duration_result": 0.0},
            ],
        }
        party_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"party": [member]}, "decode_result_is_stale": False}
        )
        self.assertEqual(
            [party_tab.table.item(0, column).text() for column in range(16)],
            [
                "party1", "True", "False", "HEALER", "True", "99.5",
                "False", "False", "True", "False", "True", "12.0", "", "",
                "0.0", "",
            ],
        )
        self.assertEqual(party_tab.status_label.text(), "共 1 名小队成员。")
        party_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"party": [member]}, "decode_result_is_stale": True}
        )
        self.assertEqual(
            party_tab.status_label.text(), "当前显示的是旧数据，最新状态不可用。"
        )

    def test_party_is_published_and_refreshed_via_main_window(self) -> None:
        party = [{
            "type": "party_info",
            "index": 2,
            "exists": {"result": False},
            "target": None,
            "role": None,
            "range": None,
            "health": None,
            "damage_absorb": None,
            "heal_absorb": None,
            "buff": None,
            "dispellable": None,
            "big_defensive": None,
            "hots": None,
        }]
        self.window.is_running = True
        self.window._handle_decode_succeeded({"party": party})

        self.assertEqual(self.window.martix_data["party"], party)
        self.assertEqual(self.window._last_success_data["party"], party)
        self.window.tabs.setCurrentWidget(self.window.party_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(self.window.party_tab.table.item(0, 0).text(), "party2")
        self.assertEqual(self.window.party_tab.table.item(0, 1).text(), "False")

    def test_raid_tab_fixed_headers_values_and_stale_state(self) -> None:
        raid_tab = self.window.raid_tab
        self.assertEqual(raid_tab.table.columnCount(), 13)
        self.assertEqual(
            raid_tab.HEADERS,
            [
                "单位", "存在", "目标", "职责", "range", "血量", "吸收",
                "可驱", "hot1", "hot2", "hot3", "hot4", "hot5",
            ],
        )
        self.assertEqual(
            raid_tab.STATUS_FIELDS,
            [
                "exists", "target", "role", "range", "health",
                "damage_absorb", "dispellable",
            ],
        )
        self.assertEqual(raid_tab.table.rowCount(), 0)
        self.assertEqual(raid_tab.status_label.text(), "暂无团队数据。")
        self.window.show()
        self.window.tabs.setCurrentWidget(raid_tab)
        self.app.processEvents()
        self.assertLessEqual(
            sum(raid_tab.COLUMN_WIDTHS), raid_tab.table.viewport().width()
        )

        def cell(result: object) -> dict[str, object]:
            return {"result": result}

        member = {
            "type": "raid_info",
            "index": 30,
            "exists": cell(True),
            "target": cell(False),
            "role": cell("HEALER"),
            "range": cell(True),
            "health": cell(99.5),
            "damage_absorb": cell(False),
            "dispellable": cell(True),
            "hots": [
                {"index": 1, "cell": cell(True)},
                {"index": 4, "cell": cell(False)},
            ],
        }
        raid_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"raid": [member]}, "decode_result_is_stale": False}
        )
        self.assertEqual(
            [raid_tab.table.item(0, column).text() for column in range(13)],
            [
                "raid30", "True", "False", "HEALER", "True", "99.5",
                "False", "True", "True", "", "", "False", "",
            ],
        )
        self.assertEqual(raid_tab.status_label.text(), "共 1 名团队成员。")
        raid_tab.refresh_from_decode_snapshot(
            {"decoded_data": {"raid": [member]}, "decode_result_is_stale": True}
        )
        self.assertEqual(
            raid_tab.status_label.text(), "当前显示的是旧数据，最新状态不可用。"
        )

    def test_raid_is_published_and_refreshed_via_main_window(self) -> None:
        raid = [{
            "type": "raid_info",
            "index": 2,
            "exists": {"result": False},
            "target": None,
            "role": None,
            "range": None,
            "health": None,
            "damage_absorb": None,
            "dispellable": None,
            "hots": None,
        }]
        self.window.is_running = True
        self.window._handle_decode_succeeded({"raid": raid})

        self.assertEqual(self.window.martix_data["raid"], raid)
        self.assertEqual(self.window._last_success_data["raid"], raid)
        self.window.tabs.setCurrentWidget(self.window.raid_tab)
        self.window._refresh_visible_tab()
        self.assertEqual(self.window.raid_tab.table.item(0, 0).text(), "raid2")
        self.assertEqual(self.window.raid_tab.table.item(0, 1).text(), "False")

    def test_environment_tab_shows_auxiliary_results_and_stale_state(self) -> None:
        assisted = {
            "type": "IconCell",
            "icon_hash": "assist-hash",
            "icon_category": "PLAYER_SPELL",
            "result": "辅助技能",
        }
        blacklist = [
            {
                "type": "IconCell",
                "icon_hash": "known-hash",
                "icon_category": "ENEMY_SPELL_INTERRUPTIBLE",
                "result": "已知读条",
            },
            {
                "type": "IconCell",
                "icon_hash": "unknown-hash",
                "icon_category": "ENEMY_SPELL_INTERRUPTIBLE",
                "result": "unknown-hash",
            },
        ]
        snapshot = {
            "decoded_data": {
                "environment": {},
                "assisted_combat": assisted,
                "interrupt_blacklist": blacklist,
            },
            "decode_result_is_stale": False,
        }

        self.window.environment_info_tab.refresh_from_decode_snapshot(snapshot)

        self.assertEqual(
            self.window.environment_info_tab.value_inputs["assisted_combat"].text(),
            "辅助技能",
        )
        self.assertEqual(
            self.window.environment_info_tab.interrupt_blacklist_input.toPlainText(),
            "已知读条\nunknown-hash",
        )
        snapshot["decode_result_is_stale"] = True
        self.window.environment_info_tab.refresh_from_decode_snapshot(snapshot)
        self.assertIn("旧数据", self.window.environment_info_tab.status_label.text())
        self.assertEqual(
            self.window.environment_info_tab.interrupt_blacklist_input.toPlainText(),
            "已知读条\nunknown-hash",
        )

        self.window.environment_info_tab.refresh_from_decode_snapshot(
            {"decoded_data": None, "decode_result_is_stale": False}
        )
        self.assertEqual(
            self.window.environment_info_tab.interrupt_blacklist_input.toPlainText(),
            "",
        )

    def test_environment_blacklist_uses_left_fifth_column(self) -> None:
        tab = self.window.environment_info_tab
        layout = tab.content_layout

        self.assertEqual(layout.count(), 3)
        self.assertIs(layout.itemAt(0).widget(), tab.interrupt_blacklist_panel)
        self.assertEqual([layout.stretch(index) for index in range(3)], [1, 2, 2])

        self.window.show()
        self.window.tabs.setCurrentWidget(tab)
        self.app.processEvents()

        columns = [layout.itemAt(index).widget() for index in range(3)]
        self.assertTrue(all(column is not None for column in columns))
        assert all(column is not None for column in columns)
        self.assertLess(columns[0].x(), columns[1].x())
        self.assertLess(columns[1].x(), columns[2].x())
        total_column_width = sum(column.width() for column in columns)
        self.assertAlmostEqual(columns[0].width() / total_column_width, 0.2, delta=0.03)
        self.assertGreater(tab.interrupt_blacklist_input.height(), 110)

    def test_auxiliary_fields_publish_through_main_window(self) -> None:
        assisted = {
            "type": "IconCell",
            "icon_hash": "assist-hash",
            "icon_category": "PLAYER_SPELL",
            "result": "辅助技能",
        }
        blacklist = [{"result": "读条"}]
        self.window.is_running = True

        self.window._handle_decode_succeeded(
            {
                "environment": {},
                "assisted_combat": assisted,
                "interrupt_blacklist": blacklist,
            }
        )

        self.assertEqual(self.window.martix_data["assisted_combat"], assisted)
        self.assertEqual(self.window.martix_data["interrupt_blacklist"], blacklist)

    def test_shared_status_layout_uses_compact_density(self) -> None:
        def assert_widget_geometry(tab: QWidget) -> None:
            self.app.processEvents()
            widgets = [
                *tab.findChildren(QLabel),
                *tab.findChildren(QLineEdit),
                *tab.findChildren(QPlainTextEdit),
            ]
            grouped_widgets: dict[QWidget, list[QWidget]] = {}
            for widget in widgets:
                parent = widget.parentWidget()
                self.assertIsNotNone(parent)
                assert parent is not None
                self.assertTrue(widget.isVisibleTo(tab))
                self.assertTrue(parent.rect().contains(widget.geometry()))
                grouped_widgets.setdefault(parent, []).append(widget)
            for siblings in grouped_widgets.values():
                for index, first in enumerate(siblings):
                    for second in siblings[index + 1 :]:
                        self.assertFalse(
                            first.geometry().intersects(second.geometry()),
                            f"{first.objectName()} 与 {second.objectName()} 重叠",
                        )

        layout = self.window.player_status_tab.layout()
        self.assertIsNotNone(layout)
        assert layout is not None
        margins = layout.contentsMargins()
        self.assertEqual(
            (margins.left(), margins.top(), margins.right(), margins.bottom()),
            (5, 5, 5, 5),
        )
        stylesheet = self.window.player_status_tab.styleSheet()
        self.assertIn("padding: 5px 8px 8px 8px", stylesheet)
        self.assertIn("padding: 4px 8px", stylesheet)

        self.window.show()
        for tab in (self.window.player_status_tab, self.window.environment_info_tab):
            self.window.tabs.setCurrentWidget(tab)
            self.app.processEvents()
            assert_widget_geometry(tab)

        class FutureStatusTab(ResultStatusTab):
            SECTION_DEFINITIONS = [("未来分区", [("future", "未来字段")])]

            def _select_fields(self, decoded_data):
                return decoded_data if isinstance(decoded_data, dict) else None

        future_tab = FutureStatusTab()
        future_tab.resize(800, 500)
        future_tab.show()
        self.app.processEvents()
        future_layout = future_tab.layout()
        assert future_layout is not None
        self.assertEqual(future_layout.contentsMargins().top(), 5)
        self.assertIn("padding: 4px 8px", future_tab.styleSheet())
        assert_widget_geometry(future_tab)
        future_tab.close()

    def test_title_database_operations_run_in_decoder_qthread(self) -> None:
        calls: list[tuple[str, QThread]] = []

        class RecordingManager(IconTitleManager):
            def __init__(self, *args, **kwargs) -> None:
                calls.append(("init", QThread.currentThread()))
                super().__init__(*args, **kwargs)

            def add_record(self, *args, **kwargs):
                calls.append(("add", QThread.currentThread()))
                return super().add_record(*args, **kwargs)

            def update_record(self, *args, **kwargs) -> None:
                calls.append(("update", QThread.currentThread()))
                super().update_record(*args, **kwargs)

            def set_similarity_threshold(self, *args, **kwargs) -> None:
                calls.append(("threshold", QThread.currentThread()))
                super().set_similarity_threshold(*args, **kwargs)

            def delete_record(self, *args, **kwargs) -> None:
                calls.append(("delete", QThread.currentThread()))
                super().delete_record(*args, **kwargs)

        def wait_until(predicate) -> None:
            deadline = time.monotonic() + 2.0
            while not predicate() and time.monotonic() < deadline:
                self.app.processEvents()
                time.sleep(0.005)
            self.assertTrue(predicate())

        with patch(
            "copilot.workers.decoder_worker.IconTitleManager", RecordingManager
        ):
            self.window._ensure_decoder_thread()
            thread = self.window._decoder_thread
            worker = self.window._decoder_worker
            assert thread is not None
            assert worker is not None
            events: list[str] = []
            worker.title_records_ready.connect(lambda _snapshot: events.append("snapshot"))
            worker.title_operation_succeeded.connect(
                lambda operation, _detail: events.append(operation)
            )
            self.window.request_title_records.emit()
            wait_until(lambda: bool(calls))

            array = np.full((6, 6, 3), 77, dtype=np.uint8)
            record_hash = icon_hash(array)
            self.window.request_title_add.emit(
                {
                    "hash": record_hash,
                    "title_type": "PLAYER_SPELL",
                    "title": "Thread Spell",
                    "valid_array": array.tolist(),
                }
            )
            wait_until(lambda: "add" in events)
            self.window.request_title_update.emit(record_hash, "Updated")
            wait_until(lambda: "update" in events)
            self.window.request_title_threshold.emit(0.98)
            wait_until(lambda: "threshold" in events)
            self.window.request_title_delete.emit(record_hash)
            wait_until(lambda: "delete" in events)

            self.assertTrue(all(call_thread is thread for _name, call_thread in calls))
            for operation in ("add", "update", "threshold", "delete"):
                operation_index = events.index(operation)
                self.assertEqual(events[operation_index - 1], "snapshot")

    def test_active_session_shutdown_stops_worker_before_thread_exit(self) -> None:
        monitor = MonitorRegion(0, 0, 200, 100)
        self.window.set_monitors([monitor])
        full_frame = np.zeros((100, 200, 3), dtype=np.uint8)
        region_frame = np.ones((20, 40, 3), dtype=np.uint8)
        stopped: list[bool] = []
        with (
            patch(
                "copilot.workers.capture_worker.capture_monitor",
                return_value=full_frame,
            ),
            patch(
                "copilot.workers.capture_worker.locate_matrix",
                return_value=(2, 3, 42, 23),
            ),
            patch(
                "copilot.workers.capture_worker.capture_region",
                return_value=region_frame,
            ),
        ):
            self.window.start_capture()
            worker = self.window._capture_worker
            thread = self.window._capture_thread
            assert worker is not None
            assert thread is not None
            worker.capture_stopped.connect(lambda: stopped.append(True))
            deadline = time.monotonic() + 1.0
            while not worker.is_running and time.monotonic() < deadline:
                self.app.processEvents()
                time.sleep(0.005)
            self.assertTrue(worker.is_running)
            self.assertTrue(worker._timer.isActive())
            self.assertTrue(self.window.shutdown_capture_worker())
        self.assertEqual(stopped, [True])
        self.assertFalse(worker.is_running)
        self.assertFalse(thread.isRunning())

    def test_worker_thread_timeout_is_not_ignored(self) -> None:
        class StuckThread:
            def __init__(self) -> None:
                self.quit_requested = False

            def isRunning(self) -> bool:
                return True

            def wait(self, _timeout_ms: int) -> bool:
                return False

        thread = StuckThread()
        self.window._capture_thread = thread  # type: ignore[assignment]
        self.window._capture_worker = object()  # type: ignore[assignment]
        self.window.request_worker_shutdown.connect(
            lambda: setattr(thread, "quit_requested", True)
        )
        self.assertFalse(self.window.shutdown_capture_worker(timeout_ms=1))
        self.assertTrue(thread.quit_requested)
        self.assertIs(self.window._capture_thread, thread)
        self.window._capture_thread = None
        self.window._capture_worker = None


class ApplicationFactoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def test_factory_starts_http_worker_keeps_capture_and_decode_lazy(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            (base / "settings.json").write_text(
                json.dumps({"logging": {"file_enabled": False}}), encoding="utf-8"
            )
            with patch("copilot.application.enumerate_monitors", return_value=[]):
                app, window, runtime = create_application([], base)
            self.app.processEvents()
            self.assertIs(app, self.app)
            # 捕获与解码 worker 仍保持懒启动
            self.assertIsNone(window._capture_thread)
            self.assertIsNone(window._decoder_thread)
            # HTTP worker 已随应用启动（默认 65131 被占用时只走隔离路径）
            self.assertTrue(window._http_started)
            self.assertTrue((base / "database.sqlite").exists())
            self.assertFalse(window.file_log_status.isVisible())
            self.assertIn("应用初始化完成", window.gui_log.toPlainText())
            # teardown 干净关闭 HTTP worker，不残留线程或端口
            self.assertTrue(window.shutdown_http_worker())
            runtime.close()
            window.close()

    def test_factory_keeps_file_log_failure_status_for_run(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            occupied_parent = base / "occupied"
            occupied_parent.write_text("not a directory", encoding="utf-8")
            (base / "settings.json").write_text(
                json.dumps({"logging": {"path": "occupied/app.log"}}),
                encoding="utf-8",
            )
            with patch("copilot.application.enumerate_monitors", return_value=[]):
                _app, window, runtime = create_application([], base)
            self.app.processEvents()
            self.assertFalse(window.file_log_status.isHidden())
            self.assertIn("文件日志初始化失败", window.gui_log.toPlainText())
            runtime.close()
            window.close()

    def test_factory_reports_residual_database_path_after_cleanup_failure(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            residual_path = base / "database.sqlite"
            (base / "settings.json").write_text(
                json.dumps({"logging": {"file_enabled": False}}),
                encoding="utf-8",
            )
            with (
                patch(
                    "copilot.application.prepare_icon_database",
                    side_effect=IncompleteDatabaseCleanupError(residual_path),
                ),
                patch("copilot.application.QMessageBox.critical") as critical,
                self.assertRaises(IncompleteDatabaseCleanupError),
            ):
                create_application([], base)
            message = critical.call_args.args[2]
            self.assertIn(str(residual_path), message)
            self.assertIn("仍残留", message)


if __name__ == "__main__":
    unittest.main()
