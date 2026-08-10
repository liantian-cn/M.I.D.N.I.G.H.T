"""摘要：以表格展示固定 AuraSlot 的玩家增益或目标减益解码结果。

描述：AuraSlotTab 由 MainWindow 创建两个实例，分别读取顶层 player_buff 与
target_debuff 列表。每行对应一个专精配置槽位，展示 index、技能名称、分号连接的法术 ID、
持续时间百分比和层数范围/当前值。表格只读，并复用其他业务页签的最后成功快照、空态和
旧数据提示契约。

主要变量信息：`data_key` 选择快照列表；`empty_text` 与 `count_noun` 生成对应页签状态文案；
`HEADERS` 是两个页签共用的固定列标题。

修改记录：2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划新增。
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


class AuraSlotTab(QWidget):
    """以只读表格展示一个固定 AuraSlot 列表。"""

    HEADERS = [
        "index",
        "技能名称",
        "法术ID",
        "持续时间百分比",
        "层数最小",
        "层数最大",
        "层数当前",
    ]

    def __init__(self, data_key: str, empty_text: str, count_noun: str) -> None:
        super().__init__()
        self.data_key = data_key
        self.empty_text = empty_text
        self.count_noun = count_noun
        self.status_label = QLabel(empty_text, self)
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
        aura_list = (
            decoded_data.get(self.data_key, [])
            if isinstance(decoded_data, dict)
            else []
        )
        stale = bool(snapshot.get("decode_result_is_stale"))

        if not aura_list:
            self.table.setRowCount(0)
            self.status_label.setText(self.empty_text)
            return

        self.table.setRowCount(len(aura_list))
        for row, aura in enumerate(aura_list):
            duration = aura.get("duration", {})
            application = aura.get("application", {})
            spell_ids = ";".join(str(spell_id) for spell_id in aura.get("spellId", []))
            values = (
                aura.get("index", ""),
                aura.get("description", ""),
                spell_ids,
                duration.get("result", ""),
                application.get("minValue", ""),
                application.get("maxValue", ""),
                application.get("result", ""),
            )
            for column, value in enumerate(values):
                self.table.setItem(row, column, self._readonly_item(str(value)))

        if stale:
            self.status_label.setText("当前显示的是旧数据，最新状态不可用。")
        else:
            self.status_label.setText(f"共 {len(aura_list)} 个{self.count_noun}。")

    @staticmethod
    def _readonly_item(text: str) -> QTableWidgetItem:
        item = QTableWidgetItem(text)
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item


__all__ = ["AuraSlotTab"]
