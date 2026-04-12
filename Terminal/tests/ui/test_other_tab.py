import os
import sys
from pathlib import Path

import pytest
from PySide6.QtWidgets import QApplication

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from terminal.pixelcalc.title_manager import TitleManager
from terminal.ui.main_window import MainWindow
from terminal.ui.tabs.other import OtherTab


@pytest.fixture(scope="session")
def qapp() -> QApplication:
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    return app


def test_other_tab_shows_empty_state_without_decoded_data(qapp: QApplication) -> None:
    tab = OtherTab()

    tab.refresh_from_decode_snapshot(
        {
            "decoded_data": None,
            "decode_result_is_stale": False,
        }
    )

    assert tab.status_label.text() == "暂无其他数据。"
    assert tab.value_inputs["combat_time"].text() == "None"
    assert tab.value_inputs["use_mouse"].text() == "None"
    assert tab.value_inputs["assisted_combat"].text() == "None"
    assert tab.value_inputs["delay"].text() == "None"
    assert tab.value_inputs["testCell"].text() == "None"
    assert tab.value_inputs["enable"].text() == "None"
    assert tab.value_inputs["spell_queue_window"].text() == "None"
    assert tab.value_inputs["burst_time"].text() == "None"
    assert tab.blacklist_inputs["dispel_blacklist"].toPlainText() == ""
    assert tab.blacklist_inputs["interrupt_blacklist"].toPlainText() == ""


def test_other_tab_formats_decoded_values(qapp: QApplication) -> None:
    tab = OtherTab()

    tab.refresh_from_decode_snapshot(
        {
            "decoded_data": {
                "misc": {
                    "combat_time": 12.345,
                    "use_mouse": True,
                },
                "assisted_combat": "冰冷之触",
                "delay": False,
                "testCell": 7,
                "enable": True,
                "dispel_blacklist": ["减益甲", "减益乙"],
                "interrupt_blacklist": ["读条甲", "读条乙"],
                "spell_queue_window": 0.3,
                "burst_time": 18.5,
            },
            "decode_result_is_stale": False,
        }
    )

    assert tab.status_label.text() == "共 10 个综合字段。"
    assert tab.value_inputs["combat_time"].text() == "12.35"
    assert tab.value_inputs["use_mouse"].text() == "True"
    assert tab.value_inputs["assisted_combat"].text() == "冰冷之触"
    assert tab.value_inputs["delay"].text() == "False"
    assert tab.value_inputs["testCell"].text() == "7"
    assert tab.value_inputs["enable"].text() == "True"
    assert tab.value_inputs["spell_queue_window"].text() == "0.30"
    assert tab.value_inputs["burst_time"].text() == "18.50"
    assert tab.blacklist_inputs["dispel_blacklist"].toPlainText() == "减益甲;减益乙"
    assert tab.blacklist_inputs["interrupt_blacklist"].toPlainText() == "读条甲;读条乙"


def test_other_tab_marks_stale_decode_results(qapp: QApplication) -> None:
    tab = OtherTab()

    tab.refresh_from_decode_snapshot(
        {
            "decoded_data": {
                "misc": {
                    "combat_time": 2,
                    "use_mouse": False,
                },
                "assisted_combat": "寒冬号角",
                "delay": True,
                "testCell": 3,
                "enable": False,
                "dispel_blacklist": [],
                "interrupt_blacklist": ["法术甲"],
                "spell_queue_window": 0.25,
                "burst_time": 9,
            },
            "decode_result_is_stale": True,
        }
    )

    assert tab.status_label.text() == "当前显示的是旧数据，最新帧还没解码成功。"
    assert tab.value_inputs["combat_time"].text() == "2"
    assert tab.value_inputs["use_mouse"].text() == "False"
    assert tab.blacklist_inputs["dispel_blacklist"].toPlainText() == ""
    assert tab.blacklist_inputs["interrupt_blacklist"].toPlainText() == "法术甲"


def test_main_window_inserts_other_tab_between_plugin_and_advanced(
    monkeypatch: pytest.MonkeyPatch,
    qapp: QApplication,
    tmp_path: Path,
) -> None:
    title_manager = TitleManager(tmp_path / "test.sqlite")

    monkeypatch.setattr("terminal.ui.main_window.get_monitors", lambda: [])
    monkeypatch.setattr("terminal.ui.main_window.get_windows_by_title", lambda: [])
    monkeypatch.setattr("terminal.ui.main_window.get_default_title_manager", lambda: title_manager)

    window = MainWindow()
    try:
        tab_names = [window.tab_widget.tabText(index) for index in range(window.tab_widget.count())]
        assert tab_names.index("插件/专精") < tab_names.index("其他") < tab_names.index("高级设置")
    finally:
        window._shutdown_worker_thread()
        window.deleteLater()
        title_manager.close()
