"""摘要：按当前 Phantom 几何提供一基 Matrix 解码访问器。

描述：构造时严格校验 `60x17` Cell 对应的 RGB ndarray，并验证左右角落直接 RGB 标记。
普通 Cell、IconCell 和三种业务 Bar 都通过明确几何切片创建；UTF 标题按纯色 Cell 的
非零 RGB 字节逐字符解码，并只接受 Phantom 当前使用的 `*#title*#` 包装。

主要变量信息：`matrix` 是只读使用的当前捕获数组；`CELL_SIZE` 与矩阵行列是绑定当前
上游提交的适配常量，不是稳定产品契约。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-02，根据 Phase 2.8 Aura Slot Matrix Decoder 冻结计划新增 ApplicationBar 访问器。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划新增 UTF 标题读取。
"""

from __future__ import annotations

import operator
from typing import SupportsIndex, cast

import numpy as np

from .bar import ApplicationBar, ChargeBar, DurationBar
from .cell import Cell
from .icon_cell import IconCell

UPSTREAM_COMMIT = "41d782953370e3ada31eeefb137bac48d11a1e3f"
CELL_SIZE = 4
WIDTH_CELLS = 60
HEIGHT_CELLS = 17
EXPECTED_SHAPE = (HEIGHT_CELLS * CELL_SIZE, WIDTH_CELLS * CELL_SIZE, 3)
DEEP_MARKER = (15, 25, 20)
LIGHT_MARKER = (25, 15, 20)


class MatrixDecoder:
    """访问当前 Phantom 矩阵中的一基 Cell 区域。"""

    def __init__(self, matrix: np.ndarray) -> None:
        if not isinstance(matrix, np.ndarray):
            raise TypeError("矩阵必须是 numpy.ndarray")
        if matrix.dtype != np.uint8 or matrix.shape != EXPECTED_SHAPE:
            raise ValueError(f"矩阵必须是 {EXPECTED_SHAPE} 的 uint8 RGB 数组")
        self.matrix = matrix
        self._validate_markers()

    def _slice_cells(
        self,
        x: int,
        y: int,
        width_cells: int,
        height_cells: int,
    ) -> np.ndarray:
        x = self._protocol_integer("x", x)
        y = self._protocol_integer("y", y)
        width_cells = self._protocol_integer("width_cells", width_cells)
        height_cells = self._protocol_integer("height_cells", height_cells)
        if x < 1 or y < 1 or width_cells < 1 or height_cells < 1:
            raise ValueError("Cell 坐标与尺寸必须为正整数")
        if x + width_cells - 1 > WIDTH_CELLS or y + height_cells - 1 > HEIGHT_CELLS:
            raise IndexError("Cell 区域超出矩阵边界")
        left = (x - 1) * CELL_SIZE
        top = (y - 1) * CELL_SIZE
        return self.matrix[
            top : top + height_cells * CELL_SIZE,
            left : left + width_cells * CELL_SIZE,
        ]

    @staticmethod
    def _protocol_integer(name: str, value: object) -> int:
        if isinstance(value, bool):
            raise TypeError(f"{name} 必须是整数，不能是 bool")
        if not hasattr(value, "__index__"):
            raise TypeError(f"{name} 必须是整数")
        try:
            return operator.index(cast(SupportsIndex, value))
        except TypeError as exc:
            raise TypeError(f"{name} 必须是整数") from exc

    def get_cell(self, x: object, y: object) -> Cell:
        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        return Cell(x_value, y_value, self._slice_cells(x_value, y_value, 1, 1))

    def get_icon_cell(self, x: object, y: object) -> IconCell:
        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        return IconCell(
            x_value,
            y_value,
            self._slice_cells(x_value, y_value, 2, 2),
        )

    def get_duration_bar(self, x: object, y: object) -> DurationBar:
        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        return DurationBar(
            x_value,
            y_value,
            self._slice_cells(x_value, y_value, 4, 1),
        )

    def get_application_bar(self, x: object, y: object) -> ApplicationBar:
        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        return ApplicationBar(
            x_value,
            y_value,
            self._slice_cells(x_value, y_value, 4, 1),
        )

    def get_charge_bar(self, x: object, y: object) -> ChargeBar:
        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        return ChargeBar(
            x_value,
            y_value,
            self._slice_cells(x_value, y_value, 1, 2),
        )

    def read_utf_title(self, x: object, y: object, length: object) -> str | None:
        """从连续纯色 Cell 中读取 Phantom 包裹的 UTF-8 标题。"""

        x_value = self._protocol_integer("x", x)
        y_value = self._protocol_integer("y", y)
        length_value = self._protocol_integer("length", length)
        if length_value < 0:
            raise ValueError("UTF Cell 数量不能为负数")

        characters: list[str] = []
        for offset in range(length_value):
            cell = self.get_cell(x_value + offset, y_value)
            if not cell.is_pure:
                return None
            if cell.channel_values == (0, 0, 0):
                break
            byte_values = [value for value in cell.channel_values if value != 0]
            try:
                character = bytes(byte_values).decode("utf-8")
            except UnicodeDecodeError:
                return None
            if not character.isprintable():
                return None
            characters.append(character)

        decoded = "".join(characters)
        start = decoded.find("*#")
        if start < 0:
            return None
        end = decoded.find("*#", start + 2)
        if end < 0:
            return None
        title = decoded[start + 2 : end].strip()
        return title or None

    def _validate_markers(self) -> None:
        expected = {
            (1, 1): DEEP_MARKER,
            (2, 2): DEEP_MARKER,
            (1, 2): LIGHT_MARKER,
            (2, 1): LIGHT_MARKER,
            (59, 16): DEEP_MARKER,
            (60, 17): DEEP_MARKER,
            (59, 17): LIGHT_MARKER,
            (60, 16): LIGHT_MARKER,
        }
        for (x, y), color in expected.items():
            if self.get_cell(x, y).channel_values != color:
                raise ValueError(f"矩阵定位标记不匹配: ({x}, {y})")


__all__ = [
    "CELL_SIZE",
    "EXPECTED_SHAPE",
    "HEIGHT_CELLS",
    "MatrixDecoder",
    "UPSTREAM_COMMIT",
    "WIDTH_CELLS",
]
