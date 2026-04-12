import atexit
import ctypes
import importlib
import subprocess
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace

import pytest
from PySide6.QtWidgets import QMessageBox

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def _load_terminal(
    monkeypatch: pytest.MonkeyPatch,
    *,
    last_error: int = 0,
    is_admin: bool = True,
) -> tuple[object, list[tuple[str, object]], list[tuple[object, tuple[object, ...]]]]:
    calls: list[tuple[str, object]] = []
    registrations: list[tuple[object, tuple[object, ...]]] = []

    class FakeKernel32:
        def CreateMutexW(self, security_attributes: object, initial_owner: bool, mutex_name: str) -> int:
            calls.append(("create", mutex_name))
            return 11

        def GetLastError(self) -> int:
            return last_error

        def ReleaseMutex(self, handle: int) -> None:
            calls.append(("release", handle))

        def CloseHandle(self, handle: int) -> None:
            calls.append(("close", handle))

    fake_signature = '{"has_signature":true,"status":"Valid","signer_subject":"CN=Python Software Foundation"}'

    fake_shell32 = SimpleNamespace(IsUserAnAdmin=lambda: is_admin)
    monkeypatch.setattr(
        ctypes,
        "windll",
        SimpleNamespace(kernel32=FakeKernel32(), shell32=fake_shell32),
        raising=False,
    )
    monkeypatch.setattr(
        subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout=fake_signature, stderr=""),
    )
    monkeypatch.setattr(
        QMessageBox,
        "information",
        lambda parent, title, message: calls.append(("message", message)),
    )
    monkeypatch.setattr(
        atexit,
        "register",
        lambda func, *args: registrations.append((func, args)),
    )

    sys.modules.pop("terminal", None)
    fake_application = ModuleType("terminal.application")
    fake_application.Termnal = object
    monkeypatch.setitem(sys.modules, "terminal.application", fake_application)
    terminal = importlib.import_module("terminal")
    return terminal, calls, registrations


def test_main_only_runs_termnal(monkeypatch: pytest.MonkeyPatch) -> None:
    calls: list[object] = []

    class FakeTermnal:
        def run(self) -> int:
            calls.append("run")
            return 123

    sys.modules.pop("main", None)
    monkeypatch.setitem(sys.modules, "terminal", SimpleNamespace(Termnal=FakeTermnal))
    main = importlib.import_module("main")

    result = main.main()

    assert result == 123
    assert calls == ["run"]


def test_terminal_import_acquires_mutex_and_registers_release(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    terminal, calls, registrations = _load_terminal(monkeypatch)

    assert not hasattr(terminal, "acquire_single_instance_mutex")
    assert not hasattr(terminal, "release_single_instance_mutex")
    assert calls == [("create", "terminal")]
    assert len(registrations) == 1

    release_func, release_args = registrations[0]
    release_func(*release_args)

    assert calls == [
        ("create", "terminal"),
        ("release", 11),
        ("close", 11),
    ]


def test_terminal_import_exits_when_mutex_exists(monkeypatch: pytest.MonkeyPatch) -> None:
    with pytest.raises(SystemExit) as exc_info:
        _load_terminal(monkeypatch, last_error=183)

    assert exc_info.value.code == 0


def test_terminal_import_exits_when_not_running_as_admin(monkeypatch: pytest.MonkeyPatch) -> None:
    with pytest.raises(SystemExit) as exc_info:
        _load_terminal(monkeypatch, is_admin=False)

    assert "管理员" in str(exc_info.value)
