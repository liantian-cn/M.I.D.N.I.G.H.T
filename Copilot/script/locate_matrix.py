"""摘要：在显示器原始 BGRA 帧中定位 Phantom 矩阵边界。

描述：本文件自行把顶部起始 BGRA bytes 转成 RGB NumPy 数组，再用 OpenCV 搜索
Phantom 当前源码定义的 8×8 对角标记。只有模板命中数恰好为两个且围成的宽高均为
4 的倍数时，才返回显示器相对半开 (left, top, right, bottom)；不使用候选面积回退，
也不依赖当前矩阵的 Cell 行列数。直接运行时先捕获指定显示器，再打印定位边界。

主要变量信息：MARKER_TEMPLATE 是来自当前 Phantom 标记实现的动态 8×8 RGB 模板；
MATCH_THRESHOLD 是模板匹配阈值；matches 保存全部超过阈值的模板左上角坐标。

修改记录：2026-07-31，按冻结计划 Screen Capture Validation Scripts 新增矩阵定位
验证脚本，并严格要求两个模板命中。
"""

from __future__ import annotations

import argparse
import sys

import cv2
import numpy as np

if __package__:
    from .capture_monitor import RawBGRAFrame, capture_monitor
else:
    from capture_monitor import RawBGRAFrame, capture_monitor


__all__ = ["locate_matrix"]

MARK_COLOR_DEEP = np.array([15, 25, 20], dtype=np.uint8)
MARK_COLOR_LIGHT = np.array([25, 15, 20], dtype=np.uint8)
MARKER_TEMPLATE = np.array(
    [
        [MARK_COLOR_DEEP] * 4 + [MARK_COLOR_LIGHT] * 4,
        [MARK_COLOR_DEEP] * 4 + [MARK_COLOR_LIGHT] * 4,
        [MARK_COLOR_DEEP] * 4 + [MARK_COLOR_LIGHT] * 4,
        [MARK_COLOR_DEEP] * 4 + [MARK_COLOR_LIGHT] * 4,
        [MARK_COLOR_LIGHT] * 4 + [MARK_COLOR_DEEP] * 4,
        [MARK_COLOR_LIGHT] * 4 + [MARK_COLOR_DEEP] * 4,
        [MARK_COLOR_LIGHT] * 4 + [MARK_COLOR_DEEP] * 4,
        [MARK_COLOR_LIGHT] * 4 + [MARK_COLOR_DEEP] * 4,
    ],
    dtype=np.uint8,
)
MATCH_THRESHOLD = 0.999


def _frame_to_rgb(frame: RawBGRAFrame) -> np.ndarray:
    bgra_array = np.frombuffer(frame.data, dtype=np.uint8).reshape(
        (frame.height, frame.width, 4)
    )
    return bgra_array[:, :, [2, 1, 0]].copy()


def locate_matrix(frame: RawBGRAFrame) -> tuple[int, int, int, int] | None:
    """在原始帧中定位恰好两个标记围成的半开矩阵边界。"""

    rgb_array = _frame_to_rgb(frame)
    template_height, template_width = MARKER_TEMPLATE.shape[:2]
    if template_height > frame.height or template_width > frame.width:
        return None

    match_result = cv2.matchTemplate(
        rgb_array, MARKER_TEMPLATE, cv2.TM_CCOEFF_NORMED
    )
    match_y, match_x = np.where(match_result >= MATCH_THRESHOLD)
    matches = [(int(x), int(y)) for y, x in zip(match_y, match_x)]
    if len(matches) != 2:
        return None

    (first_x, first_y), (second_x, second_y) = matches
    left = min(first_x, second_x)
    top = min(first_y, second_y)
    right = max(first_x + template_width, second_x + template_width)
    bottom = max(first_y + template_height, second_y + template_height)
    if (right - left) % 4 != 0 or (bottom - top) % 4 != 0:
        return None
    return left, top, right, bottom


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="定位指定显示器中的 Phantom 矩阵")
    parser.add_argument("--monitor", type=int, default=0, help="系统枚举显示器编号")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        bounds = locate_matrix(capture_monitor(args.monitor))
        if bounds is None:
            print("矩阵定位失败：模板命中数不是两个或边界无效", file=sys.stderr)
            return 1
        left, top, right, bottom = bounds
        print(f"left={left} top={top} right={right} bottom={bottom}")
        return 0
    except Exception as error:
        print(f"矩阵定位失败: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
