"""摘要：验证 Phase 3.0 HTTP 输出：handler、序列化回退、worker 与主窗口接线。

描述：用 unittest 覆盖快照 handler 的 GET/POST/OPTIONS/PUT/DELETE/HEAD 行为、
五种错误枚举、时间戳稳定性、CORS 头、datetime 注入序列化、序列化失败回退与
预编码 bytes、失败响应不含本地细节；用真实 MainWindow + HTTPServer + QThread
验证初始 not_ready 快照、快照生命周期、worker 启动/关闭释放端口、绑定失败隔离、
端口修改提示与 closeEvent 关闭顺序。快乐路径使用动态空闲端口。

主要变量信息：``window`` 是每个 MainWindow 集成测试独立创建并关闭的主窗口；
``_free_port`` 提供动态空闲端口；``_request`` 对连接拒绝自动重试等待服务就绪。

修改记录：2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划新增。
2026-08-09，根据审计 finding 修复 _start_server 重复调用的旧 server 泄漏，并把
读取器失败测试改为断言发布方回退时间戳（SnapshotReaderError 路径）。
"""

from __future__ import annotations

from datetime import datetime
from functools import partial
import http.client
from http.server import HTTPServer
import json
from pathlib import Path
import socket
import tempfile
import threading
import time
import unittest
from unittest.mock import DEFAULT, patch

import numpy as np
from PySide6.QtCore import QThread, Qt
from PySide6.QtGui import QCloseEvent
from PySide6.QtWidgets import QApplication

from copilot.capture import MonitorRegion
from copilot.httpd import (
    SnapshotHandler,
    SnapshotReaderError,
    build_internal_error_fallback,
)
from copilot.ui import MainWindow
from copilot.workers import WebServerWorker


def _free_port() -> int:
    """请求一个刚释放的动态空闲端口。"""

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.bind(("127.0.0.1", 0))
        return probe.getsockname()[1]


def _request(
    method: str,
    path: str,
    port: int,
    body: bytes | None = None,
    timeout: float = 3.0,
) -> tuple[int, dict[str, str], bytes]:
    """发起一次 HTTP 请求；连接被拒（服务未就绪）时重试直到超时。"""

    deadline = time.monotonic() + timeout
    while True:
        try:
            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=2)
            try:
                conn.request(method, path, body=body)
                response = conn.getresponse()
                return response.status, dict(response.getheaders()), response.read()
            finally:
                conn.close()
        except OSError:
            if time.monotonic() >= deadline:
                raise
            time.sleep(0.01)


