"""摘要：展示当前玩家、目标、焦点、环境与辅助信息的 result 值。

描述：四个页面复用 Terminal 的滚动区、横向分区、只读居中输入框和统一 snapshot 刷新
入口。页面只读取字段 envelope 的 `result`，不展示 classification、index、raw_value 或
图标内部元数据；当前失败但存在最后成功数据时保留值并明确标记旧数据。玩家页读取
`decoded_data["player"]["status"]`，目标/焦点页直接读取顶层平铺字典 `decoded_data
["target"]`/`["focus"]`，与 extractor 的有意分层差异保持一致。环境页另外读取顶层
assisted_combat 与 interrupt_blacklist，后者用只读多行框逐行展示标准 IconCell 的 result。

主要变量信息：`SECTION_DEFINITIONS` 决定每页业务字段分组；`value_inputs` 供刷新与测试
按字段名访问固定尺寸控件。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划统一压缩垂直间距。
2026-08-01，根据 Phase 2.6 Target and Focus Matrix Decoder 冻结计划新增 target/focus 页。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划增加辅助图标与黑名单展示。
2026-08-02，根据环境页黑名单布局需求将黑名单调整为左侧五分之一宽度列。
"""

from __future__ import annotations

from typing import Any, ClassVar

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPlainTextEdit,
    QScrollArea,
    QVBoxLayout,
    QWidget,
)

from .status_tab_style import (
    apply_status_tab_skin,
    mark_field_label,
    mark_multiline_value_input,
    mark_section_title,
    mark_value_input,
)

FieldDefinition = tuple[str, str]
SectionDefinition = tuple[str, list[FieldDefinition]]


class ResultStatusTab(QWidget):
    """把标准解码 snapshot 映射为只读业务结果。"""

    SECTION_DEFINITIONS: ClassVar[list[SectionDefinition]] = []
    EMPTY_TEXT: ClassVar[str] = "暂无数据。"
    CURRENT_TEXT: ClassVar[str] = "当前数据。"

    def __init__(self) -> None:
        super().__init__()
        self.value_inputs: dict[str, QLineEdit] = {}
        self.status_label = QLabel(self.EMPTY_TEXT, self)
        self.status_label.setWordWrap(True)

        content = QWidget(self)
        self.content_layout = QHBoxLayout(content)
        self.content_layout.setContentsMargins(5, 0, 5, 5)
        self.content_layout.setSpacing(10)
        for title, fields in self.SECTION_DEFINITIONS:
            self.content_layout.addWidget(self._build_section(title, fields), 1)

        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QScrollArea.Shape.NoFrame)
        scroll_area.setWidget(content)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(5, 5, 5, 5)
        layout.setSpacing(5)
        layout.addWidget(self.status_label)
        layout.addWidget(scroll_area, 1)
        apply_status_tab_skin(self, self.status_label)

    def _build_section(self, title: str, fields: list[FieldDefinition]) -> QWidget:
        container = QWidget(self)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(5)
        title_label = QLabel(title, container)
        mark_section_title(title_label)
        layout.addWidget(title_label)
        for field_name, label_text in fields:
            field_label = QLabel(label_text, container)
            field_label.setAlignment(
                Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter
            )
            mark_field_label(field_label)
            value_input = QLineEdit("None", container)
            value_input.setReadOnly(True)
            value_input.setAlignment(Qt.AlignmentFlag.AlignCenter)
            value_input.setMinimumWidth(110)
            mark_value_input(value_input)
            row = QHBoxLayout()
            row.setSpacing(5)
            row.addWidget(field_label, 1)
            row.addWidget(value_input, 1)
            layout.addLayout(row)
            self.value_inputs[field_name] = value_input
        layout.addStretch(1)
        return container

    def refresh_from_decode_snapshot(self, snapshot: dict[str, Any]) -> None:
        decoded_data = snapshot.get("decoded_data")
        stale = bool(snapshot.get("decode_result_is_stale"))
        fields = self._select_fields(decoded_data)
        if not isinstance(fields, dict):
            self._clear_values()
            self.status_label.setText(self.EMPTY_TEXT)
            return
        for field_name, value_input in self.value_inputs.items():
            envelope = fields.get(field_name)
            result = envelope.get("result") if isinstance(envelope, dict) else None
            value_input.setText(self._format_value(result))
        self.status_label.setText(
            "当前显示的是旧数据，最新状态不可用。" if stale else self.CURRENT_TEXT
        )

    def _select_fields(self, decoded_data: object) -> dict[str, Any] | None:
        raise NotImplementedError

    def _clear_values(self) -> None:
        for value_input in self.value_inputs.values():
            value_input.setText("None")

    @staticmethod
    def _format_value(value: Any) -> str:
        if value is None:
            return "None"
        if isinstance(value, bool):
            return "True" if value else "False"
        if isinstance(value, float):
            return f"{value:.6f}".rstrip("0").rstrip(".")
        return str(value)


