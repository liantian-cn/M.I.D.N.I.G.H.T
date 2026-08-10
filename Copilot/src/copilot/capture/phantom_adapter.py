"""摘要：保存当前 Phantom 静态定位标记的动态适配数据。

描述：依据 PhantomProject 当前实际加载的 ``src/0901_mark.lua`` 构造 2x2 Cell 标记
模板。每个 Cell 当前占用 4x4 物理像素，因此适配器生成 8x8 RGB 模板。这里的颜色、
Cell 尺寸和模板几何仅对应已核对的上游提交，不是 Copilot 的稳定产品契约。

主要变量信息：``UPSTREAM_COMMIT`` 标识本次核对版本；``CELL_PIXEL_SIZE`` 是当前
Cell 的物理像素边长；``MARKER_TEMPLATE`` 是当前上游标记的 RGB 模板；
``MATCH_THRESHOLD`` 是模板匹配阈值。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划核对并接入当前 Phantom
定位标记；2026-08-01，根据 audit finding 公开动态 Cell 像素尺寸供定位几何校验。
"""

from __future__ import annotations

import numpy as np

UPSTREAM_COMMIT = "643fbc525f2173e80d571af7f43f739e6eaeb229"
MATCH_THRESHOLD = 0.999

_DEEP_COLOR = np.array([15, 25, 20], dtype=np.uint8)
_LIGHT_COLOR = np.array([25, 15, 20], dtype=np.uint8)
CELL_PIXEL_SIZE = 4
_DEEP_CELL = np.broadcast_to(
    _DEEP_COLOR, (CELL_PIXEL_SIZE, CELL_PIXEL_SIZE, 3)
)
_LIGHT_CELL = np.broadcast_to(
    _LIGHT_COLOR, (CELL_PIXEL_SIZE, CELL_PIXEL_SIZE, 3)
)
MARKER_TEMPLATE = np.vstack(
    (
        np.hstack((_DEEP_CELL, _LIGHT_CELL)),
        np.hstack((_LIGHT_CELL, _DEEP_CELL)),
    )
).astype(np.uint8, copy=False)

__all__ = [
    "CELL_PIXEL_SIZE",
    "MARKER_TEMPLATE",
    "MATCH_THRESHOLD",
    "UPSTREAM_COMMIT",
]
