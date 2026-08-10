"""摘要：把矩阵区域原始 BGRA 帧转换为独立 RGB NumPy 数组。

描述：公开 matrix_to_rgb_array 接收 RawBGRAFrame，将 BGRA 通道重排为形状
(height, width, 3)、dtype 为 uint8 的独立 RGB 数组，不做垂直翻转。直接运行时先调用
capture_matrix_region 捕获指定显示器相对半开区域，再依次打印宽、高、数组形状、类型，
以及左上、左下、右上、右下四个 RGB 值。

主要变量信息：bgra_array 是共享原始 bytes 的临时四通道视图；rgb_array 是独立拥有
内存的三通道结果；四个 corner 值按计划要求的固定顺序输出。

修改记录：2026-07-31，按冻结计划 Screen Capture Validation Scripts 新增矩阵区域
BGRA 到 RGB 转换验证脚本。
"""

from __future__ import annotations

import argparse
import sys

import numpy as np

if __package__:
    from .capture_matrix_region import capture_matrix_region
    from .capture_monitor import RawBGRAFrame
else:
    from capture_matrix_region import capture_matrix_region
    from capture_monitor import RawBGRAFrame


__all__ = ["matrix_to_rgb_array"]


def matrix_to_rgb_array(frame: RawBGRAFrame) -> np.ndarray:
    """将顶部起始 BGRA 帧转换成独立 RGB uint8 数组。"""

    bgra_array = np.frombuffer(frame.data, dtype=np.uint8).reshape(
        (frame.height, frame.width, 4)
    )
    return bgra_array[:, :, [2, 1, 0]].copy()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="捕获矩阵区域并转换为 RGB 数组")
    parser.add_argument("--monitor", type=int, default=0, help="系统枚举显示器编号")
    parser.add_argument("--left", type=int, required=True)
    parser.add_argument("--top", type=int, required=True)
    parser.add_argument("--right", type=int, required=True)
    parser.add_argument("--bottom", type=int, required=True)
    return parser


def _format_rgb(pixel: np.ndarray) -> str:
    return str(tuple(int(channel) for channel in pixel))


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        frame = capture_matrix_region(
            args.monitor, args.left, args.top, args.right, args.bottom
        )
        rgb_array = matrix_to_rgb_array(frame)
        print(f"width={frame.width}")
        print(f"height={frame.height}")
        print(f"shape={rgb_array.shape}")
        print(f"dtype={rgb_array.dtype}")
        print(f"top-left={_format_rgb(rgb_array[0, 0])}")
        print(f"bottom-left={_format_rgb(rgb_array[-1, 0])}")
        print(f"top-right={_format_rgb(rgb_array[0, -1])}")
        print(f"bottom-right={_format_rgb(rgb_array[-1, -1])}")
        return 0
    except Exception as error:
        print(f"RGB 数组转换失败: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
