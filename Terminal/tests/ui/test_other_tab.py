import atexit
import ctypes
import importlib
import os
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtWidgets import QApplication

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))


def _import_ui_modules(monkeypatch: pytest.MonkeyPatch):
    fake_signature = '{"has_signature":true,"status":"Valid","signer_subject":"CN=Python Software Foundation"}'
    fake_kernel32 = SimpleNamespace(
        CreateMutexW=lambda *args, **kwargs: 11,
        GetLastError=lambda: 0,
        ReleaseMutex=lambda handle: None,
        CloseHandle=lambda handle: None,
    )
    fake_windll = SimpleNamespace(
        kernel32=fake_kernel32,
        user32=SimpleNamespace(),
        gdi32=SimpleNamespace(),
        shell32=SimpleNamespace(IsUserAnAdmin=lambda: True),
    )

    monkeypatch.setattr(ctypes, "windll", fake_windll, raising=False)
    monkeypatch.setattr(
        subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout=fake_signature, stderr=""),
    )
    monkeypatch.setattr(atexit, "register", lambda *args, **kwargs: None)
    sys.modules.pop("terminal", None)
    sys.modules.pop("terminal.ui.main_window", None)
    sys.modules.pop("terminal.ui.tabs.other", None)
    sys.modules.pop("terminal.pixelcalc.title_manager", None)

    title_manager_module = importlib.import_module("terminal.pixelcalc.title_manager")
    main_window_module = importlib.import_module("terminal.ui.main_window")
    other_tab_module = importlib.import_module("terminal.ui.tabs.other")
    return title_manager_module.TitleManager, main_window_module, other_tab_module.OtherTab


@pytest.fixture(scope="session")
def qapp() -> QApplication:
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    return app


def test_other_tab_shows_empty_state_without_decoded_data(
    monkeypatch: pytest.MonkeyPatch,
    qapp: QApplication,
) -> None:
    _, _, OtherTab = _import_ui_modules(monkeypatch)
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


def test_other_tab_formats_decoded_values(
    monkeypatch: pytest.MonkeyPatch,
    qapp: QApplication,
) -> None:
    _, _, OtherTab = _import_ui_modules(monkeypatch)
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


def test_other_tab_marks_stale_decode_results(
    monkeypatch: pytest.MonkeyPatch,
    qapp: QApplication,
) -> None:
    _, _, OtherTab = _import_ui_modules(monkeypatch)
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
    TitleManager, main_window_module, _ = _import_ui_modules(monkeypatch)
    title_manager = TitleManager(tmp_path / "test.sqlite")

    monkeypatch.setattr(main_window_module, "get_monitors", lambda: [])
    monkeypatch.setattr(main_window_module, "get_windows_by_title", lambda: [])
    monkeypatch.setattr(main_window_module, "get_default_title_manager", lambda: title_manager)

    window = main_window_module.MainWindow()
    try:
        tab_names = [window.tab_widget.tabText(index) for index in range(window.tab_widget.count())]
        assert tab_names.index("插件/专精") < tab_names.index("其他") < tab_names.index("高级设置")
    finally:
        window._shutdown_worker_thread()
        window.deleteLater()
        title_manager.close()