class PlayerStatusTab(ResultStatusTab):
    """展示当前 `01??` 玩家状态。"""

    EMPTY_TEXT = "暂无玩家状态数据。"
    CURRENT_TEXT = "当前玩家状态。"
    SECTION_DEFINITIONS = [
        (
            "基础信息",
            [
                ("is_alive", "存活"),
                ("class_id", "职业"),
                ("specialization_index", "专精"),
                ("role", "职责"),
                ("health_pct", "生命百分比"),
                ("power_pct", "资源百分比"),
                ("in_group", "在队伍中"),
                ("in_vehicle_or_mounted", "载具或坐骑"),
                ("hero_talent_code", "英雄天赋"),
            ],
        ),
        (
            "战斗状态",
            [
                ("in_combat", "战斗中"),
                ("is_player_target", "目标是玩家"),
                ("is_moving", "移动中"),
                ("melee_enemies_count", "近战敌人数"),
                ("has_big_defensive", "大型防御"),
                ("has_dispellable_debuff", "可驱散减益"),
                ("damage_absorb_over_threshold", "伤害吸收超阈值"),
                ("heal_absorb_over_threshold", "治疗吸收超阈值"),
                ("has_party_buff", "队伍增益"),
            ],
        ),
        (
            "施法与物品",
            [
                ("cast_icon", "施法图标"),
                ("cast_progress", "施法进度"),
                ("cast_empowered", "蓄力施法"),
                ("cast_target", "施法目标"),
                ("is_targeting_spell", "选择法术目标"),
                ("is_chatting", "聊天输入"),
                ("trinket_13_ready", "饰品 13 可用"),
                ("trinket_14_ready", "饰品 14 可用"),
                ("healthstone_ready", "生命石可用"),
                ("heal_potion_ready", "治疗药水可用"),
            ],
        ),
    ]

    def _select_fields(self, decoded_data: object) -> dict[str, Any] | None:
        if not isinstance(decoded_data, dict):
            return None
        player = decoded_data.get("player")
        if not isinstance(player, dict):
            return None
        status = player.get("status")
        return status if isinstance(status, dict) else None


