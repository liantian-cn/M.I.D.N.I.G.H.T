"""摘要：按 Win32 系统枚举顺序列出物理像素显示器区域。

描述：调用 EnumDisplayMonitors 收集虚拟桌面中的显示器矩形，在调用期间临时启用
Per-Monitor V2 DPI 感知，确保边界和尺寸均为物理像素。返回结果保持系统回调顺序，
不按空间位置排序，也不调整主显示器编号。直接运行时打印每块显示器的索引、边界、
宽度和高度；导入模块不会枚举显示器。

主要变量信息：MonitorRegion 表示含 left、top、right、bottom、width、height 的显示器
字典；monitors 按 EnumDisplayMonitors 回调顺序保存显示器区域。

修改记录：2026-07-31，按冻结计划 Screen Capture Validation Scripts 新增显示器枚举
验证脚本。
"""

from __future__ import annotations

import argparse
import ctypes
from contextlib import contextmanager
from ctypes import wintypes
import sys
from typing import TypeAlias


__all__ = ["MonitorRegion", "enumerate_monitors"]

MonitorRegion: TypeAlias = dict[str, int]
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = ctypes.c_void_p(-4)


class RECT(ctypes.Structure):
    _fields_ = [
        ("left", wintypes.LONG),
        ("top", wintypes.LONG),
        ("right", wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]


MONITOR_ENUM_PROC = ctypes.WINFUNCTYPE(
    wintypes.BOOL,
    wintypes.HANDLE,
    wintypes.HDC,
    ctypes.POINTER(RECT),
    wintypes.LPARAM,
)


def _load_user32():
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    user32.SetThreadDpiAwarenessContext.argtypes = [wintypes.HANDLE]
    user32.SetThreadDpiAwarenessContext.restype = wintypes.HANDLE
    user32.EnumDisplayMonitors.argtypes = [
        wintypes.HDC,
        ctypes.POINTER(RECT),
        MONITOR_ENUM_PROC,
        wintypes.LPARAM,
    ]
    user32.EnumDisplayMonitors.restype = wintypes.BOOL
    return user32


def _win32_error() -> OSError:
    return ctypes.WinError(ctypes.get_last_error())


@contextmanager
def physical_pixel_context(user32):
    """在当前线程临时关闭 DPI 坐标虚拟化。"""

    previous_context = user32.SetThreadDpiAwarenessContext(
        DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
    )
    if not previous_context:
        raise _win32_error()
    try:
        yield
    finally:
        if not user32.SetThreadDpiAwarenessContext(previous_context):
            raise _win32_error()


def _build_monitor_region(left: int, top: int, right: int, bottom: int) -> MonitorRegion:
    return {
        "left": left,
        "top": top,
        "right": right,
        "bottom": bottom,
        "width": right - left,
        "height": bottom - top,
    }


def enumerate_monitors() -> list[MonitorRegion]:
    """返回保持 Win32 系统枚举顺序的物理像素显示器区域。"""

    user32 = _load_user32()
    monitors: list[MonitorRegion] = []

    def callback(_monitor_handle, _monitor_dc, monitor_rect_ptr, _lparam):
        rect = monitor_rect_ptr.contents
        monitors.append(
            _build_monitor_region(
                int(rect.left), int(rect.top), int(rect.right), int(rect.bottom)
            )
        )
        return True

    callback_reference = MONITOR_ENUM_PROC(callback)
    with physical_pixel_context(user32):
        if not user32.EnumDisplayMonitors(0, None, callback_reference, 0):
            raise _win32_error()
    return monitors


def _build_parser() -> argparse.ArgumentParser:
    return argparse.ArgumentParser(description="按 Win32 系统枚举顺序列出显示器")


def main(argv: list[str] | None = None) -> int:
    _build_parser().parse_args(argv)
    try:
        monitors = enumerate_monitors()
        if not monitors:
            raise RuntimeError("Win32 未枚举到显示器")
        for index, monitor in enumerate(monitors):
            print(
                f"monitor_{index}: left={monitor['left']} top={monitor['top']} "
                f"right={monitor['right']} bottom={monitor['bottom']} "
                f"width={monitor['width']} height={monitor['height']}"
            )
        return 0
    except Exception as error:
        print(f"显示器枚举失败: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
