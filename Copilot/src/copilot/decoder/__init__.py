"""公开 Copilot Matrix 解码原语、适配器与 extractor。"""

from .bar import ApplicationBar, ChargeBar, DurationBar
from .cell import Cell
from .database import (
    DatabaseResetDeclined,
    DatabaseStartupError,
    IncompleteDatabaseCleanupError,
    prepare_icon_database,
)
from .extractor import (
    decode_aura_group_container,
    decode_horizontal_icon_list,
    decode_optional_icon,
    decode_party_container,
    decode_raid_container,
    extract_matrix,
    learn_badge_utf_title,
)
from .icon_cell import IconCell
from .matrix import MatrixDecoder
from .title_manager import IconTitleManager

__all__ = [
    "ApplicationBar",
    "Cell",
    "ChargeBar",
    "DatabaseResetDeclined",
    "DatabaseStartupError",
    "DurationBar",
    "IncompleteDatabaseCleanupError",
    "IconCell",
    "IconTitleManager",
    "MatrixDecoder",
    "decode_aura_group_container",
    "decode_horizontal_icon_list",
    "decode_optional_icon",
    "decode_party_container",
    "decode_raid_container",
    "extract_matrix",
    "learn_badge_utf_title",
    "prepare_icon_database",
]
