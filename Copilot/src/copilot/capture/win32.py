"""摘要：通过物理像素 Win32/GDI API 枚举显示器并捕获独立 RGB 帧。

描述：在调用线程临时启用 Per-Monitor V2 DPI 感知，按 Win32 物理坐标枚举显示器并按
``(left, top, right, bottom)`` 排序。截图流程验证显示器相对半开区域，建立兼容 DC 与
位图，读取顶部起始 BGRA 像素，再复制为调用方独立拥有的 RGB NumPy 数组；成功和失败
路径均恢复位图并释放 GDI 资源。

主要变量信息：``MonitorRegion`` 表示虚拟桌面物理像素矩形；``region`` 表示显示器内部
相对半开边界；``rgb_frame`` 是脱离 GDI 缓冲区生命周期的 RGB 数组。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划将已验证 script 截图
原语提升为应用实现，并采用 Terminal 的显示器排序。
"""

from __future__ import annotations

import ctypes
from contextlib import contextmanager
from ctypes import wintypes
from dataclasses import dataclass
from typing import Iterator

import numpy as np

SRCCOPY = 0x00CC0020
BI_RGB = 0
HGDI_ERROR = ctypes.c_void_p(-1).value
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = ctypes.c_void_p(-4)


@dataclass(frozen=True, slots=True)
class MonitorRegion:
    """描述虚拟桌面中的物理像素显示器矩形。"""

    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return self.right - self.left

    @property
    def height(self) -> int:
        return self.bottom - self.top


