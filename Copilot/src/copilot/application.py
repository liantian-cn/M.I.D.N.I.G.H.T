"""摘要：组装 DPI 感知 Qt 应用、主窗口、设置、业务事件通道、数据库和显示器列表。

描述：应用工厂显式创建或复用 QApplication，读取启动入口同级设置，先建立业务事件
通道，再尝试文件诊断日志、准备图标数据库并枚举物理显示器。设置警告双写：既进入
文件诊断日志也显示在日志窗口；生命周期事件只显示在日志窗口；异常诊断进入文件日志；
文件日志失败时主窗口顶部显示本次运行内常驻状态。只有 ``run_application`` 显示窗口
并进入事件循环，模块导入没有文件、GUI、线程、截图或网络副作用。

主要变量信息：``entry_dir`` 是 settings.json 与相对日志路径的基准；``logging_runtime``
持有本次运行日志资源；``window`` 是 GUI 主线程拥有的主窗口。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增应用工厂。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划增加数据库预检。
2026-08-01，根据 GUI Log Business Channel 冻结计划把业务事件改为 business_log 通道，
设置警告与初始化事件只显示在日志窗口，异常诊断仍走 logger 仅进入文件日志。
2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划在数据库预检成功后启动 HTTP worker。
"""

from __future__ import annotations

from pathlib import Path
import sys
from typing import Sequence

from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtWidgets import QApplication, QMessageBox

from .capture import enumerate_monitors
from .decoder import (
    DatabaseStartupError,
    IncompleteDatabaseCleanupError,
    prepare_icon_database,
)
from .logging_setup import LoggingRuntime, business_log, configure_logging
from .settings import load_settings
from .ui import MainWindow


def create_application(
    argv: Sequence[str] | None = None,
    entry_dir: Path | None = None,
) -> tuple[QApplication, MainWindow, LoggingRuntime]:
    """创建完整但尚未显示的应用对象。"""

    if QApplication.instance() is None:
        QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
            Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
        )
        app = QApplication(list(argv) if argv is not None else sys.argv)
    else:
        app = QApplication.instance()
        if not isinstance(app, QApplication):
            raise RuntimeError("当前 Qt application 不是 QApplication")
    app.setApplicationName("Copilot")

    startup_dir = (
        Path(entry_dir)
        if entry_dir is not None
        else Path(sys.argv[0]).resolve().parent
    )
    settings_result = load_settings(startup_dir)
    database_path = startup_dir / "database.sqlite"
    window = MainWindow(database_path)
    logging_runtime = configure_logging(
        settings_result.logging, startup_dir, window.append_gui_log
    )
    logger = logging_runtime.logger
    for warning in settings_result.warnings:
        # 设置警告既是诊断信息（进入文件日志）也是用户可读信息（显示在窗口）
        logger.warning(warning)
        business_log(warning)
    if logging_runtime.file_error is not None:
        window.set_file_log_unavailable(True)
    try:
        prepare_icon_database(
            database_path,
            lambda reason: QMessageBox.question(
                window,
                "图标数据库不可用",
                f"图标数据库无法读取：{reason}\n是否重置数据库？",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                QMessageBox.StandardButton.No,
            )
            == QMessageBox.StandardButton.Yes,
        )
    except IncompleteDatabaseCleanupError as error:
        logger.exception("图标数据库初始化失败且残留文件无法清理")
        QMessageBox.critical(
            window,
            "图标数据库清理失败",
            f"新数据库初始化失败，且不完整文件仍残留在：\n{error.path}\n"
            "Copilot 将退出，请人工处理该文件。",
        )
        logging_runtime.close()
        window.close()
        raise
    except DatabaseStartupError:
        logger.exception("图标数据库启动检查失败")
        QMessageBox.critical(
            window,
            "图标数据库不可用",
            "图标数据库启动检查失败，Copilot 将退出。",
        )
        logging_runtime.close()
        window.close()
        raise
    window.start_http_worker()
    business_log(
        "日志设置已加载："
        f"file_enabled={settings_result.logging.file_enabled} "
        f"path={settings_result.logging.path} "
        f"max_bytes={settings_result.logging.max_bytes} "
        f"backup_count={settings_result.logging.backup_count} "
        f"level={settings_result.logging.level}"
    )
    try:
        window.set_monitors(enumerate_monitors())
    except Exception:
        logger.exception("显示器枚举失败")
        business_log("显示器枚举失败", error=True)
        window.set_monitors([])
    business_log("Copilot 应用初始化完成")
    return app, window, logging_runtime


def run_application() -> int:
    """显示主窗口、运行事件循环并在退出后关闭日志资源。"""

    try:
        app, window, logging_runtime = create_application()
    except DatabaseStartupError:
        return 1
    window.show()
    try:
        return app.exec()
    finally:
        business_log("Copilot 应用退出")
        logging_runtime.close()


__all__ = ["create_application", "run_application"]
