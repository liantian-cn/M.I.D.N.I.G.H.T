"""摘要：提供 Copilot 图标标题记录的非模态维护窗口。

描述：窗口按四个可持久化业务类别和一个只读 Other 类别展示记录，并额外展示相似匹配
与未分类缓存。用户可以把合格的实时记录保存为正式标题、修改正式标题或确认删除记录；
窗口每秒通过 signal 请求 DecoderWorker 快照，输入标题时不会被周期刷新覆盖。

主要变量信息：`database_records` 是 SQLite 正式记录快照；`memory_records` 包含正式、
相似命中、未命中和 Other 缓存；`_miss_input_cache` 保留未提交的输入文本。

修改记录：2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划新增。
"""

from __future__ import annotations

from typing import Any

import numpy as np
from PySide6.QtCore import QTimer, Qt, Signal, Slot
from PySide6.QtGui import QCloseEvent, QPixmap, QShowEvent
from PySide6.QtWidgets import (
    QAbstractItemView,
    QDialog,
    QHBoxLayout,
    QHeaderView,
    QInputDialog,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QTableWidget,
    QTableWidgetItem,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)

from ..decoder.color import ICON_CATEGORIES
from ..decoder.title_manager import CACHE_MISS, CACHE_PERSISTENT, CACHE_SIMILAR

CATEGORY_TABS = (
    ("玩家技能", "PLAYER_SPELL"),
    ("可打断敌方施法", "ENEMY_SPELL_INTERRUPTIBLE"),
    ("不可打断敌方施法", "ENEMY_SPELL_NOT_INTERRUPTIBLE"),
    ("友方减益", "DEBUFF_ON_FRIENDLY"),
)