class RECT(ctypes.Structure):
    _fields_ = [
        ("left", wintypes.LONG),
        ("top", wintypes.LONG),
        ("right", wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", wintypes.LONG),
        ("biHeight", wintypes.LONG),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", wintypes.LONG),
        ("biYPelsPerMeter", wintypes.LONG),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]


MONITOR_ENUM_PROC = ctypes.WINFUNCTYPE(
    wintypes.BOOL,
    wintypes.HANDLE,
    wintypes.HDC,
    ctypes.POINTER(RECT),
    wintypes.LPARAM,
)


def _win32_error() -> OSError:
    return ctypes.WinError(ctypes.get_last_error())


def _load_win32_api():
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
    user32.SetThreadDpiAwarenessContext.argtypes = [wintypes.HANDLE]
    user32.SetThreadDpiAwarenessContext.restype = wintypes.HANDLE
    user32.EnumDisplayMonitors.argtypes = [
        wintypes.HDC,
        ctypes.POINTER(RECT),
        MONITOR_ENUM_PROC,
        wintypes.LPARAM,
    ]
    user32.EnumDisplayMonitors.restype = wintypes.BOOL
    user32.GetDC.argtypes = [wintypes.HWND]
    user32.GetDC.restype = wintypes.HDC
    user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
    user32.ReleaseDC.restype = ctypes.c_int
    gdi32.CreateCompatibleDC.argtypes = [wintypes.HDC]
    gdi32.CreateCompatibleDC.restype = wintypes.HDC
    gdi32.CreateCompatibleBitmap.argtypes = [wintypes.HDC, ctypes.c_int, ctypes.c_int]
    gdi32.CreateCompatibleBitmap.restype = wintypes.HBITMAP
    gdi32.SelectObject.argtypes = [wintypes.HDC, wintypes.HGDIOBJ]
    gdi32.SelectObject.restype = wintypes.HGDIOBJ
    gdi32.BitBlt.argtypes = [
        wintypes.HDC,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        wintypes.HDC,
        ctypes.c_int,
        ctypes.c_int,
        wintypes.DWORD,
    ]
    gdi32.BitBlt.restype = wintypes.BOOL
    gdi32.GetDIBits.argtypes = [
        wintypes.HDC,
        wintypes.HBITMAP,
        wintypes.UINT,
        wintypes.UINT,
        ctypes.POINTER(ctypes.c_ubyte),
        ctypes.POINTER(BITMAPINFOHEADER),
        wintypes.UINT,
    ]
    gdi32.GetDIBits.restype = ctypes.c_int
    gdi32.DeleteObject.argtypes = [wintypes.HGDIOBJ]
    gdi32.DeleteObject.restype = wintypes.BOOL
    gdi32.DeleteDC.argtypes = [wintypes.HDC]
    gdi32.DeleteDC.restype = wintypes.BOOL
    return user32, gdi32


@contextmanager
def _physical_pixel_context(user32) -> Iterator[None]:
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


def enumerate_monitors() -> list[MonitorRegion]:
    """返回按物理位置排序的显示器区域。"""

    user32, _ = _load_win32_api()
    monitors: list[MonitorRegion] = []

    def callback(_monitor_handle, _monitor_dc, monitor_rect_ptr, _lparam):
        rect = monitor_rect_ptr.contents
        monitors.append(
            MonitorRegion(
                left=int(rect.left),
                top=int(rect.top),
                right=int(rect.right),
                bottom=int(rect.bottom),
            )
        )
        return True

    callback_reference = MONITOR_ENUM_PROC(callback)
    with _physical_pixel_context(user32):
        if not user32.EnumDisplayMonitors(0, None, callback_reference, 0):
            raise _win32_error()
    return sorted(
        monitors,
        key=lambda monitor: (
            monitor.left,
            monitor.top,
            monitor.right,
            monitor.bottom,
        ),
    )


def _validate_monitor(monitor: MonitorRegion) -> None:
    if monitor.width <= 0 or monitor.height <= 0:
        raise ValueError("显示器区域必须具有正宽度和正高度")


def _absolute_capture_rect(
    monitor: MonitorRegion,
    region: tuple[int, int, int, int] | None,
) -> MonitorRegion:
    _validate_monitor(monitor)
    if region is None:
        return monitor
    left, top, right, bottom = (int(value) for value in region)
    if left < 0 or top < 0:
        raise ValueError("截图相对区域不能使用负坐标")
    if right <= left or bottom <= top:
        raise ValueError("截图相对区域必须具有正宽度和正高度")
    if right > monitor.width or bottom > monitor.height:
        raise ValueError("截图相对区域超出显示器范围")
    return MonitorRegion(
        monitor.left + left,
        monitor.top + top,
        monitor.left + right,
        monitor.top + bottom,
    )


def _read_owned_rgb(gdi32, memory_dc, bitmap, width: int, height: int) -> np.ndarray:
    pixel_buffer = (ctypes.c_ubyte * (width * height * 4))()
    bitmap_info = BITMAPINFOHEADER()
    bitmap_info.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    bitmap_info.biWidth = width
    bitmap_info.biHeight = -height
    bitmap_info.biPlanes = 1
    bitmap_info.biBitCount = 32
    bitmap_info.biCompression = BI_RGB
    scan_lines = gdi32.GetDIBits(
        memory_dc,
        bitmap,
        0,
        height,
        pixel_buffer,
        ctypes.byref(bitmap_info),
        0,
    )
    if scan_lines != height:
        raise _win32_error()
    bgra_frame = np.frombuffer(pixel_buffer, dtype=np.uint8).reshape(height, width, 4)
    return bgra_frame[:, :, [2, 1, 0]].copy()


def _capture(
    monitor: MonitorRegion,
    region: tuple[int, int, int, int] | None,
) -> np.ndarray:
    """执行一次 GDI 截图，并保证位图在读取前解除选择。"""

    capture_rect = _absolute_capture_rect(monitor, region)
    user32, gdi32 = _load_win32_api()
    with _physical_pixel_context(user32):
        screen_dc = user32.GetDC(0)
        if not screen_dc:
            raise _win32_error()
        memory_dc = None
        bitmap = None
        old_bitmap = None
        bitmap_selected = False
        restore_attempted = False
        try:
            memory_dc = gdi32.CreateCompatibleDC(screen_dc)
            if not memory_dc:
                raise _win32_error()
            bitmap = gdi32.CreateCompatibleBitmap(
                screen_dc, capture_rect.width, capture_rect.height
            )
            if not bitmap:
                raise _win32_error()
            old_bitmap = gdi32.SelectObject(memory_dc, bitmap)
            if not old_bitmap or old_bitmap == HGDI_ERROR:
                raise _win32_error()
            bitmap_selected = True
            if not gdi32.BitBlt(
                memory_dc,
                0,
                0,
                capture_rect.width,
                capture_rect.height,
                screen_dc,
                capture_rect.left,
                capture_rect.top,
                SRCCOPY,
            ):
                raise _win32_error()
            restore_attempted = True
            restored_bitmap = gdi32.SelectObject(memory_dc, old_bitmap)
            if not restored_bitmap or restored_bitmap == HGDI_ERROR:
                raise _win32_error()
            bitmap_selected = False
            return _read_owned_rgb(
                gdi32, memory_dc, bitmap, capture_rect.width, capture_rect.height
            )
        finally:
            cleanup_error = None
            if memory_dc and bitmap_selected and not restore_attempted:
                restored_bitmap = gdi32.SelectObject(memory_dc, old_bitmap)
                if not restored_bitmap or restored_bitmap == HGDI_ERROR:
                    cleanup_error = _win32_error()
                else:
                    bitmap_selected = False
            if memory_dc and bitmap_selected:
                if not gdi32.DeleteDC(memory_dc):
                    cleanup_error = cleanup_error or _win32_error()
                else:
                    bitmap_selected = False
                memory_dc = None
            if bitmap and not bitmap_selected and not gdi32.DeleteObject(bitmap):
                cleanup_error = cleanup_error or _win32_error()
            if memory_dc and not gdi32.DeleteDC(memory_dc):
                cleanup_error = cleanup_error or _win32_error()
            if not user32.ReleaseDC(0, screen_dc):
                cleanup_error = cleanup_error or _win32_error()
            if cleanup_error is not None:
                raise cleanup_error


def capture_monitor(monitor: MonitorRegion) -> np.ndarray:
    """捕获完整显示器并返回独立 RGB 帧。"""

    return _capture(monitor, None)


def capture_region(
    monitor: MonitorRegion,
    bounds: tuple[int, int, int, int],
) -> np.ndarray:
    """捕获显示器内部的相对半开区域并返回独立 RGB 帧。"""

    return _capture(monitor, bounds)


__all__ = [
    "MonitorRegion",
    "capture_monitor",
    "capture_region",
    "enumerate_monitors",
]
