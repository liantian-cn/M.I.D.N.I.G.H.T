"""摘要：实现 Copilot 固定尺寸主窗口、截图与解码会话生命周期。

描述：窗口由 48 像素顶部设置条和十三个标签页组成。Home 上方 100 像素区域左侧提供
300 像素矩阵预览、时间戳和 FPS 控制，右侧留空；下方为最多 3000 文本块的 GUI 日志。
主线程分别管理 CaptureWorker 与 DecoderWorker/QThread，使用单飞行加最新 pending 调度
解码，独占发布 `martix_data`，并把最后成功结果作为独立 GUI 旧值缓存。标题编辑、阈值和
导入导出通过 signals 访问 decoder 线程内数据库。关闭时先停编辑器刷新，再按顺序请求两个
worker 在线程内释放资源并确认线程实际结束。成功快照还发布一键辅助与打断黑名单，供
环境信息页展示；badge UTF 仅在解码线程内部学习，不进入主线程快照。

主要变量信息：``martix_raw`` 保存当前独立 RGB 帧；``martix_data`` 是当前公开快照；
``_last_success_data`` 只供 GUI 旧值显示；``_pending_decode_frame`` 最多保存最新一帧。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增主窗口；
2026-08-01，根据 audit findings 修正 shutdown 顺序和停止后的失败门控。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划接入解码与状态页。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划接入标题管理和高级设置。
2026-08-01，根据 Phase 2.6 Target and Focus Matrix Decoder 冻结计划接入目标/焦点页与快照。
2026-08-01，根据 GUI Log Business Channel 冻结计划把业务事件改为 business_log 通道，
日志窗口显示无级别标记文本，错误行红色，Traceback 不再进入窗口。
2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划接入"技能"tab 与 spell 快照发布。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划接入"技能充能"tab 与 charge 快照发布。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划接入固定 Aura 页与快照发布。
2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划接入玩家减益页与快照发布。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划接入小队页并加宽窗口。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 冻结计划接入团队页与 raid 快照发布。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划发布辅助图标字段并接入环境页。
2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划接入 HTTP 服务、快照回退对与
HTTP 优先的关闭顺序。
2026-08-09，根据审计 finding 让 get_http_snapshot 在 deepcopy 失败时以
SnapshotReaderError 携带发布方回退对，保证 HTTP 回退时间戳来自发布方。
"""

from __future__ import annotations

from datetime import datetime
from copy import deepcopy
from functools import partial
from http.server import HTTPServer
import logging
from pathlib import Path
import threading
from typing import Iterable

import numpy as np
from PySide6.QtCore import QThread, QTimer, Qt, Signal, Slot
from PySide6.QtGui import (
    QCloseEvent,
    QColor,
    QImage,
    QPalette,
    QPixmap,
    QResizeEvent,
    QTextCharFormat,
    QTextCursor,
)
from PySide6.QtWidgets import (
    QComboBox,
    QFileDialog,
    QFrame,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPlainTextEdit,
    QPushButton,
    QMessageBox,
    QSlider,
    QSpinBox,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)

from ..capture import MonitorRegion
from ..httpd import SnapshotHandler, SnapshotReaderError, build_internal_error_fallback
from ..logging_setup import business_log
from ..workers import CaptureWorker, DecoderWorker, WebServerWorker
from .aura_group_tab import AuraGroupTab
from .aura_slot_tab import AuraSlotTab
from .charge_tab import ChargeTab
from .party_tab import PartyTab
from .raid_tab import RaidTab
from .spell_tab import SpellTab
from .status_tabs import (
    EnvironmentInfoTab,
    FocusStatusTab,
    PlayerStatusTab,
    TargetStatusTab,
)
from .title_editor_dialog import TitleEditorDialog


