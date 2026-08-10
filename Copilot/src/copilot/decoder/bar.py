"""摘要：解析 Phantom 水平 Duration/Application Bar 与垂直 ChargeBar。

描述：三种业务 StatusBar 都只读取远离边缘的中间两排或两列像素，并按 B 通道是否为
255 计算填充比例。ApplicationBar 复用 DurationBar 的水平几何，仅提供清晰的层数业务
类型。R/G 保留 classification/index；ratio 使用 `0.0..1.0`，percent 保持
`0.0..100.0` 浮点值。

主要变量信息：`sample_array` 是方向相关的稳定采样区域；`filled_steps` 统计填充方向上
至少一个中心采样像素为满值的位置。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-02，根据 Phase 2.7 Charge Matrix Decoder 冻结计划新增 ratio 并兼容 percent。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划新增 ApplicationBar。
"""

from __future__ import annotations

import numpy as np

from .classification import CLASSIFICATION_BY_CODE


class _Bar:
    expected_shape: tuple[int, int, int]
    orientation: str

    def __init__(self, x: int, y: int, pix_array: np.ndarray) -> None:
        if not isinstance(pix_array, np.ndarray):
            raise TypeError("Bar 像素必须是 numpy.ndarray")
        if pix_array.dtype != np.uint8 or pix_array.shape != self.expected_shape:
            raise ValueError(
                f"{type(self).__name__} 像素必须是 {self.expected_shape} uint8 RGB 数组"
            )
        self.x = int(x)
        self.y = int(y)
        self.pix_array = pix_array

    @property
    def sample_array(self) -> np.ndarray:
        raise NotImplementedError

    @property
    def classification_code(self) -> int:
        return int(np.rint(np.mean(self.sample_array[..., 0])))

    @property
    def classification(self) -> str:
        return CLASSIFICATION_BY_CODE.get(
            self.classification_code,
            f"UNKNOWN_{self.classification_code}",
        )

    @property
    def index(self) -> int:
        return int(np.rint(np.mean(self.sample_array[..., 1])))

    @property
    def filled_steps(self) -> float:
        raise NotImplementedError

    @property
    def total_steps(self) -> int:
        raise NotImplementedError

    @property
    def ratio(self) -> float:
        return self.filled_steps / self.total_steps

    @property
    def percent(self) -> float:
        return self.ratio * 100.0


class DurationBar(_Bar):
    expected_shape = (4, 16, 3)
    orientation = "horizontal"

    @property
    def sample_array(self) -> np.ndarray:
        return self.pix_array[1:3, :]

    @property
    def filled_steps(self) -> float:
        return float(np.count_nonzero(self.sample_array[..., 2] == 255)) / 2.0

    @property
    def total_steps(self) -> int:
        return 16


class ApplicationBar(DurationBar):
    """使用水平 Bar 比例表达 Aura 层数。"""


class ChargeBar(_Bar):
    expected_shape = (8, 4, 3)
    orientation = "vertical"

    @property
    def sample_array(self) -> np.ndarray:
        return self.pix_array[:, 1:3]

    @property
    def filled_steps(self) -> float:
        return float(np.count_nonzero(self.sample_array[..., 2] == 255)) / 2.0

    @property
    def total_steps(self) -> int:
        return 8


__all__ = ["ApplicationBar", "ChargeBar", "DurationBar"]
