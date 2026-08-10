"""摘要：解析 Phantom 8x8 IconCell 的图像身份与边框类别。

描述：图标 hash 只使用中心 6x6，边框颜色从外围像素独立反向为当前上游标题类型，再
聚合为四个可持久化类别；其余非空图标进入 Other。中心区域全黑表示图标隐藏，不进入
未知图标缓存。本阶段按确认决定保留 Terminal 的中心特征算法。

主要变量信息：`valid_array` 是连续中心 6x6 RGB 特征；`border_footnote` 是 Terminal
一致的右下角 2x2 分类色区域；`hash` 使用固定 seed 0 的 xxh3_64。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划增加完整颜色类型和 Other。
"""

from __future__ import annotations

import numpy as np
import xxhash

from .color import ICON_CATEGORY_BY_TYPE, icon_type_from_colors


class IconCell:
    """按中心纹理和外围边框解析一个一基坐标 IconCell。"""

    def __init__(self, x: int, y: int, pix_array: np.ndarray) -> None:
        if not isinstance(pix_array, np.ndarray):
            raise TypeError("IconCell 像素必须是 numpy.ndarray")
        if pix_array.dtype != np.uint8 or pix_array.shape != (8, 8, 3):
            raise ValueError("IconCell 像素必须是 8x8x3 uint8 RGB 数组")
        self.x = int(x)
        self.y = int(y)
        self.pix_array = pix_array
        self.valid_array = np.ascontiguousarray(pix_array[1:7, 1:7].copy())
        self.border_footnote = np.ascontiguousarray(pix_array[-2:, -2:].copy())
        self._hash: str | None = None

    @property
    def is_blank(self) -> bool:
        return bool(np.all(self.valid_array == 0))

    @property
    def icon_hash(self) -> str | None:
        if self.is_blank:
            return None
        if self._hash is None:
            self._hash = xxhash.xxh3_64_hexdigest(self.valid_array, seed=0)
        return self._hash

    @property
    def icon_category(self) -> str | None:
        if self.is_blank:
            return None
        icon_type = self.icon_type
        return ICON_CATEGORY_BY_TYPE.get(icon_type) if icon_type is not None else None

    @property
    def icon_type(self) -> str | None:
        """返回当前边框语义；未知的非空图标归入 UNKNOWN。"""

        if self.is_blank:
            return None
        colors = (
            (int(pixel[0]), int(pixel[1]), int(pixel[2]))
            for pixel in self.border_footnote.reshape(-1, 3)
        )
        return icon_type_from_colors(colors)


__all__ = ["IconCell"]
