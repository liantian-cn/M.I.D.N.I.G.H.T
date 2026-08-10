"""摘要：在独立 QThread 事件循环中运行标准库 HTTP 服务。

描述：worker 通过 ``start`` 槽运行主线程已构造好的 HTTPServer 的 ``serve_forever``，
``shutdown`` 槽调用 ``server_close`` 释放监听端口并发出 ``shutdown_ready`` 供主线程
确认退出。``serve_forever`` 的意外异常记录到 copilot 诊断日志。worker 不创建 server、
不持有或修改 ``martix_data``，只通过主线程注入的处理器读取快照。

主要变量信息：``_server`` 是主线程注入的 HTTPServer；``shutdown_ready`` 通知主线程
HTTP 资源已释放。

修改记录：2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划新增。
"""

from __future__ import annotations

from http.server import HTTPServer
import logging

from PySide6.QtCore import QObject, Signal, Slot


class WebServerWorker(QObject):
    """运行主线程构造的 HTTPServer，并在关闭时释放监听端口。"""

    shutdown_ready = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._logger = logging.getLogger("copilot")
        self._server: HTTPServer | None = None

    @Slot(object)
    def start(self, server: HTTPServer) -> None:
        """在 worker 线程事件循环内阻塞运行服务循环。"""

        self._server = server
        try:
            server.serve_forever()
        except Exception:
            self._logger.exception("HTTP 服务运行异常退出")

    @Slot()
    def shutdown(self) -> None:
        """关闭服务端资源释放监听端口，并确认 HTTP 已停止。"""

        server = self._server
        if server is not None:
            try:
                server.server_close()
            except Exception:
                self._logger.exception("HTTP server_close 失败")
        self.shutdown_ready.emit()


__all__ = ["WebServerWorker"]