class MainWindow(QMainWindow):
    """管理截图 UI、运行状态和 worker 生命周期。"""

    request_worker_start = Signal(object, int)
    request_worker_stop = Signal()
    request_worker_fps = Signal(int)
    request_worker_shutdown = Signal()
    request_httpd_start = Signal(object)
    request_httpd_shutdown = Signal()
    request_decoder_decode = Signal(object)
    request_decoder_shutdown = Signal()
    request_title_records = Signal()
    request_title_add = Signal(object)
    request_title_update = Signal(str, str)
    request_title_delete = Signal(str)
    request_title_threshold = Signal(float)
    request_title_export = Signal(str)
    request_title_import = Signal(str)

    def __init__(self, database_path: str | Path) -> None:
        super().__init__()
        self._logger = logging.getLogger("copilot")
        self._database_path = Path(database_path)
        self.is_running = False
        self.martix_raw: np.ndarray | None = None
        self._martix_data_lock = threading.Lock()
        self.martix_data: dict = {}
        self._fallback_dict: dict = {}
        self._fallback_bytes: bytes = b""
        self._last_success_data: dict | None = None
        self._decode_busy = False
        self._pending_decode_frame: np.ndarray | None = None
        self._preview_source: QPixmap | None = None
        self._capture_worker: CaptureWorker | None = None
        self._capture_thread: QThread | None = None
        self._decoder_worker: DecoderWorker | None = None
        self._decoder_thread: QThread | None = None
        self._http_worker: WebServerWorker | None = None
        self._http_thread: QThread | None = None
        self._http_server: HTTPServer | None = None
        self._http_started = False
        self.title_editor_dialog: TitleEditorDialog | None = None

        self.setWindowTitle("Copilot")
        self.setFixedSize(960, 600)
        self._build_ui()
        self._connect_ui()
        self._replace_martix_data(self._error_snapshot("not_ready"))
        self.set_monitors([])
        self._tab_refresh_timer = QTimer(self)
        self._tab_refresh_timer.setInterval(300)
        self._tab_refresh_timer.timeout.connect(self._refresh_visible_tab)
        self._tab_refresh_timer.start()

    def _build_ui(self) -> None:
        """按固定外部尺寸和伸缩内部布局构建界面。"""

        central_widget = QWidget(self)
        root_layout = QVBoxLayout(central_widget)
        root_layout.setContentsMargins(0, 0, 0, 0)
        root_layout.setSpacing(0)

        self.settings_strip = QFrame(central_widget)
        self.settings_strip.setFixedHeight(48)
        settings_layout = QHBoxLayout(self.settings_strip)
        settings_layout.setContentsMargins(8, 6, 8, 6)
        settings_layout.setSpacing(8)

        settings_layout.addWidget(QLabel("端口", self.settings_strip))
        self.port_spin = QSpinBox(self.settings_strip)
        self.port_spin.setRange(1, 65535)
        self.port_spin.setValue(65131)
        settings_layout.addWidget(self.port_spin)
        self.port_restart_hint = QLabel("端口修改需重启生效", self.settings_strip)
        self.port_restart_hint.setStyleSheet("color: #b42318; font-weight: 600;")
        self.port_restart_hint.hide()
        settings_layout.addWidget(self.port_restart_hint)

        settings_layout.addWidget(QLabel("显示器", self.settings_strip))
        self.monitor_combo = QComboBox(self.settings_strip)
        self.monitor_combo.setMinimumWidth(220)
        settings_layout.addWidget(self.monitor_combo, 1)

        self.capture_button = QPushButton("开始截图", self.settings_strip)
        settings_layout.addWidget(self.capture_button)
        self.title_editor_button = QPushButton("标题编辑", self.settings_strip)
        settings_layout.addWidget(self.title_editor_button)
        self.file_log_status = QLabel("文件日志不可用", self.settings_strip)
        self.file_log_status.setStyleSheet("color: #b42318; font-weight: 600;")
        self.file_log_status.hide()
        settings_layout.addWidget(self.file_log_status)
        self.http_status = QLabel("HTTP 服务不可用", self.settings_strip)
        self.http_status.setStyleSheet("color: #b42318; font-weight: 600;")
        self.http_status.hide()
        settings_layout.addWidget(self.http_status)
        root_layout.addWidget(self.settings_strip)

        self.tabs = QTabWidget(central_widget)
        self.home_tab = self._build_home_tab()
        self.tabs.addTab(self.home_tab, "Home")
        self.player_status_tab = PlayerStatusTab()
        self.player_buff_tab = AuraSlotTab(
            "player_buff", "暂无玩家增益数据。", "玩家增益"
        )
        self.player_debuff_tab = AuraGroupTab()
        self.party_tab = PartyTab()
        self.raid_tab = RaidTab()
        self.spell_tab = SpellTab()
        self.charge_tab = ChargeTab()
        self.target_status_tab = TargetStatusTab()
        self.target_debuff_tab = AuraSlotTab(
            "target_debuff", "暂无目标减益数据。", "目标减益"
        )
        self.focus_status_tab = FocusStatusTab()
        self.environment_info_tab = EnvironmentInfoTab()
        # 角色相关页聚类在前，Aura 页紧跟所属对象；环境与高级页次靠后。
        self.tabs.addTab(self.player_status_tab, "玩家属性")
        self.tabs.addTab(self.player_buff_tab, "玩家增益")
        self.tabs.addTab(self.player_debuff_tab, "玩家减益")
        self.tabs.addTab(self.party_tab, "小队")
        self.tabs.addTab(self.raid_tab, "团队")
        self.tabs.addTab(self.spell_tab, "技能")
        self.tabs.addTab(self.charge_tab, "技能充能")
        self.tabs.addTab(self.target_status_tab, "目标属性")
        self.tabs.addTab(self.target_debuff_tab, "目标减益")
        self.tabs.addTab(self.focus_status_tab, "焦点属性")
        self.tabs.addTab(self.environment_info_tab, "环境信息")
        self.tabs.addTab(self._build_advanced_tab(), "高级设置")
        root_layout.addWidget(self.tabs, 1)
        self.setCentralWidget(central_widget)

    def _build_home_tab(self) -> QWidget:
        home_tab = QWidget(self.tabs if hasattr(self, "tabs") else self)
        home_layout = QVBoxLayout(home_tab)
        home_layout.setContentsMargins(6, 6, 6, 6)
        home_layout.setSpacing(6)

        self.home_upper_band = QFrame(home_tab)
        self.home_upper_band.setFixedHeight(100)
        upper_layout = QHBoxLayout(self.home_upper_band)
        upper_layout.setContentsMargins(0, 0, 0, 0)
        upper_layout.setSpacing(6)

        self.preview_section = QFrame(self.home_upper_band)
        self.preview_section.setFixedWidth(300)
        preview_layout = QVBoxLayout(self.preview_section)
        preview_layout.setContentsMargins(0, 0, 0, 0)
        preview_layout.setSpacing(2)
        self.preview_label = QLabel("无截图", self.preview_section)
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setMinimumHeight(45)
        self.preview_label.setStyleSheet("background: #111; color: #ccc;")
        preview_layout.addWidget(self.preview_label, 1)
        self.preview_timestamp = QLabel("", self.preview_section)
        self.preview_timestamp.setAlignment(Qt.AlignmentFlag.AlignCenter)
        preview_layout.addWidget(self.preview_timestamp)
        upper_layout.addWidget(self.preview_section)
        upper_layout.addWidget(QFrame(self.home_upper_band), 1)
        home_layout.addWidget(self.home_upper_band)

        self.gui_log = QPlainTextEdit(home_tab)
        self.gui_log.setReadOnly(True)
        self.gui_log.document().setMaximumBlockCount(3000)
        home_layout.addWidget(self.gui_log, 1)
        return home_tab

    def _build_advanced_tab(self) -> QWidget:
        advanced_tab = QWidget(self.tabs)
        layout = QVBoxLayout(advanced_tab)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(12)

        fps_group = QGroupBox("截图频率", advanced_tab)
        fps_group_layout = QVBoxLayout(fps_group)
        fps_row = QHBoxLayout()
        fps_row.addWidget(QLabel("截图 FPS", advanced_tab))
        self.fps_slider = QSlider(Qt.Orientation.Horizontal, advanced_tab)
        self.fps_slider.setRange(1, 40)
        self.fps_slider.setValue(30)
        fps_row.addWidget(self.fps_slider, 1)
        self.fps_value = QLabel("30", advanced_tab)
        self.fps_value.setMinimumWidth(24)
        fps_row.addWidget(self.fps_value)
        fps_group_layout.addLayout(fps_row)
        layout.addWidget(fps_group)

        threshold_group = QGroupBox("余弦阈值", advanced_tab)
        threshold_layout = QHBoxLayout(threshold_group)
        self.threshold_slider = QSlider(Qt.Orientation.Horizontal, threshold_group)
        self.threshold_slider.setRange(980, 999)
        self.threshold_slider.setValue(999)
        threshold_layout.addWidget(self.threshold_slider, 1)
        self.threshold_value = QLabel("0.999", threshold_group)
        self.threshold_value.setMinimumWidth(40)
        threshold_layout.addWidget(self.threshold_value)
        layout.addWidget(threshold_group)

        library_group = QGroupBox("标题库导入导出", advanced_tab)
        library_layout = QHBoxLayout(library_group)
        self.title_export_button = QPushButton("导出标题库", library_group)
        self.title_import_button = QPushButton("导入标题库", library_group)
        library_layout.addWidget(self.title_export_button)
        library_layout.addWidget(self.title_import_button)
        layout.addWidget(library_group)
        layout.addStretch(1)
        return advanced_tab

    def _connect_ui(self) -> None:
        self.capture_button.clicked.connect(self._toggle_capture)
        self.title_editor_button.clicked.connect(self._open_title_editor)
        self.port_spin.valueChanged.connect(self._handle_port_changed)
        self.fps_slider.valueChanged.connect(self._handle_fps_changed)
        self.threshold_slider.valueChanged.connect(self._handle_threshold_changed)
        self.title_export_button.clicked.connect(self._export_title_database)
        self.title_import_button.clicked.connect(self._import_title_database)
        self.tabs.currentChanged.connect(self._refresh_visible_tab)

    def set_monitors(self, monitors: Iterable[MonitorRegion]) -> None:
        """替换排序后的显示器列表，并默认选中第一块。"""

        self.monitor_combo.clear()
        monitor_list = list(monitors)
        if not monitor_list:
            self.monitor_combo.addItem("未选择显示器", None)
            return
        for index, monitor in enumerate(monitor_list, start=1):
            self.monitor_combo.addItem(
                f"显示器 {index} ({monitor.width}x{monitor.height}, "
                f"{monitor.left},{monitor.top})",
                monitor,
            )
        self.monitor_combo.setCurrentIndex(0)

    def set_file_log_unavailable(self, unavailable: bool) -> None:
        """控制本次运行内常驻的文件日志失败状态。"""

        self.file_log_status.setVisible(unavailable)

    @Slot(str, bool)
    def append_gui_log(self, message: str, is_error: bool = False) -> None:
        """仅在 GUI 线程追加业务事件文本；错误行使用红色区分。"""

        scrollbar = self.gui_log.verticalScrollBar()
        follow_bottom = scrollbar.value() >= scrollbar.maximum()
        cursor = self.gui_log.textCursor()
        cursor.movePosition(QTextCursor.MoveOperation.End)
        text_format = QTextCharFormat()
        if is_error:
            text_format.setForeground(QColor("#b42318"))
        else:
            text_format.setForeground(
                self.gui_log.palette().color(QPalette.ColorRole.Text)
            )
        cursor.insertText(message + "\n", text_format)
        if follow_bottom:
            self.gui_log.setTextCursor(cursor)
            self.gui_log.ensureCursorVisible()
            # ensureCursorVisible 只保证光标可见，滚到底后 value 可能低于
            # maximum，显式置底以避免后续追加的跟随判定链漂移
            self.gui_log.verticalScrollBar().setValue(scrollbar.maximum())

    @Slot()
    def _toggle_capture(self) -> None:
        if self.is_running:
            self.stop_capture()
        else:
            self.start_capture()

    def start_capture(self) -> None:
        """校验显示器并向 worker 发出启动请求。"""

        monitor = self.monitor_combo.currentData()
        if not isinstance(monitor, MonitorRegion):
            business_log("当前未选择显示器，无法开始截图", error=True)
            return
        self._ensure_worker_thread()
        self._ensure_decoder_thread()
        self.is_running = True
        self.monitor_combo.setEnabled(False)
        self.capture_button.setText("停止截图")
        self._clear_preview()
        self._publish_error("not_ready")
        self._refresh_visible_tab()
        business_log("收到截图启动请求")
        self.request_worker_start.emit(monitor, self.fps_slider.value())

    def stop_capture(self) -> None:
        """立即恢复停止界面并异步通知 worker 停止。"""

        was_running = self.is_running
        self.is_running = False
        self.monitor_combo.setEnabled(True)
        self.capture_button.setText("开始截图")
        self._clear_preview()
        self._clear_pending_decode()
        self._publish_error("not_ready")
        self._refresh_visible_tab()
        if was_running:
            business_log("收到截图停止请求")
            self.request_worker_stop.emit()

    def _ensure_worker_thread(self) -> None:
        if self._capture_thread is not None:
            return
        thread = QThread(self)
        worker = CaptureWorker()
        worker.moveToThread(thread)
        self.request_worker_start.connect(worker.start_capture)
        self.request_worker_stop.connect(worker.stop_capture)
        self.request_worker_fps.connect(worker.set_fps)
        self.request_worker_shutdown.connect(worker.shutdown)
        worker.capture_started.connect(self._handle_capture_started)
        worker.frame_ready.connect(self._handle_frame_ready)
        worker.capture_failed.connect(self._handle_capture_failed)
        worker.capture_stopped.connect(self._handle_capture_stopped)
        worker.shutdown_ready.connect(
            thread.quit, Qt.ConnectionType.DirectConnection
        )
        thread.finished.connect(worker.deleteLater)
        self._capture_thread = thread
        self._capture_worker = worker
        thread.start()

    def _ensure_decoder_thread(self) -> None:
        if self._decoder_thread is not None:
            return
        thread = QThread(self)
        worker = DecoderWorker(self._database_path)
        worker.moveToThread(thread)
        self.request_decoder_decode.connect(worker.decode)
        self.request_decoder_shutdown.connect(worker.shutdown)
        self.request_title_records.connect(worker.request_title_records)
        self.request_title_add.connect(worker.add_title_record)
        self.request_title_update.connect(worker.update_title_record)
        self.request_title_delete.connect(worker.delete_title_record)
        self.request_title_threshold.connect(worker.set_title_threshold)
        self.request_title_export.connect(worker.export_title_database)
        self.request_title_import.connect(worker.import_title_database)
        worker.decode_succeeded.connect(self._handle_decode_succeeded)
        worker.decode_failed.connect(self._handle_decode_failed)
        worker.title_records_ready.connect(self._handle_title_records_ready)
        worker.title_operation_succeeded.connect(
            self._handle_title_operation_succeeded
        )
        worker.title_operation_failed.connect(self._handle_title_operation_failed)
        worker.shutdown_ready.connect(
            thread.quit, Qt.ConnectionType.DirectConnection
        )
        thread.finished.connect(worker.deleteLater)
        self._decoder_thread = thread
        self._decoder_worker = worker
        thread.start()

    @Slot(object)
    def _handle_capture_started(self, bounds: tuple[int, int, int, int]) -> None:
        if not self.is_running:
            return
        business_log(
            "截图区域已锁定："
            f"left={bounds[0]} top={bounds[1]} right={bounds[2]} bottom={bounds[3]}"
        )

    @Slot(object)
    def _handle_frame_ready(self, frame: np.ndarray) -> None:
        """按当前运行状态接收 owned RGB 帧并刷新完整预览。"""

        if not self.is_running:
            return
        self.martix_raw = frame
        height, width = frame.shape[:2]
        image = QImage(
            frame.data,
            width,
            height,
            int(frame.strides[0]),
            QImage.Format.Format_RGB888,
        ).copy()
        self._preview_source = QPixmap.fromImage(image)
        self.preview_timestamp.setText(
            datetime.now().isoformat(sep=" ", timespec="milliseconds")
        )
        self._scale_preview()
        self._queue_decode(frame)

    @Slot(str, str)
    def _handle_capture_failed(self, error_code: str, reason: str) -> None:
        if not self.is_running:
            return
        self.is_running = False
        self.monitor_combo.setEnabled(True)
        self.capture_button.setText("开始截图")
        self._clear_preview()
        self._clear_pending_decode()
        self._publish_error(error_code)
        self._refresh_visible_tab()
        business_log(reason, error=True)

    @Slot()
    def _handle_capture_stopped(self) -> None:
        business_log("截图 worker 确认停止")

    @Slot(int)
    def _handle_fps_changed(self, value: int) -> None:
        self.fps_value.setText(str(value))
        if self.is_running:
            self.request_worker_fps.emit(value)

    @Slot(int)
    def _handle_port_changed(self, value: int) -> None:
        """端口修改只在重启后生效，常驻显示提示并记录业务事件。"""

        self.port_restart_hint.setVisible(True)
        business_log(f"HTTP 端口已修改为 {value}，重启应用后生效")

    @Slot()
    def _open_title_editor(self) -> None:
        self._ensure_decoder_thread()
        if self.title_editor_dialog is None:
            dialog = TitleEditorDialog(self)
            dialog.records_requested.connect(self.request_title_records)
            dialog.record_save_requested.connect(self.request_title_add)
            dialog.record_update_requested.connect(self.request_title_update)
            dialog.record_delete_requested.connect(self.request_title_delete)
            self.title_editor_dialog = dialog
        self.title_editor_dialog.show()
        self.title_editor_dialog.raise_()
        self.title_editor_dialog.activateWindow()

    @Slot(int)
    def _handle_threshold_changed(self, value: int) -> None:
        threshold = value / 1000.0
        self.threshold_value.setText(f"{threshold:.3f}")
        self._ensure_decoder_thread()
        self.request_title_threshold.emit(threshold)

    @Slot()
    def _export_title_database(self) -> None:
        path, _selected_filter = QFileDialog.getSaveFileName(
            self,
            "导出标题库",
            str(Path("title-manager-export.json").resolve()),
            "JSON 文件 (*.json)",
        )
        if not path:
            return
        self._ensure_decoder_thread()
        self.request_title_export.emit(path)

    @Slot()
    def _import_title_database(self) -> None:
        path, _selected_filter = QFileDialog.getOpenFileName(
            self, "导入标题库", "", "JSON 文件 (*.json)"
        )
        if not path:
            return
        self._ensure_decoder_thread()
        self.request_title_import.emit(path)

    @Slot(object)
    def _handle_title_records_ready(self, snapshot: object) -> None:
        if self.title_editor_dialog is not None:
            self.title_editor_dialog.apply_records(snapshot)

    @Slot(str, str)
    def _handle_title_operation_succeeded(self, operation: str, detail: str) -> None:
        if operation == "export":
            QMessageBox.information(self, "导出成功", f"已导出到:\n{detail}")
        elif operation == "import":
            QMessageBox.information(
                self, "导入成功", f"已从下列文件导入:\n{detail}"
            )

    @Slot(str, str)
    def _handle_title_operation_failed(self, operation: str, reason: str) -> None:
        labels = {
            "refresh": "读取失败",
            "add": "保存失败",
            "update": "编辑失败",
            "delete": "删除失败",
            "threshold": "阈值设置失败",
            "export": "导出失败",
            "import": "导入失败",
        }
        QMessageBox.warning(self, labels.get(operation, "标题操作失败"), reason)

    def _clear_preview(self) -> None:
        self.martix_raw = None
        self._preview_source = None
        self.preview_label.clear()
        self.preview_label.setText("无截图")
        self.preview_timestamp.clear()

    def _queue_decode(self, frame: np.ndarray) -> None:
        if self._decode_busy:
            self._pending_decode_frame = frame
            return
        self._decode_busy = True
        self.request_decoder_decode.emit(frame)

    @Slot(object)
    def _handle_decode_succeeded(self, decoded_data: object) -> None:
        self._decode_busy = False
        if self.is_running and isinstance(decoded_data, dict):
            published = {
                "error": False,
                "timestamp": self._timestamp(),
                "player": decoded_data.get("player", {}),
                "target": decoded_data.get("target", {}),
                "focus": decoded_data.get("focus", {}),
                "environment": decoded_data.get("environment", {}),
                "spell": decoded_data.get("spell", []),
                "charge": decoded_data.get("charge", []),
                "player_buff": decoded_data.get("player_buff", []),
                "target_debuff": decoded_data.get("target_debuff", []),
                "player_debuff": decoded_data.get("player_debuff", []),
                "party": decoded_data.get("party", []),
                "raid": decoded_data.get("raid", []),
                "assisted_combat": decoded_data.get("assisted_combat"),
                "interrupt_blacklist": decoded_data.get("interrupt_blacklist", []),
            }
            self._replace_martix_data(published)
            self._last_success_data = deepcopy(published)
            self._refresh_visible_tab()
        self._submit_pending_decode()

    @Slot(str)
    def _handle_decode_failed(self, reason: str) -> None:
        self._decode_busy = False
        if self.is_running:
            self._clear_pending_decode()
            self._clear_preview()
            self._publish_error("decode_failed")
            self._refresh_visible_tab()
            business_log(f"Matrix 解码失败：{reason}", error=True)

    def _submit_pending_decode(self) -> None:
        pending = self._pending_decode_frame
        self._pending_decode_frame = None
        if not self.is_running or pending is None:
            return
        self._decode_busy = True
        self.request_decoder_decode.emit(pending)

    def _clear_pending_decode(self) -> None:
        self._pending_decode_frame = None

    @staticmethod
    def _timestamp() -> str:
        return datetime.now().isoformat(sep=" ", timespec="milliseconds")

    @classmethod
    def _error_snapshot(cls, error_msg: str) -> dict:
        return {
            "error": True,
            "error_msg": error_msg,
            "timestamp": cls._timestamp(),
        }

    def _publish_error(self, error_msg: str) -> None:
        self._replace_martix_data(self._error_snapshot(error_msg))

    def _replace_martix_data(self, snapshot: dict) -> None:
        """锁外准备最小回退对，锁内原子替换快照与关联回退对。"""

        fallback, fallback_bytes = build_internal_error_fallback(
            snapshot["timestamp"]
        )
        with self._martix_data_lock:
            self.martix_data = snapshot
            self._fallback_dict = fallback
            self._fallback_bytes = fallback_bytes

    def get_http_snapshot(self) -> tuple[dict, dict, bytes]:
        """单次持锁返回当前快照副本与发布方准备的关联最小回退对。

        deepcopy 失败时抛 ``SnapshotReaderError`` 并携带同一锁内取得的回退对，
        锁在异常展开时自动释放；临界区只含读取与拷贝，不含编码、网络、日志或
        数据库工作。
        """

        with self._martix_data_lock:
            fallback_dict, fallback_bytes = (
                self._fallback_dict,
                self._fallback_bytes,
            )
            try:
                snapshot = deepcopy(self.martix_data)
            except Exception as exc:
                raise SnapshotReaderError(fallback_dict, fallback_bytes) from exc
            return snapshot, fallback_dict, fallback_bytes

    @Slot()
    @Slot(int)
    def _refresh_visible_tab(self, _index: int | None = None) -> None:
        current_widget = self.tabs.currentWidget()
        refresh = getattr(current_widget, "refresh_from_decode_snapshot", None)
        if not callable(refresh):
            return
        if self._last_success_data is None:
            snapshot = {
                "decoded_data": None,
                "decode_result_is_stale": False,
            }
        else:
            snapshot = {
                "decoded_data": self._last_success_data,
                "decode_result_is_stale": bool(self.martix_data.get("error")),
            }
        refresh(snapshot)

    def _scale_preview(self) -> None:
        if self._preview_source is None:
            return
        target_size = self.preview_label.contentsRect().size()
        if target_size.width() <= 0 or target_size.height() <= 0:
            return
        self.preview_label.setPixmap(
            self._preview_source.scaled(
                target_size,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
        )

    def resizeEvent(self, event: QResizeEvent) -> None:
        super().resizeEvent(event)
        self._scale_preview()

    def shutdown_capture_worker(self, timeout_ms: int = 5000) -> bool:
        """同步停止 worker，退出线程并确认实际结束。"""

        thread = self._capture_thread
        worker = self._capture_worker
        if thread is None:
            return True
        if thread.isRunning() and worker is not None:
            self.request_worker_shutdown.emit()
            if not thread.wait(timeout_ms):
                self._logger.critical("截图 worker 线程未在 %d ms 内退出", timeout_ms)
                return False
        if thread.isRunning():
            self._logger.critical("截图 worker 线程仍在运行")
            return False
        self._capture_thread = None
        self._capture_worker = None
        return True

    def shutdown_decoder_worker(self, timeout_ms: int = 5000) -> bool:
        """关闭 worker 内数据库连接并确认解码线程退出。"""

        thread = self._decoder_thread
        worker = self._decoder_worker
        if thread is None:
            return True
        self._pending_decode_frame = None
        if thread.isRunning() and worker is not None:
            self.request_decoder_shutdown.emit()
            if not thread.wait(timeout_ms):
                self._logger.critical("解码 worker 线程未在 %d ms 内退出", timeout_ms)
                return False
        if thread.isRunning():
            self._logger.critical("解码 worker 线程仍在运行")
            return False
        self._decoder_thread = None
        self._decoder_worker = None
        self._decode_busy = False
        return True

    def start_http_worker(self) -> None:
        """随应用启动 HTTP 服务；绑定失败只隔离 HTTP 并常驻显示失败状态。"""

        if self._http_started:
            return
        self._http_started = True
        port = self.port_spin.value()
        try:
            server = HTTPServer(
                ("0.0.0.0", port),
                partial(SnapshotHandler, self.get_http_snapshot),
            )
        except OSError:
            self._logger.exception("HTTP 服务端口 %d 绑定失败", port)
            business_log(
                f"HTTP 服务端口 {port} 绑定失败，HTTP 服务不可用", error=True
            )
            self.http_status.setVisible(True)
            return
        thread = QThread(self)
        worker = WebServerWorker()
        worker.moveToThread(thread)
        self.request_httpd_start.connect(worker.start)
        self.request_httpd_shutdown.connect(worker.shutdown)
        worker.shutdown_ready.connect(
            thread.quit, Qt.ConnectionType.DirectConnection
        )
        thread.finished.connect(worker.deleteLater)
        self._http_server = server
        self._http_thread = thread
        self._http_worker = worker
        thread.start()
        self.request_httpd_start.emit(server)
        business_log(f"HTTP 服务已监听 0.0.0.0:{port}")

    def shutdown_http_worker(self, timeout_ms: int = 5000) -> bool:
        """先停止服务循环，再关闭 server 资源并确认 HTTP 线程实际退出。"""

        thread = self._http_thread
        worker = self._http_worker
        server = self._http_server
        if thread is None:
            return True
        if thread.isRunning() and worker is not None and server is not None:
            try:
                server.shutdown()
            except Exception:
                self._logger.exception("HTTP server.shutdown 失败")
            self.request_httpd_shutdown.emit()
            if not thread.wait(timeout_ms):
                self._logger.critical("HTTP worker 线程未在 %d ms 内退出", timeout_ms)
                return False
        if thread.isRunning():
            self._logger.critical("HTTP worker 线程仍在运行")
            return False
        if server is not None:
            try:
                server.server_close()
            except Exception:
                self._logger.exception("HTTP server_close 失败")
        self._http_thread = None
        self._http_worker = None
        self._http_server = None
        return True

    def closeEvent(self, event: QCloseEvent) -> None:
        self._tab_refresh_timer.stop()
        if self.title_editor_dialog is not None:
            self.title_editor_dialog.close()
        if not self.shutdown_http_worker():
            event.ignore()
            return
        self.stop_capture()
        if not self.shutdown_capture_worker():
            event.ignore()
            return
        if not self.shutdown_decoder_worker():
            event.ignore()
            return
        event.accept()


__all__ = ["MainWindow"]
