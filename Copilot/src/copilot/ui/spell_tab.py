"""摘要：以表格展示当前 spell 解码结果的 GUI 页签。

描述：SpellTab 是主窗口"技能"页签，用只读 QTableWidget 展示 extract_matrix 返回的
spell 列表。每行对应一个 spell 槽位，列依次为 index、技能名称、法术ID、冷却、可用、
高亮、学会；布尔列渲染"是/否"，冷却整数显示整数否则保留 1 位小数。
refresh_from_decode_snapshot 复用其他页签的快照契约（decoded_data +
decode_result_is_stale），当前失败但存在最后成功数据时保留值并标记旧数据。

主要变量信息：`HEADERS` 是固定列标题；`table` 是只读表格控件；`status_label` 显示
空态、计数与旧数据提示。

修改记录：2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划新增。
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


class SpellTab(QWidget):
    """以只读表格展示当前 spell 解码结果。"""

    HEADERS = ["index", "技能名称", "法术ID", "冷却", "可用", "高亮", "学会"]

    def __init__(self) -> None:
        super().__init__()
        self.status_label = QLabel("暂无技能数据。", self)
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
        spell_list = decoded_data.get("spell", []) if isinstance(decoded_data, dict) else []
        stale = bool(snapshot.get("decode_result_is_stale"))

        if not spell_list:
            self.table.setRowCount(0)
            self.status_label.setText("暂无技能数据。")
            return

        self.table.setRowCount(len(spell_list))
        for row, spell in enumerate(spell_list):
            self.table.setItem(row, 0, self._readonly_item(str(spell.get("index", ""))))
            self.table.setItem(row, 1, self._readonly_item(str(spell.get("description", ""))))
            self.table.setItem(row, 2, self._readonly_item(str(spell.get("spellId", ""))))
            self.table.setItem(row, 3, self._readonly_item(self._format_cooldown(spell.get("cooldown"))))
            self.table.setItem(row, 4, self._readonly_item(self._format_bool(spell.get("usable"))))
            self.table.setItem(row, 5, self._readonly_item(self._format_bool(spell.get("overlayed"))))
            self.table.setItem(row, 6, self._readonly_item(self._format_bool(spell.get("known"))))

        if stale:
            self.status_label.setText("当前显示的是旧数据，最新状态不可用。")
        else:
            self.status_label.setText(f"共 {len(spell_list)} 个技能。")

    @staticmethod
    def _readonly_item(text: str) -> QTableWidgetItem:
        item = QTableWidgetItem(text)
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item

    @staticmethod
    def _format_bool(envelope: Any) -> str:
        result = envelope.get("result") if isinstance(envelope, dict) else None
        return "是" if bool(result) else "否"

    @staticmethod
    def _format_cooldown(envelope: Any) -> str:
        result = envelope.get("result") if isinstance(envelope, dict) else None
        if result is None:
            return "None"
        cooldown = float(result)
        if cooldown.is_integer():
            return str(int(cooldown))
        return f"{cooldown:.1f}"


__all__ = ["SpellTab"]
