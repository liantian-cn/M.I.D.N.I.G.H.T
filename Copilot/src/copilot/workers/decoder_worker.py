"""摘要：在独立 QThread 中解析单张当前 Phantom Matrix 帧。

描述：worker 在线程内打开并独占 IconTitleManager/SQLite 连接；每个 decode 请求调用
extractor 并通过 signal 返回完整内部结果或失败文案。标题记录查询、维护、阈值调整和
JSON 导入导出同样通过线程内 slot 串行执行。单飞行与最新 pending 调度由主线程负责，
worker 不持有或修改 `martix_data`。

主要变量信息：`_database_path` 是启动前已验证的数据库；`_title_manager` 只在 worker
线程创建、使用和关闭。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增；
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划增加标题管理命令。
2026-08-01，根据 GUI Log Business Channel 冻结计划把可读失败文案改为 business_log，
异常 Traceback 仍走 logger 仅进入文件日志。
"""

from __future__ import annotations

from collections.abc import Callable
import logging
from pathlib import Path

import numpy as np
from PySide6.QtCore import QObject, Signal, Slot

from ..decoder import IconTitleManager, extract_matrix
from ..logging_setup import business_log


class DecoderWorker(QObject):
    """解析主线程投递的单张 RGB Matrix。"""

    decode_succeeded = Signal(object)
    decode_failed = Signal(str)
    title_records_ready = Signal(object)
    title_operation_succeeded = Signal(str, str)
    title_operation_failed = Signal(str, str)
    shutdown_ready = Signal()

    def __init__(self, database_path: str | Path) -> None:
        super().__init__()
        self._logger = logging.getLogger("copilot")
        self._database_path = Path(database_path)
        self._title_manager: IconTitleManager | None = None

    def _manager(self) -> IconTitleManager:
        if self._title_manager is None:
            self._title_manager = IconTitleManager(self._database_path)
        return self._title_manager

    @Slot(object)
    def decode(self, frame: object) -> None:
        try:
            if not isinstance(frame, np.ndarray):
                raise TypeError("DecoderWorker 只接受 numpy.ndarray")
            result = extract_matrix(frame, self._manager())
        except Exception as exc:
            self._logger.exception("Matrix 解码失败")
            self.decode_failed.emit(str(exc))
            return
        self.decode_succeeded.emit(result)

    def _emit_title_records(self) -> None:
        manager = self._manager()
        self.title_records_ready.emit(
            {
                "database": manager.list_database_records(),
                "memory": manager.list_memory_records(),
                "threshold": manager.similarity_threshold,
            }
        )

    def _run_title_operation(
        self, operation: str, callback: Callable[[], object]
    ) -> None:
        try:
            detail = str(callback() or "")
            self._emit_title_records()
        except Exception as exc:
            self._logger.exception("标题管理操作失败：%s", operation)
            business_log(f"标题管理操作失败：{operation}", error=True)
            self.title_operation_failed.emit(operation, str(exc))
            return
        self.title_operation_succeeded.emit(operation, detail)

    @Slot()
    def request_title_records(self) -> None:
        try:
            self._emit_title_records()
        except Exception as exc:
            self._logger.exception("读取标题记录失败")
            business_log("读取标题记录失败", error=True)
            self.title_operation_failed.emit("refresh", str(exc))

    @Slot(object)
    def add_title_record(self, payload: object) -> None:
        def add() -> str:
            if not isinstance(payload, dict):
                raise TypeError("标题记录必须是 dict")
            return self._manager().add_record(
                np.array(payload["valid_array"], dtype=np.uint8),
                str(payload["title_type"]),
                str(payload["title"]),
                str(payload["hash"]),
            )

        self._run_title_operation("add", add)

    @Slot(str, str)
    def update_title_record(self, record_hash: str, title: str) -> None:
        self._run_title_operation(
            "update", lambda: self._manager().update_record(record_hash, title)
        )

    @Slot(str)
    def delete_title_record(self, record_hash: str) -> None:
        self._run_title_operation(
            "delete", lambda: self._manager().delete_record(record_hash)
        )

    @Slot(float)
    def set_title_threshold(self, threshold: float) -> None:
        self._run_title_operation(
            "threshold",
            lambda: self._manager().set_similarity_threshold(threshold),
        )

    @Slot(str)
    def export_title_database(self, path: str) -> None:
        self._run_title_operation(
            "export", lambda: self._manager().export_json(path)
        )

    @Slot(str)
    def import_title_database(self, path: str) -> None:
        def import_database() -> str:
            self._manager().import_json(path)
            return path

        self._run_title_operation("import", import_database)

    @Slot()
    def shutdown(self) -> None:
        if self._title_manager is not None:
            self._title_manager.close()
            self._title_manager = None
        self.shutdown_ready.emit()


__all__ = ["DecoderWorker"]