class TitleEditorDialog(QDialog):
    """显示 worker 提供的标题快照并发出维护命令。"""

    records_requested = Signal()
    record_save_requested = Signal(object)
    record_update_requested = Signal(str, str)
    record_delete_requested = Signal(str)

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setWindowTitle("标题编辑器")
        self.resize(1100, 760)
        self.database_records: list[dict[str, Any]] = []
        self.memory_records: list[dict[str, Any]] = []
        self.category_tables: dict[str, QTableWidget] = {}
        self._miss_input_cache: dict[str, str] = {}

        layout = QVBoxLayout(self)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(12)
        self.tabs = QTabWidget(self)
        for label, _category in CATEGORY_TABS:
            table = self._create_table(["图像", "标题", "Hash", "分类", "操作"])
            self.category_tables[label] = table
            self.tabs.addTab(self._wrap_table(table), label)
        self.other_table = self._create_table(
            ["图像", "当前标题", "Hash", "分类", "来源"]
        )
        self.tabs.addTab(self._wrap_table(self.other_table), "其他")
        self.similar_table = self._create_table(
            ["图像", "当前标题", "Hash", "分类", "操作"]
        )
        self.tabs.addTab(self._wrap_table(self.similar_table), "相似匹配")
        self.miss_table = self._create_table(
            ["图像", "当前标题", "Hash", "分类", "输入标题", "操作"]
        )
        self.tabs.addTab(self._wrap_table(self.miss_table), "未分类")
        layout.addWidget(self.tabs)

        self.refresh_timer = QTimer(self)
        self.refresh_timer.setInterval(1000)
        self.refresh_timer.timeout.connect(self.records_requested)

    @staticmethod
    def _create_table(headers: list[str]) -> QTableWidget:
        table = QTableWidget()
        table.setColumnCount(len(headers))
        table.setHorizontalHeaderLabels(headers)
        table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        table.verticalHeader().setVisible(False)
        table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Fixed)
        table.setColumnWidth(0, 64)
        table.horizontalHeader().setSectionResizeMode(
            len(headers) - 1, QHeaderView.ResizeMode.ResizeToContents
        )
        return table

    @staticmethod
    def _wrap_table(table: QTableWidget) -> QWidget:
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(table)
        return container

    @staticmethod
    def _readonly_item(value: object) -> QTableWidgetItem:
        item = QTableWidgetItem(str(value))
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item

    @staticmethod
    def _image_label(png_bytes: bytes) -> QLabel:
        label = QLabel()
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        pixmap = QPixmap()
        pixmap.loadFromData(png_bytes)
        label.setPixmap(
            pixmap.scaled(
                36,
                36,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.FastTransformation,
            )
        )
        return label

    @Slot(object)
    def apply_records(self, snapshot: object) -> None:
        if not isinstance(snapshot, dict):
            return
        self._remember_miss_inputs()
        database = snapshot.get("database")
        memory = snapshot.get("memory")
        if not isinstance(database, list) or not isinstance(memory, list):
            return
        self.database_records = database
        self.memory_records = memory
        if self._is_editing_miss_input():
            return
        self._populate_all_tables()

    def _populate_all_tables(self) -> None:
        for label, category in CATEGORY_TABS:
            records = [
                record
                for record in self.database_records
                if record.get("title_type") == category
            ]
            self._populate_database_table(self.category_tables[label], records)
        self._populate_other_table(
            [
                record
                for record in self.memory_records
                if record.get("title_type") not in ICON_CATEGORIES
            ]
        )
        self._populate_similar_table(
            [
                record
                for record in self.memory_records
                if record.get("cache_kind") == CACHE_SIMILAR
            ]
        )
        self._populate_miss_table(
            [
                record
                for record in self.memory_records
                if record.get("cache_kind") == CACHE_MISS
                and record.get("title_type") in ICON_CATEGORIES
            ]
        )

    def _populate_database_table(
        self, table: QTableWidget, records: list[dict[str, Any]]
    ) -> None:
        table.setRowCount(len(records))
        for row, record in enumerate(records):
            self._set_common_cells(table, row, record)
            table.setCellWidget(row, 4, self._database_actions(record))

    def _populate_other_table(self, records: list[dict[str, Any]]) -> None:
        self.other_table.setRowCount(len(records))
        for row, record in enumerate(records):
            self._set_common_cells(self.other_table, row, record)
            sources = {
                CACHE_PERSISTENT: "正式记录",
                CACHE_SIMILAR: "相似匹配",
                CACHE_MISS: "未分类",
            }
            self.other_table.setItem(
                row,
                4,
                self._readonly_item(
                    sources.get(str(record.get("cache_kind")), "N/A")
                ),
            )

    def _populate_similar_table(self, records: list[dict[str, Any]]) -> None:
        self.similar_table.setRowCount(len(records))
        for row, record in enumerate(records):
            self._set_common_cells(self.similar_table, row, record)
            self.similar_table.setCellWidget(row, 4, self._similar_actions(record))

    def _populate_miss_table(self, records: list[dict[str, Any]]) -> None:
        self.miss_table.setRowCount(len(records))
        for row, record in enumerate(records):
            self._set_common_cells(self.miss_table, row, record)
            record_hash = str(record["hash"])
            editor = QLineEdit(self.miss_table)
            editor.setText(self._miss_input_cache.get(record_hash, ""))
            self.miss_table.setCellWidget(row, 4, editor)
            self.miss_table.setCellWidget(row, 5, self._miss_actions(record, editor))

    def _set_common_cells(
        self, table: QTableWidget, row: int, record: dict[str, Any]
    ) -> None:
        table.setRowHeight(row, 44)
        table.setCellWidget(row, 0, self._image_label(bytes(record["png_bytes"])))
        table.setItem(row, 1, self._readonly_item(record["title"]))
        table.setItem(row, 2, self._readonly_item(record["hash"]))
        table.setItem(row, 3, self._readonly_item(record["title_type"]))

    @staticmethod
    def _action_container(*buttons: QPushButton) -> QWidget:
        container = QWidget()
        layout = QHBoxLayout(container)
        layout.setContentsMargins(2, 2, 2, 2)
        layout.setSpacing(6)
        for button in buttons:
            layout.addWidget(button)
        return container

    def _database_actions(self, record: dict[str, Any]) -> QWidget:
        edit_button = QPushButton("编辑标题")
        edit_button.clicked.connect(
            lambda _checked=False, payload=record: self._edit_record(payload)
        )
        delete_button = QPushButton("删除")
        delete_button.clicked.connect(
            lambda _checked=False, payload=record: self._delete_record(payload)
        )
        return self._action_container(edit_button, delete_button)

    def _similar_actions(self, record: dict[str, Any]) -> QWidget:
        save_button = QPushButton("保存为正式记录")
        save_button.clicked.connect(
            lambda _checked=False, payload=record: self._save_record(
                payload, str(payload["title"])
            )
        )
        return self._action_container(save_button)

    def _miss_actions(
        self, record: dict[str, Any], editor: QLineEdit
    ) -> QWidget:
        save_button = QPushButton("保存")
        save_button.clicked.connect(
            lambda _checked=False, payload=record, title_editor=editor: self._save_record(
                payload, title_editor.text()
            )
        )
        return self._action_container(save_button)

    def _save_record(self, record: dict[str, Any], title: str) -> None:
        normalized_title = title.strip()
        if not normalized_title:
            QMessageBox.warning(self, "标题为空", "请先输入标题。")
            return
        payload = {
            "hash": str(record["hash"]),
            "title_type": str(record["title_type"]),
            "title": normalized_title,
            "valid_array": np.array(record["valid_array"], dtype=np.uint8).tolist(),
        }
        self._miss_input_cache.pop(payload["hash"], None)
        self.record_save_requested.emit(payload)

    def _edit_record(self, record: dict[str, Any]) -> None:
        title, accepted = QInputDialog.getText(
            self,
            "编辑标题",
            "请输入新的标题:",
            text=str(record["title"]),
        )
        normalized_title = title.strip()
        if accepted and normalized_title:
            self.record_update_requested.emit(str(record["hash"]), normalized_title)

    def _delete_record(self, record: dict[str, Any]) -> None:
        answer = QMessageBox.question(
            self, "确认删除", "确定要删除这条标题记录吗？"
        )
        if answer == QMessageBox.StandardButton.Yes:
            self.record_delete_requested.emit(str(record["hash"]))

    def _remember_miss_inputs(self) -> None:
        for row in range(self.miss_table.rowCount()):
            hash_item = self.miss_table.item(row, 2)
            editor = self.miss_table.cellWidget(row, 4)
            if hash_item is not None and isinstance(editor, QLineEdit):
                self._miss_input_cache[hash_item.text()] = editor.text()

    def _is_editing_miss_input(self) -> bool:
        focus = self.focusWidget()
        return isinstance(focus, QLineEdit) and focus in self.miss_table.findChildren(
            QLineEdit
        )

    def showEvent(self, event: QShowEvent) -> None:
        self.records_requested.emit()
        self.refresh_timer.start()
        super().showEvent(event)

    def closeEvent(self, event: QCloseEvent) -> None:
        self.refresh_timer.stop()
        super().closeEvent(event)


__all__ = ["TitleEditorDialog"]
