"""摘要：解析普通 Phantom 4x4 数据 Cell。

描述：普通 Cell 只使用中心 2x2 像素抵抗边缘缩放与抗锯齿影响，并按稳定协议把
R/G/B 分别解释为 classification、index 和 raw value。保留 Terminal 有效的统计属性，
删除旧产品的颜色名称、黑白判断和剩余秒数曲线。

主要变量信息：`valid_array` 是中心 2x2 RGB 数组；`channel_values` 是各通道平均后取整
得到的三个 8 位协议值。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
"""

from __future__ import annotations

import numpy as np

from .classification import CLASSIFICATION_BY_CODE


class Cell:
    """按中心像素解析一个一基坐标普通 Cell。"""

    def __init__(self, x: int, y: int, pix_array: np.ndarray) -> None:
        if not isinstance(pix_array, np.ndarray):
            raise TypeError("Cell 像素必须是 numpy.ndarray")
        if pix_array.dtype != np.uint8 or pix_array.shape != (4, 4, 3):
            raise ValueError("Cell 像素必须是 4x4x3 uint8 RGB 数组")
        self.x = int(x)
        self.y = int(y)
        self.pix_array = pix_array
        self.valid_array = pix_array[1:3, 1:3]

    @property
    def channel_values(self) -> tuple[int, int, int]:
        values = np.rint(np.mean(self.valid_array, axis=(0, 1))).astype(np.uint8)
        return int(values[0]), int(values[1]), int(values[2])

    @property
    def mean(self) -> float:
        return float(np.mean(self.valid_array))

    @property
    def decimal(self) -> float:
        return self.mean / 255.0

    @property
    def percent(self) -> float:
        return self.decimal * 100.0

    @property
    def remaining(self) -> float:
        return self.percent

    @property
    def is_pure(self) -> bool:
        return bool(np.all(self.valid_array == self.valid_array[0, 0]))

    @property
    def is_not_pure(self) -> bool:
        return not self.is_pure

    @property
    def classification_code(self) -> int:
        return self.channel_values[0]

    @property
    def classification(self) -> str:
        return CLASSIFICATION_BY_CODE.get(
            self.classification_code,
            f"UNKNOWN_{self.classification_code}",
        )

    @property
    def index(self) -> int:
        return self.channel_values[1]

    @property
    def raw_value(self) -> int:
        return self.channel_values[2]


__all__ = ["Cell"]
