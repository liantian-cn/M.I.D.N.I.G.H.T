"""摘要：以固定表格展示四名小队成员的状态与 HOT 剩余时间。

描述：PartyTab 读取成功快照中的 party 列表，每行使用成员 index 生成单位标识，并展示
十项状态 Cell 的 result。hot1..hot5 始终保留固定列，按 HOT 项的显式 index 填入持续时间；
未配置或协议异常而省略的 HOT 留空。显示表头与英文快照字段相互独立，固定 16 列在当前
窗口内完整显示，并沿用现有空态与旧数据提示契约。

主要变量信息：HEADERS 定义稳定 16 列的显示文本；STATUS_FIELDS 定义英文快照字段；
COLUMN_WIDTHS 定义不会随帧变化的列宽。

修改记录：2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划新增。
2026-08-02，根据小队页中文表头需求本地化指定列并压缩固定列宽。
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


class PartyTab(QWidget):
    """展示小队成员状态与五个固定 HOT 槽。"""

    HEADERS = [
        "单位",
        "存在",
        "目标",
        "职责",
        "range",
        "血量",
        "吸收",
        "吸奶",
        "buff",
        "可驱",
        "减伤",
        "hot1",
        "hot2",
        "hot3",
        "hot4",
        "hot5",
    ]
    COLUMN_WIDTHS = [68, 54, 54, 74, 64, 54, 54, 54, 54, 54, 54, 55, 55, 55, 55, 55]
    STATUS_FIELDS = [
        "exists",
        "target",
        "role",
        "range",
        "health",
        "damage_absorb",
        "heal_absorb",
        "buff",
        "dispellable",
        "big_defensive",
    ]

    def __init__(self) -> None:
        super().__init__()
        self.status_label = QLabel("暂无小队数据。", self)
        self.status_label.setWordWrap(True)

        self.table = QTableWidget(self)
        self.table.setColumnCount(len(self.HEADERS))
        self.table.setHorizontalHeaderLabels(self.HEADERS)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.setHorizontalScrollMode(QAbstractItemView.ScrollMode.ScrollPerPixel)
        self.table.verticalHeader().setVisible(False)
        header = self.table.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.ResizeMode.Fixed)
        header.setStretchLastSection(False)
        for column, width in enumerate(self.COLUMN_WIDTHS):
            self.table.setColumnWidth(column, width)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(5, 5, 5, 5)
        layout.setSpacing(5)
        layout.addWidget(self.status_label)
        layout.addWidget(self.table, 1)

    def refresh_from_decode_snapshot(self, snapshot: dict[str, Any]) -> None:
        decoded_data = snapshot.get("decoded_data")
        party = decoded_data.get("party", []) if isinstance(decoded_data, dict) else []
        stale = bool(snapshot.get("decode_result_is_stale"))
        if not party:
            self.table.setRowCount(0)
            self.status_label.setText("暂无小队数据。")
            return

        self.table.setRowCount(len(party))
        for row, member in enumerate(party):
            member_index = member.get("index", "")
            values: list[Any] = [f"party{member_index}"]
            for field in self.STATUS_FIELDS:
                record = member.get(field)
                values.append(record.get("result", "") if isinstance(record, dict) else "")
            hot_values: dict[int, Any] = {}
            for hot in member.get("hots") or []:
                hot_index = hot.get("index")
                if isinstance(hot_index, int) and 1 <= hot_index <= 5:
                    hot_values[hot_index] = hot.get("duration_result", "")
            values.extend(hot_values.get(index, "") for index in range(1, 6))
            for column, value in enumerate(values):
                self.table.setItem(row, column, self._readonly_item(str(value)))

        if stale:
            self.status_label.setText("当前显示的是旧数据，最新状态不可用。")
        else:
            self.status_label.setText(f"共 {len(party)} 名小队成员。")

    @staticmethod
    def _readonly_item(text: str) -> QTableWidgetItem:
        item = QTableWidgetItem(text)
        item.setFlags(Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled)
        return item


__all__ = ["PartyTab"]