class EnvironmentInfoTab(ResultStatusTab):
    """展示当前 `06??` 环境信息。"""

    EMPTY_TEXT = "暂无环境信息数据。"
    CURRENT_TEXT = "当前环境信息。"
    SECTION_DEFINITIONS = [
        (
            "队伍与副本",
            [
                ("group_member_count", "成员数量"),
                ("group_type", "队伍类型"),
                ("player_raid_index", "团队索引"),
                ("boss_encounter_code", "首领战"),
                ("instance_difficulty_id", "副本难度"),
            ],
        ),
        (
            "运行环境",
            [
                ("combat_time_seconds", "战斗时间（秒）"),
                ("use_mouse", "使用鼠标"),
                ("spell_queue_window_ms", "施法队列窗口（毫秒）"),
                ("flash", "闪烁信号"),
                ("delayed_update", "延迟状态"),
                ("burst_remaining_seconds", "爆发剩余时间（秒）"),
                ("enabled", "插件启用"),
                ("assisted_combat", "一键辅助推荐技能"),
            ],
        ),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.interrupt_blacklist_panel = QWidget(self)
        blacklist_layout = QVBoxLayout(self.interrupt_blacklist_panel)
        blacklist_layout.setContentsMargins(0, 0, 0, 0)
        blacklist_layout.setSpacing(5)
        blacklist_label = QLabel("打断黑名单", self.interrupt_blacklist_panel)
        mark_field_label(blacklist_label)
        self.interrupt_blacklist_input = QPlainTextEdit(self.interrupt_blacklist_panel)
        self.interrupt_blacklist_input.setReadOnly(True)
        mark_multiline_value_input(self.interrupt_blacklist_input)
        blacklist_layout.addWidget(blacklist_label)
        blacklist_layout.addWidget(self.interrupt_blacklist_input, 1)

        self.content_layout.insertWidget(0, self.interrupt_blacklist_panel, 1)
        self.content_layout.setStretch(1, 2)
        self.content_layout.setStretch(2, 2)

    def refresh_from_decode_snapshot(self, snapshot: dict[str, Any]) -> None:
        super().refresh_from_decode_snapshot(snapshot)
        decoded_data = snapshot.get("decoded_data")
        if not isinstance(decoded_data, dict):
            self.interrupt_blacklist_input.clear()
            return
        blacklist = decoded_data.get("interrupt_blacklist")
        if not isinstance(blacklist, list):
            self.interrupt_blacklist_input.clear()
            return
        results = [
            str(record["result"])
            for record in blacklist
            if isinstance(record, dict) and record.get("result") is not None
        ]
        self.interrupt_blacklist_input.setPlainText("\n".join(results))

    def _select_fields(self, decoded_data: object) -> dict[str, Any] | None:
        if not isinstance(decoded_data, dict):
            return None
        environment = decoded_data.get("environment")
        if not isinstance(environment, dict):
            return None
        return {
            **environment,
            "assisted_combat": decoded_data.get("assisted_combat"),
        }


class TargetStatusTab(ResultStatusTab):
    """展示当前 `02??` 目标状态；字段直接读取顶层 `target` 平铺字典。"""

    EMPTY_TEXT = "暂无目标状态数据。"
    CURRENT_TEXT = "当前目标状态。"
    SECTION_DEFINITIONS = [
        (
            "基础信息",
            [
                ("is_exists", "存在"),
                ("is_alive", "存活"),
                ("health_pct", "生命百分比"),
                ("is_enemy", "敌对"),
                ("can_attack", "可攻击"),
            ],
        ),
        (
            "范围与战斗",
            [
                ("in_ranged", "远程范围内"),
                ("in_melee", "近战范围内"),
                ("in_combat", "战斗中"),
            ],
        ),
        (
            "施法与增益",
            [
                ("cast_progress", "施法进度"),
                ("cast_interruptible", "可打断"),
                ("has_dispellable_buff", "可驱散增益"),
                ("cast_icon", "施法图标"),
            ],
        ),
    ]

    def _select_fields(self, decoded_data: object) -> dict[str, Any] | None:
        if not isinstance(decoded_data, dict):
            return None
        target = decoded_data.get("target")
        return target if isinstance(target, dict) else None


class FocusStatusTab(ResultStatusTab):
    """展示当前 `03??` 焦点状态；字段直接读取顶层 `focus` 平铺字典。"""

    EMPTY_TEXT = "暂无焦点状态数据。"
    CURRENT_TEXT = "当前焦点状态。"
    SECTION_DEFINITIONS = [
        (
            "基础信息",
            [
                ("is_exists", "存在"),
                ("is_alive", "存活"),
                ("health_pct", "生命百分比"),
                ("is_enemy", "敌对"),
                ("can_attack", "可攻击"),
            ],
        ),
        (
            "范围与战斗",
            [
                ("in_ranged", "远程范围内"),
                ("in_melee", "近战范围内"),
                ("in_combat", "战斗中"),
            ],
        ),
        (
            "施法与增益",
            [
                ("cast_progress", "施法进度"),
                ("cast_interruptible", "可打断"),
                ("has_dispellable_buff", "可驱散增益"),
                ("cast_icon", "施法图标"),
            ],
        ),
    ]

    def _select_fields(self, decoded_data: object) -> dict[str, Any] | None:
        if not isinstance(decoded_data, dict):
            return None
        focus = decoded_data.get("focus")
        return focus if isinstance(focus, dict) else None


__all__ = [
    "EnvironmentInfoTab",
    "FocusStatusTab",
    "PlayerStatusTab",
    "ResultStatusTab",
    "TargetStatusTab",
]
