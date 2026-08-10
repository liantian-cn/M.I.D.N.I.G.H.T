"""摘要：在 RGB 显示器帧中严格定位 Phantom 矩阵边界。

描述：使用当前 Phantom 动态标记模板执行 OpenCV 匹配。只有全帧恰好出现两个匹配，
且两者形成位于输入帧内、宽高均可按当前 Cell 物理像素尺寸完整分割的非空半开边界时
才成功；零个、一个或多于两个匹配均失败，不选择最小面积候选，也不解析矩阵业务内容。

主要变量信息：``matches`` 保存超过阈值的全部模板左上角坐标；返回值依次为相对显示器
的 ``left``、``top``、``right``、``bottom`` 半开边界。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增严格双标记定位；
2026-08-01，根据 audit finding 增加动态 Cell 像素尺寸整除校验。
"""

from __future__ import annotations

import cv2
import numpy as np

from .phantom_adapter import CELL_PIXEL_SIZE, MARKER_TEMPLATE, MATCH_THRESHOLD

Bounds = tuple[int, int, int, int]


def locate_matrix(rgb_frame: np.ndarray) -> Bounds | None:
    """返回恰好两个标记围成的完整半开区域，无法严格定位时返回 ``None``。"""

    if not isinstance(rgb_frame, np.ndarray):
        raise TypeError("截图帧必须是 numpy.ndarray")
    if rgb_frame.dtype != np.uint8 or rgb_frame.ndim != 3 or rgb_frame.shape[2] != 3:
        raise ValueError("截图帧必须是 HxWx3 的 uint8 RGB 数组")

    frame_height, frame_width = rgb_frame.shape[:2]
    template_height, template_width = MARKER_TEMPLATE.shape[:2]
    if frame_height < template_height or frame_width < template_width:
        return None

    match_result = cv2.matchTemplate(
        rgb_frame, MARKER_TEMPLATE, cv2.TM_CCOEFF_NORMED
    )
    match_y, match_x = np.where(match_result >= MATCH_THRESHOLD)
    matches = [(int(x), int(y)) for y, x in zip(match_y, match_x)]
    if len(matches) != 2:
        return None

    (first_x, first_y), (second_x, second_y) = matches
    left = min(first_x, second_x)
    top = min(first_y, second_y)
    right = max(first_x, second_x) + template_width
    bottom = max(first_y, second_y) + template_height
    if right <= left or bottom <= top:
        return None
    if right > frame_width or bottom > frame_height:
        return None
    if (right - left) % CELL_PIXEL_SIZE or (bottom - top) % CELL_PIXEL_SIZE:
        return None
    return left, top, right, bottom


__all__ = ["Bounds", "locate_matrix"]
