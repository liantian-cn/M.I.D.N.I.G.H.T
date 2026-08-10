"""摘要：捕获指定显示器中的矩阵相对区域并返回原始 BGRA 帧。

描述：接收 Win32 系统枚举显示器编号和显示器相对半开 LTRB 坐标，复用整屏捕获模块
的显示器选择、边界验证和 GDI 生命周期实现，返回独立 RawBGRAFrame。直接运行时要求
四个边界参数，将区域保存为 PNG，默认覆盖 script/matrix_region_<index>.png，并打印
实际捕获宽高。

主要变量信息：monitor_index 是系统枚举编号；left、top、right、bottom 是显示器相对
物理像素坐标；frame 是调用方独立拥有的区域 BGRA 数据。

修改记录：2026-07-31，按冻结计划 Screen Capture Validation Scripts 新增矩阵区域
捕获验证脚本。
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

if __package__:
    from .capture_monitor import (
        RawBGRAFrame,
        _capture_bgra,
        _select_monitor,
        save_frame_png,
    )
else:
    from capture_monitor import (
        RawBGRAFrame,
        _capture_bgra,
        _select_monitor,
        save_frame_png,
    )


__all__ = ["capture_matrix_region"]


def capture_matrix_region(
    monitor_index: int,
    left: int,
    top: int,
    right: int,
    bottom: int,
) -> RawBGRAFrame:
    """捕获显示器相对半开 LTRB 区域。"""

    monitor = _select_monitor(int(monitor_index))
    region = {
        "left": int(left),
        "top": int(top),
        "right": int(right),
        "bottom": int(bottom),
    }
    return _capture_bgra(monitor, region)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="捕获指定显示器的矩阵区域")
    parser.add_argument("--monitor", type=int, default=0, help="系统枚举显示器编号")
    parser.add_argument("--left", type=int, required=True)
    parser.add_argument("--top", type=int, required=True)
    parser.add_argument("--right", type=int, required=True)
    parser.add_argument("--bottom", type=int, required=True)
    parser.add_argument("--output", type=Path, help="PNG 输出路径")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    output_path = (
        args.output
        or Path(__file__).resolve().parent / f"matrix_region_{args.monitor}.png"
    )
    try:
        frame = capture_matrix_region(
            args.monitor, args.left, args.top, args.right, args.bottom
        )
        save_frame_png(frame, output_path)
        print(f"saved={output_path} width={frame.width} height={frame.height}")
        return 0
    except Exception as error:
        print(f"矩阵区域捕获失败: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
