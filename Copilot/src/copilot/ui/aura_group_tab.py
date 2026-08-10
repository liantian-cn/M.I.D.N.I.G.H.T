"""摘要：以表格展示动态玩家减益 AuraGroup 解码结果。

描述：AuraGroupTab 读取顶层 ``player_debuff`` 列表。每行使用 IconCell 的 result 作为
技能名称，显示剩余持续时间百分比和固定 0..4 层数结果。表格只读，并复用主窗口提供的
最后成功快照、空态和旧数据提示契约；动态项不包含固定 AuraSlot 的 index 或法术 ID。

主要变量信息：`HEADERS` 是页签的固定三列标题；`refresh_from_decode_snapshot` 固定读取
`player_debuff`。

修改记录：2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划新增。
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


class AuraGroupTab(QWidget):
    """以只读三列表格展示动态玩家减益。"""

    HEADERS = ["技能名称", "持续时间百分比", "层数当前"]

    def __init__(self) -> None:
        super().__init__()
        self.status_label = QLabel("暂无玩家减益数据。", self)
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
            decoded_data.get("player_debuff", [])
            if isinstance(decoded_data, dict)
            else []
        )
        if not aura_list:
            self.table.setRowCount(0)
            self.status_label.setText("暂无玩家减益数据。")
            return

        self.table.setRowCount(len(aura_list))
        for row, aura in enumerate(aura_list):
            icon = aura.get("icon", {})
            duration = aura.get("duration", {})
            application = aura.get("application", {})
            values = (
                icon.get("result", ""),
                duration.get("result", ""),
                application.get("result", ""),
            )
            for column, value in enumerate(values):
                self.table.setItem(row, column, self._readonly_item(str(value)))

        if snapshot.get("decode_result_is_stale"):
            self.status_label.setText("当前显示的是旧数据，最新状态不可用。")
        else:
            self.status_label.setText(f"共 {len(aura_list)} 个玩家减益。")

    @staticmethod
    def _readonly_item(text: str) -> QTableWidgetItem:
        item = QTableWidgetItem(text)
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item


__all__ = ["AuraGroupTab"]
