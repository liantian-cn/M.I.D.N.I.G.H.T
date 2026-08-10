"""摘要：提供玩家与环境状态页共享的 Terminal 样式。

描述：保留 Terminal 的摘要、分区标题、只读单行/多行值输入框与无边框滚动区样式，不固定前景
或背景色，使控件继续遵循当前 Qt palette。

主要变量信息：`STATUS_TAB_STYLESHEET` 是状态信息页共用的 QSS。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划复用
Terminal 状态页样式。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划压缩约 15% 垂直留白。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划增加多行只读值样式。
"""

from __future__ import annotations

from PySide6.QtWidgets import QLabel, QLineEdit, QPlainTextEdit, QWidget

STATUS_TAB_STYLESHEET = """
QLabel#statusSummaryLabel {
    padding: 5px 8px 8px 8px;
    font-size: 13px;
}

QLabel#statusSectionTitleLabel {
    font-weight: 600;
    padding: 3px 0 5px 0;
}

QLabel[statusRole="fieldLabel"] {
    padding-right: 6px;
}

QLineEdit[statusRole="value"] {
    border: 1px solid;
    border-radius: 6px;
    padding: 4px 8px;
}

QPlainTextEdit[statusRole="multilineValue"] {
    border: 1px solid;
    border-radius: 6px;
    padding: 4px 8px;
}

QScrollArea {
    border: none;
}
"""


def apply_status_tab_skin(tab: QWidget, summary_label: QLabel) -> None:
    tab.setObjectName("statusTab")
    tab.setStyleSheet(STATUS_TAB_STYLESHEET)
    summary_label.setObjectName("statusSummaryLabel")


def mark_section_title(label: QLabel) -> None:
    label.setObjectName("statusSectionTitleLabel")


def mark_field_label(label: QLabel) -> None:
    label.setProperty("statusRole", "fieldLabel")


def mark_value_input(line_edit: QLineEdit) -> None:
    line_edit.setProperty("statusRole", "value")


def mark_multiline_value_input(text_edit: QPlainTextEdit) -> None:
    text_edit.setProperty("statusRole", "multilineValue")


__all__ = [
    "apply_status_tab_skin",
    "mark_field_label",
    "mark_multiline_value_input",
    "mark_section_title",
    "mark_value_input",
]
