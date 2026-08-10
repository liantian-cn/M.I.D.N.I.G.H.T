"""摘要：以表格展示当前技能充能解码结果的 GUI 页签。

描述：ChargeTab 是主窗口“技能充能”页签，用只读 QTableWidget 展示 extract_matrix
返回的 charge 列表。每行对应一个 specialization charge_list 槽位，列依次为 index、
技能名称、法术ID、最大、最小、当前；当前值使用 float 自然字符串保留有效精度。
refresh_from_decode_snapshot 复用其他页签的最后成功快照和旧数据标记契约。

主要变量信息：`HEADERS` 是固定列标题；`table` 是只读表格控件；`status_label` 显示
空态、计数与旧数据提示。

修改记录：2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划新增。
"""

from __future__ import annotations

from typing import Any

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QAbstractItemView,
    QHeaderView,
    QLabel,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)


class ChargeTab(QWidget):
    """以只读表格展示当前 charge 解码结果。"""

    HEADERS = ["index", "技能名称", "法术ID", "最大", "最小", "当前"]

    def __init__(self) -> None:
        super().__init__()
        self.status_label = QLabel("暂无技能充能数据。", self)
        self.status_label.setWordWrap(True)

        self.table = QTableWidget(self)
        self.table.setColumnCount(len(self.HEADERS))
        self.table.setHorizontalHeaderLabels(self.HEADERS)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.verticalHeader().setVisible(False)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.horizontalHeader().setStretchLastSection(True)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(5, 5, 5, 5)
        layout.setSpacing(5)
        layout.addWidget(self.status_label)
        layout.addWidget(self.table, 1)

    def refresh_from_decode_snapshot(self, snapshot: dict[str, Any]) -> None:
        decoded_data = snapshot.get("decoded_data")
        charge_list = decoded_data.get("charge", []) if isinstance(decoded_data, dict) else []
        stale = bool(snapshot.get("decode_result_is_stale"))

        if not charge_list:
            self.table.setRowCount(0)
            self.status_label.setText("暂无技能充能数据。")
            return

        self.table.setRowCount(len(charge_list))
        for row, charge in enumerate(charge_list):
            values = (
                charge.get("index", ""),
                charge.get("description", ""),
                charge.get("spellId", ""),
                charge.get("maxValue", ""),
                charge.get("minValue", ""),
                charge.get("result", ""),
            )
            for column, value in enumerate(values):
                self.table.setItem(row, column, self._readonly_item(str(value)))

        if stale:
            self.status_label.setText("当前显示的是旧数据，最新状态不可用。")
        else:
            self.status_label.setText(f"共 {len(charge_list)} 个充能技能。")

    @staticmethod
    def _readonly_item(text: str) -> QTableWidgetItem:
        item = QTableWidgetItem(text)
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item


__all__ = ["ChargeTab"]
