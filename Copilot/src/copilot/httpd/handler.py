"""摘要：实现任意 URL path 固定返回最新 JSON 快照的最小 HTTP handler。

描述：GET/POST 都调用同一 ``_serve_snapshot``，通过注入的读取器单次持锁取得
(快照副本, 最小回退 dict, 预编码回退 bytes) 并返回相同 JSON，忽略请求体；
``do_OPTIONS`` 返回 HTTP 200 与 CORS 预检头、空体，不读取快照；PUT/DELETE/HEAD
保留基类默认行为。快照读取（deepcopy）或编码失败时记录完整本地诊断，并以 HTTP
200 返回发布方准备的最小 ``internal_error`` 回退，响应从不包含异常、traceback、
本地路径或 GUI 文案。请求行经 ``log_message`` 覆盖写入 copilot 诊断日志而非 stderr。

主要变量信息：``_snapshot_reader`` 是注入的单次持锁快照读取回调；``_logger``
是 copilot 诊断日志。

修改记录：2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划新增。
2026-08-09，根据审计 finding 移除读取器失败路径的 worker 生成时间戳：读取失败经
``SnapshotReaderError`` 携带发布方回退对，回退链收敛为回退 dict → 预编码 bytes 两级。
"""

from __future__ import annotations

from http.server import BaseHTTPRequestHandler
import json
import logging
from typing import Any, Callable

from ..logging_setup import business_log
from .serializer import json_default

SnapshotReader = Callable[[], tuple[dict, dict, bytes]]


class SnapshotReaderError(Exception):
    """快照读取（deepcopy）失败，携带发布方锁内准备的最小回退对。"""

    def __init__(self, fallback_dict: dict, fallback_bytes: bytes) -> None:
        super().__init__("snapshot read failed")
        self.fallback_dict = fallback_dict
        self.fallback_bytes = fallback_bytes


class SnapshotHandler(BaseHTTPRequestHandler):
    """对任意 URL path 返回相同最新快照 JSON，正常与错误体一律 HTTP 200。"""

    def __init__(
        self,
        snapshot_reader: SnapshotReader,
        request: Any,
        client_address: Any,
        server: Any,
    ) -> None:
        self._snapshot_reader = snapshot_reader
        self._logger = logging.getLogger("copilot")
        super().__init__(request, client_address, server)

    def do_GET(self) -> None:
        self._serve_snapshot()

    def do_POST(self) -> None:
        # 请求体不读取也不影响响应，POST 与 GET 返回相同 JSON
        self._serve_snapshot()

    def do_OPTIONS(self) -> None:
        """返回 CORS 预检响应；不读取快照，也不返回 JSON 体。"""

        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:
        # 请求行进入 copilot 诊断日志，不写入 stderr
        self._logger.info("%s - %s", self.address_string(), format % args)

    def _serve_snapshot(self) -> None:
        fallback_dict: dict | None = None
        fallback_bytes: bytes | None = None
        try:
            snapshot, fallback_dict, fallback_bytes = self._snapshot_reader()
            body = json.dumps(snapshot, default=json_default).encode("utf-8")
        except SnapshotReaderError as error:
            # 读取器（deepcopy）失败：使用发布方锁内准备的回退对，保留发布方时间戳
            self._logger.exception("HTTP 快照读取失败")
            business_log("HTTP 快照读取失败，已返回最小错误响应", error=True)
            body = self._minimal_error_body(
                error.fallback_dict, error.fallback_bytes
            )
        except Exception:
            self._logger.exception("HTTP 快照读取或序列化失败")
            business_log("HTTP 快照读取或序列化失败，已返回最小错误响应", error=True)
            body = self._minimal_error_body(fallback_dict, fallback_bytes)
        self._send_json(body)

    def _minimal_error_body(
        self, fallback_dict: dict | None, fallback_bytes: bytes | None
    ) -> bytes:
        """按可用顺序返回最小错误体：回退 dict 优先，其次发布方预编码 bytes。"""

        if fallback_dict is not None:
            try:
                return json.dumps(fallback_dict).encode("utf-8")
            except Exception:
                self._logger.exception("HTTP 最小回退对象序列化失败")
        if fallback_bytes is not None:
            return fallback_bytes
        # 生产不可达：发布方每次发布都关联回退对，读取失败也经 SnapshotReaderError
        # 携带同一回退对；handler 不生成或重写时间戳，故此处只能暴露编程错误
        raise RuntimeError("HTTP 快照回退数据不可用")

    def _send_json(self, body: bytes) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


__all__ = ["SnapshotHandler", "SnapshotReaderError"]