class SnapshotHandlerTests(unittest.TestCase):
    """handler 级测试：固定读取器的标准库 HTTPServer，运行在后台线程。"""

    def setUp(self) -> None:
        self.snapshot = {
            "error": False,
            "timestamp": "2026-08-09 12:34:56.789",
        }
        self.fallback, self.fallback_bytes = build_internal_error_fallback(
            self.snapshot["timestamp"]
        )
        self.reader_calls: list[str] = []
        self._start_server(self._make_reader())

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.server_thread.join(timeout=2)

    def _make_reader(self) -> object:
        def reader() -> tuple[dict, dict, bytes]:
            self.reader_calls.append("read")
            return self.snapshot, self.fallback, self.fallback_bytes

        return reader

    def _start_server(self, reader: object) -> int:
        # 重复调用前先关闭旧 server，避免残留监听 socket 与 serve_forever 线程
        if getattr(self, "server", None) is not None:
            self.server.shutdown()
            self.server.server_close()
            self.server_thread.join(timeout=2)
        self.server = HTTPServer(
            ("127.0.0.1", 0), partial(SnapshotHandler, reader)
        )
        self.server_thread = threading.Thread(
            target=self.server.serve_forever, daemon=True
        )
        self.server_thread.start()
        self.port = self.server.server_address[1]
        return self.port

    def _assert_json_response(
        self, result: tuple[int, dict[str, str], bytes]
    ) -> dict:
        status, headers, body = result
        self.assertEqual(status, 200)
        self.assertEqual(headers["Content-Type"], "application/json; charset=utf-8")
        self.assertEqual(headers["Content-Length"], str(len(body)))
        self.assertEqual(headers["Access-Control-Allow-Origin"], "*")
        return json.loads(body)

    def test_any_get_path_returns_identical_json(self) -> None:
        first = self._assert_json_response(_request("GET", "/", self.port))
        second = self._assert_json_response(
            _request("GET", "/any/path?query=1", self.port)
        )
        self.assertEqual(first, self.snapshot)
        self.assertEqual(second, first)

    def test_post_with_body_returns_identical_json_and_ignores_body(self) -> None:
        get_body = _request("GET", "/", self.port)[2]
        status, headers, body = _request(
            "POST", "/", self.port, body=b"ignored request body"
        )
        parsed = self._assert_json_response((status, headers, body))
        self.assertEqual(parsed, self.snapshot)
        self.assertEqual(body, get_body)

    def test_options_preflight_without_reading_snapshot(self) -> None:
        reader_calls: list[str] = []
        self._start_server(
            lambda: (
                reader_calls.append("read") or self.snapshot,
                self.fallback,
                self.fallback_bytes,
            )
        )
        status, headers, body = _request("OPTIONS", "/", self.port)
        self.assertEqual(status, 200)
        self.assertEqual(headers["Access-Control-Allow-Origin"], "*")
        self.assertEqual(headers["Access-Control-Allow-Methods"], "GET, POST, OPTIONS")
        self.assertEqual(headers["Access-Control-Allow-Headers"], "Content-Type")
        self.assertEqual(headers["Content-Length"], "0")
        self.assertEqual(body, b"")
        self.assertEqual(reader_calls, [])

    def test_put_delete_head_keep_base_class_default(self) -> None:
        for method in ("PUT", "DELETE", "HEAD"):
            with self.subTest(method=method):
                status, _headers, _body = _request(method, "/", self.port)
                self.assertEqual(status, 501)

    def test_error_snapshots_return_http_200_with_five_error_messages(self) -> None:
        for error_msg in (
            "not_ready",
            "capture_failed",
            "matrix_not_found",
            "decode_failed",
            "internal_error",
        ):
            with self.subTest(error_msg=error_msg):
                snapshot = {
                    "error": True,
                    "error_msg": error_msg,
                    "timestamp": "2026-08-09 12:34:56.789",
                }
                self._start_server(
                    lambda s=snapshot: (s, self.fallback, self.fallback_bytes)
                )
                parsed = self._assert_json_response(_request("GET", "/", self.port))
                self.assertTrue(parsed["error"])
                self.assertEqual(parsed["error_msg"], error_msg)

    def test_consecutive_gets_on_same_snapshot_keep_timestamp(self) -> None:
        first = self._assert_json_response(_request("GET", "/a", self.port))
        second = self._assert_json_response(_request("GET", "/b", self.port))
        self.assertEqual(first["timestamp"], second["timestamp"])

    def test_cors_header_present_on_get_and_post(self) -> None:
        for method in ("GET", "POST"):
            with self.subTest(method=method):
                status, headers, _body = _request(method, "/", self.port)
                self.assertEqual(status, 200)
                self.assertEqual(headers["Access-Control-Allow-Origin"], "*")

    def test_datetime_values_serialized_to_contract_string(self) -> None:
        # 生产快照不保证含 datetime，测试必须向 fixture 注入 datetime 对象
        snapshot = {
            "error": False,
            "timestamp": "2026-08-09 12:34:56.789",
            "decoded_at": datetime(2026, 8, 9, 12, 34, 56, 789000),
        }
        self._start_server(lambda: (snapshot, self.fallback, self.fallback_bytes))
        parsed = self._assert_json_response(_request("GET", "/", self.port))
        self.assertEqual(parsed["decoded_at"], "2026-08-09 12:34:56.789")

    def test_serialization_failure_returns_minimal_error_without_overwriting(
        self,
    ) -> None:
        bad_snapshot = {
            "error": False,
            "timestamp": "2026-08-09 00:00:00.000",
            "bad": object(),
        }
        fallback, fallback_bytes = build_internal_error_fallback(
            "2026-08-09 00:00:00.000"
        )
        box = {"snapshot": bad_snapshot}
        self._start_server(lambda: (box["snapshot"], fallback, fallback_bytes))
        parsed = self._assert_json_response(_request("GET", "/", self.port))
        self.assertEqual(parsed, fallback)
        # 共享快照未被覆盖，坏对象仍在原快照中
        self.assertIs(box["snapshot"], bad_snapshot)
        self.assertIn("bad", bad_snapshot)
        # 下一次请求重新读取当前快照
        box["snapshot"] = {"error": False, "timestamp": "2026-08-09 01:00:00.000"}
        repaired = self._assert_json_response(_request("GET", "/", self.port))
        self.assertEqual(repaired, box["snapshot"])

    def test_preencoded_bytes_sent_when_fallback_dict_fails_to_encode(self) -> None:
        pre_encoded = json.dumps(
            {
                "error": True,
                "error_msg": "internal_error",
                "timestamp": "2026-08-09 00:00:00.000",
            }
        ).encode("utf-8")
        bad_snapshot = {
            "error": False,
            "timestamp": "2026-08-09 00:00:00.000",
            "bad": object(),
        }
        bad_fallback = {
            "error": True,
            "error_msg": "internal_error",
            "timestamp": "2026-08-09 00:00:00.000",
            "bad": object(),
        }
        self._start_server(lambda: (bad_snapshot, bad_fallback, pre_encoded))
        status, headers, body = _request("GET", "/", self.port)
        self.assertEqual(status, 200)
        self.assertEqual(headers["Content-Type"], "application/json; charset=utf-8")
        self.assertEqual(body, pre_encoded)

    def test_reader_failure_returns_publisher_fallback_without_local_details(
        self,
    ) -> None:
        def reader() -> tuple[dict, dict, bytes]:
            raise SnapshotReaderError(self.fallback, self.fallback_bytes)

        self._start_server(reader)
        status, _headers, body = _request("GET", "/", self.port)
        self.assertEqual(status, 200)
        parsed = json.loads(body)
        # 最小回退沿用发布方时间戳，不是请求时刻新值
        self.assertEqual(parsed, self.fallback)
        self.assertEqual(parsed["timestamp"], self.snapshot["timestamp"])
        text = body.decode("utf-8")
        self.assertNotIn("Traceback", text)
        self.assertNotIn("OSError", text)


