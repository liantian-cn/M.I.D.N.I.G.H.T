"""摘要：公开 Copilot 主窗口界面。

描述：导出固定尺寸的 ``MainWindow``、玩家/环境状态页、小队/团队页、技能页、技能充能页、Aura 页和
标题编辑器；导入包不会创建 QApplication、窗口、worker 线程或数据库连接。

主要变量信息：无。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增 UI 包。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划导出状态页。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划导出标题编辑器。
2026-08-02，根据 Phase 2.6 Spell Matrix Decoder 冻结计划导出技能页。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划导出技能充能页。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划导出固定 Aura 页。
2026-08-02，根据 Phase 2.9 Matrix Decoder 冻结计划导出动态 AuraGroup 页。
2026-08-02，根据 Phase 2.10 Party Matrix Decoder 冻结计划导出小队页。
2026-08-02，根据 Phase 2.11 Raid Matrix Decoder 冻结计划导出团队页。
"""

from .aura_group_tab import AuraGroupTab
from .aura_slot_tab import AuraSlotTab
from .charge_tab import ChargeTab
from .main_window import MainWindow
from .party_tab import PartyTab
from .raid_tab import RaidTab
from .spell_tab import SpellTab
from .status_tabs import EnvironmentInfoTab, PlayerStatusTab
from .title_editor_dialog import TitleEditorDialog

__all__ = [
    "AuraGroupTab",
    "AuraSlotTab",
    "ChargeTab",
    "EnvironmentInfoTab",
    "MainWindow",
    "PartyTab",
    "RaidTab",
    "PlayerStatusTab",
    "SpellTab",
    "TitleEditorDialog",
]
