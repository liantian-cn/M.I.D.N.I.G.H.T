"""摘要：配置独立于 logging 的业务事件通道和可配置轮转文件诊断日志。

描述：日志窗口与 logging 完全解耦。``business_log`` 是业务事件通道：只把带时间戳的
可读消息经 Qt signal 投递到 GUI 主线程，不进入文件日志；``logging`` 仅用于文件诊断
日志（异常与 Traceback、设置警告、线程退出超时等），带级别标记写入 RotatingFileHandler。
文件初始化失败时窗口仍显示可读错误，Traceback 因文件不可用而丢弃，本次运行不重试。

主要变量信息：``BusinessLogEmitter`` 负责跨线程投递业务事件文本与错误标记；
``_business_emitter`` 是 configure_logging 时注册的模块级发射器；``LoggingRuntime``
持有本次运行创建的 logger、文件 handler 和文件初始化错误，供应用关闭时释放资源。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增双日志实现；
2026-08-01，根据 GUI Log Business Channel 冻结计划解耦日志窗口与 logging，
移除 GUI handler，新增 business_log 业务事件通道，logging 仅保留文件诊断输出。
"""

from __future__ import annotations

from datetime import datetime
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Callable

from PySide6.QtCore import QObject, Qt, Signal

from .settings import LoggingSettings, VALID_LEVELS, resolve_log_path

LOG_FORMAT = "%(asctime)s.%(msecs)03d %(levelname)s %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


class BusinessLogEmitter(QObject):
    """把任意线程产生的业务事件文本转交 Qt 主线程。"""

    message_ready = Signal(str, bool)


_business_emitter: BusinessLogEmitter | None = None


def business_log(message: str, *, error: bool = False) -> None:
    """业务事件通道：仅显示在日志窗口，不进入文件日志。

    未配置（configure_logging 尚未调用）时静默丢弃，与模块导入无副作用保持一致。
    """

    emitter = _business_emitter
    if emitter is None:
        return
    timestamp = datetime.now().isoformat(sep=" ", timespec="milliseconds")
    emitter.message_ready.emit(f"{timestamp} {message}", error)


class LoggingRuntime:
    """保存本次运行的日志资源及文件日志失败信息。"""

    def __init__(
        self,
        logger: logging.Logger,
        file_handler: RotatingFileHandler | None,
        file_error: BaseException | None,
    ) -> None:
        self.logger = logger
        self.file_handler = file_handler
        self.file_error = file_error

    def close(self) -> None:
        """注销业务发射器，并从 logger 移除、关闭文件 handler。"""

        global _business_emitter
        _business_emitter = None
        if self.file_handler is None:
            return
        self.logger.removeHandler(self.file_handler)
        self.file_handler.close()


def configure_logging(
    settings: LoggingSettings,
    entry_dir: Path,
    gui_sink: Callable[[str, bool], None],
) -> LoggingRuntime:
    """建立业务事件通道，并按设置尝试建立文件诊断日志。"""

    global _business_emitter
    emitter = BusinessLogEmitter()
    emitter.message_ready.connect(
        gui_sink, Qt.ConnectionType.QueuedConnection
    )
    _business_emitter = emitter

    logger = logging.getLogger("copilot")
    logger.setLevel(logging.DEBUG)
    logger.propagate = False
    for existing_handler in tuple(logger.handlers):
        logger.removeHandler(existing_handler)
        existing_handler.close()

    formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
    file_handler = None
    file_error = None
    if settings.file_enabled:
        log_path = resolve_log_path(entry_dir, settings.path)
        try:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            file_handler = RotatingFileHandler(
                log_path,
                maxBytes=settings.max_bytes,
                backupCount=settings.backup_count,
                encoding="utf-8",
            )
            file_handler.setLevel(VALID_LEVELS[settings.level])
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
        except Exception as error:
            # 文件 handler 尚未建立，异常与 Traceback 无处记录，仅窗口显示可读错误
            file_error = error
            business_log(f"文件日志初始化失败：{log_path}", error=True)

    return LoggingRuntime(logger, file_handler, file_error)


__all__ = ["BusinessLogEmitter", "LoggingRuntime", "business_log", "configure_logging"]