class WebServerWorkerTests(unittest.TestCase):
    """worker 级测试：信号接线、服务响应与关闭后端口释放。"""

    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def test_worker_serve_and_shutdown_release_port(self) -> None:
        snapshot = {"error": False, "timestamp": "2026-08-09 00:00:00.000"}
        fallback, fallback_bytes = build_internal_error_fallback(
            snapshot["timestamp"]
        )
        server = HTTPServer(
            ("127.0.0.1", 0),
            partial(
                SnapshotHandler,
                lambda: (snapshot, fallback, fallback_bytes),
            ),
        )
        port = server.server_address[1]
        thread = QThread()
        worker = WebServerWorker()
        worker.moveToThread(thread)

        # 用真实信号接线模拟主窗口的 request_httpd_start/request_httpd_shutdown
        from PySide6.QtCore import QObject, Signal

        class CommandEmitter(QObject):
            start = Signal(object)
            stop = Signal()

        emitter = CommandEmitter()
        emitter.start.connect(worker.start)
        emitter.stop.connect(worker.shutdown)
        worker.shutdown_ready.connect(
            thread.quit, Qt.ConnectionType.DirectConnection
        )
        thread.finished.connect(worker.deleteLater)
        thread.start()
        emitter.start.emit(server)

        status, _headers, body = _request("GET", "/", port)
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), snapshot)

        # 关闭顺序与主窗口 shutdown_http_worker 一致：先服务循环，再 worker 关闭
        server.shutdown()
        emitter.stop.emit()
        self.assertTrue(thread.wait(5000))
        self.assertFalse(thread.isRunning())

        # 端口已释放，可立即重新绑定
        rebind = HTTPServer(
            ("127.0.0.1", port),
            partial(
                SnapshotHandler,
                lambda: (snapshot, fallback, fallback_bytes),
            ),
        )
        self.assertEqual(rebind.server_address[1], port)
        rebind.server_close()


