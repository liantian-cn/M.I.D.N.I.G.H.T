import atexit
import ctypes
import importlib
import os
import subprocess
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def _import_application(monkeypatch: pytest.MonkeyPatch):
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
    fake_main_window = ModuleType("terminal.ui.main_window")
    fake_main_window.MainWindow = object

    monkeypatch.setattr(ctypes, "windll", fake_windll, raising=False)
    monkeypatch.setattr(
        subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout=fake_signature, stderr=""),
    )
    monkeypatch.setattr(atexit, "register", lambda *args, **kwargs: None)
    monkeypatch.setitem(sys.modules, "terminal.ui.main_window", fake_main_window)
    sys.modules.pop("terminal", None)
    sys.modules.pop("terminal.application", None)
    return importlib.import_module("terminal.application")


def test_set_windows_app_user_model_id_calls_win32_api(monkeypatch: pytest.MonkeyPatch) -> None:
    application = _import_application(monkeypatch)
    received_app_ids: list[str] = []

    def fake_set_current_process_explicit_app_user_model_id(app_id: str) -> None:
        received_app_ids.append(app_id)

    fake_shell32 = SimpleNamespace(
        SetCurrentProcessExplicitAppUserModelID=fake_set_current_process_explicit_app_user_model_id
    )
    fake_windll = SimpleNamespace(shell32=fake_shell32)

    monkeypatch.setattr(application.sys, "platform", "win32")
    monkeypatch.setattr(application.ctypes, "windll", fake_windll, raising=False)

    application._set_windows_app_user_model_id()

    assert received_app_ids == ["midnight.terminal"]


def test_set_windows_app_user_model_id_skips_non_windows(monkeypatch: pytest.MonkeyPatch) -> None:
    application = _import_application(monkeypatch)
    monkeypatch.setattr(application.sys, "platform", "linux")

    application._set_windows_app_user_model_id()


def test_set_windows_app_user_model_id_ignores_win32_errors(monkeypatch: pytest.MonkeyPatch) -> None:
    application = _import_application(monkeypatch)

    def fake_set_current_process_explicit_app_user_model_id(app_id: str) -> None:
        raise OSError(app_id)

    fake_shell32 = SimpleNamespace(
        SetCurrentProcessExplicitAppUserModelID=fake_set_current_process_explicit_app_user_model_id
    )
    fake_windll = SimpleNamespace(shell32=fake_shell32)

    monkeypatch.setattr(application.sys, "platform", "win32")
    monkeypatch.setattr(application.ctypes, "windll", fake_windll, raising=False)

    application._set_windows_app_user_model_id()


def test_termnal_run_sets_application_and_window_icons(monkeypatch: pytest.MonkeyPatch) -> None:
    application = _import_application(monkeypatch)
    captured: dict[str, object] = {}

    class FakeApplication:
        def __init__(self) -> None:
            self.window_icon = None

        def setWindowIcon(self, icon: object) -> None:
            self.window_icon = icon

        def exec(self) -> int:
            return 123

    class FakeMainWindow:
        def __init__(self) -> None:
            self.window_icon = None
            self.shown = False

        def setWindowIcon(self, icon: object) -> None:
            self.window_icon = icon

        def show(self) -> None:
            self.shown = True

    fake_application = FakeApplication()
    fake_icon = object()

    monkeypatch.setattr(application, "create_qapplication", lambda argv: fake_application)
    monkeypatch.setattr(application, "get_logo_icon", lambda: fake_icon)
    monkeypatch.setattr(application, "MainWindow", FakeMainWindow)

    termnal = application.Termnal()

    result = termnal.run()

    captured["app_icon"] = fake_application.window_icon
    captured["window"] = termnal.window

    assert result == 123
    assert captured["app_icon"] is fake_icon
    assert isinstance(captured["window"], FakeMainWindow)
    assert captured["window"].window_icon is fake_icon
    assert captured["window"].shown is True