class HttpIntegrationTests(unittest.TestCase):
    """主窗口集成测试：真实 start_http_worker 接线与快照生命周期。"""

    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def setUp(self) -> None:
        self.temporary_dir = tempfile.TemporaryDirectory()
        self.window = MainWindow(Path(self.temporary_dir.name) / "database.sqlite")

    def tearDown(self) -> None:
        self.window.shutdown_http_worker()
        self.window.shutdown_capture_worker()
        self.window.shutdown_decoder_worker()
        self.window.close()
        self.app.processEvents()
        self.temporary_dir.cleanup()

    def _start_http(self) -> int:
        port = _free_port()
        self.window.port_spin.setValue(port)
        self.window.start_http_worker()
        return port

    def test_initial_not_ready_snapshot_is_served(self) -> None:
        port = self._start_http()
        status, _headers, body = _request("GET", "/", port)
        self.assertEqual(status, 200)
        parsed = json.loads(body)
        self.assertTrue(parsed["error"])
        self.assertEqual(parsed["error_msg"], "not_ready")
        self.assertEqual(parsed["timestamp"], self.window.martix_data["timestamp"])

    def test_snapshot_lifecycle_is_served_over_http(self) -> None:
        port = self._start_http()
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertEqual(parsed["error_msg"], "not_ready")

        # 运行状态下的成功解码发布完整正常快照
        self.window.is_running = True
        self.window._handle_decode_succeeded({"player": {"name": "测试"}})
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertFalse(parsed["error"])
        self.assertEqual(parsed["player"], {"name": "测试"})

        # 手动停止发布新的 not_ready
        self.window.stop_capture()
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertTrue(parsed["error"])
        self.assertEqual(parsed["error_msg"], "not_ready")

        # 失败立即替换为对应错误快照
        self.window.is_running = True
        self.window._handle_decode_failed("测试失败")
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertEqual(parsed["error_msg"], "decode_failed")
        self.window.is_running = True
        self.window._handle_capture_failed("capture_failed", "测试失败")
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertEqual(parsed["error_msg"], "capture_failed")
        self.window._publish_error("matrix_not_found")
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertEqual(parsed["error_msg"], "matrix_not_found")

        # 运行状态下再次成功恢复完整正常快照
        self.window.is_running = True
        self.window._handle_decode_succeeded({"spell": []})
        parsed = json.loads(_request("GET", "/", port)[2])
        self.assertFalse(parsed["error"])
        self.assertEqual(parsed["spell"], [])

    def test_worker_shutdown_releases_port(self) -> None:
        port = self._start_http()
        status, _headers, _body = _request("GET", "/", port)
        self.assertEqual(status, 200)
        self.assertTrue(self.window.shutdown_http_worker())
        self.assertIsNone(self.window._http_thread)
        self.assertIsNone(self.window._http_worker)
        self.assertIsNone(self.window._http_server)
        # 端口已释放，标准库 HTTPServer 可立即重新绑定同一端口
        rebind = HTTPServer(
            ("127.0.0.1", port),
            partial(SnapshotHandler, self.window.get_http_snapshot),
        )
        self.assertEqual(rebind.server_address[1], port)
        rebind.server_close()

    def test_bind_failure_shows_label_creates_no_worker_and_never_shuts_down(
        self,
    ) -> None:
        port = _free_port()
        blocker = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        blocker.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        blocker.bind(("0.0.0.0", port))
        blocker.listen(1)
        try:
            self.window.port_spin.setValue(port)
            with (
                patch("copilot.ui.main_window.business_log") as business,
                patch("socketserver.BaseServer.shutdown") as shutdown,
            ):
                self.window.start_http_worker()
                # GUI 常驻失败标签可见（窗口未显示时按仓库惯例断言 isHidden）
                self.assertFalse(self.window.http_status.isHidden())
                # 不创建 worker 线程，也没有 server 对象
                self.assertIsNone(self.window._http_thread)
                self.assertIsNone(self.window._http_worker)
                self.assertIsNone(self.window._http_server)
                # 关闭路径从不调用 shutdown()
                self.assertTrue(self.window.shutdown_http_worker())
                shutdown.assert_not_called()
            business.assert_called_once()

            # capture/decode 不受影响：仍可正常启动截图 worker
            monitor = MonitorRegion(-100, 0, 100, 100)
            self.window.set_monitors([monitor])
            with (
                patch(
                    "copilot.workers.capture_worker.capture_monitor",
                    return_value=np.zeros((100, 200, 3), dtype=np.uint8),
                ),
                patch(
                    "copilot.workers.capture_worker.locate_matrix",
                    return_value=(2, 3, 42, 23),
                ),
                patch(
                    "copilot.workers.capture_worker.capture_region",
                    return_value=np.ones((20, 40, 3), dtype=np.uint8),
                ),
            ):
                self.window.start_capture()
            self.assertIsNotNone(self.window._capture_thread)
            self.assertTrue(self.window.shutdown_capture_worker())
        finally:
            blocker.close()

    def test_port_change_shows_hint_without_affecting_running_server(self) -> None:
        port = self._start_http()
        server_before = self.window._http_server
        thread_before = self.window._http_thread
        target = port + 1 if port < 65535 else 1
        with patch("copilot.ui.main_window.business_log") as business:
            self.window.port_spin.setValue(target)
        self.assertFalse(self.window.port_restart_hint.isHidden())
        business.assert_called_once()
        # 不重建 server，不热重试
        self.assertIs(self.window._http_server, server_before)
        self.assertIs(self.window._http_thread, thread_before)
        # 运行中的服务仍监听原端口
        status, _headers, body = _request("GET", "/", port)
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), self.window.martix_data)

    def test_close_event_shuts_http_down_before_capture_and_decoder(self) -> None:
        port = self._start_http()
        status, _headers, _body = _request("GET", "/", port)
        self.assertEqual(status, 200)
        calls: list[str] = []

        def record(name: str) -> object:
            def side_effect(*args: object, **kwargs: object) -> object:
                calls.append(name)
                return DEFAULT

            return side_effect

        with (
            patch.object(
                self.window,
                "shutdown_http_worker",
                wraps=self.window.shutdown_http_worker,
                side_effect=record("http"),
            ),
            patch.object(
                self.window,
                "stop_capture",
                wraps=self.window.stop_capture,
                side_effect=record("stop_capture"),
            ),
            patch.object(
                self.window,
                "shutdown_capture_worker",
                wraps=self.window.shutdown_capture_worker,
                side_effect=record("capture"),
            ),
            patch.object(
                self.window,
                "shutdown_decoder_worker",
                wraps=self.window.shutdown_decoder_worker,
                side_effect=record("decoder"),
            ),
        ):
            event = QCloseEvent()
            self.window.closeEvent(event)
        self.assertTrue(event.isAccepted())
        self.assertEqual(
            calls, ["http", "stop_capture", "capture", "decoder"]
        )
        self.assertIsNone(self.window._http_thread)
        # 关闭后端口已释放
        rebind = HTTPServer(
            ("127.0.0.1", port),
            partial(SnapshotHandler, self.window.get_http_snapshot),
        )
        self.assertEqual(rebind.server_address[1], port)
        rebind.server_close()


if __name__ == "__main__":
    unittest.main()
