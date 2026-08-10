"""摘要：通过 Win32/GDI 捕获指定显示器并保存原始 BGRA 帧。

描述：按系统枚举编号选择显示器，在物理像素 DPI 作用域中建立兼容 DC 和位图，使用
BitBlt 捕获整屏或经验证的显示器相对半开区域。读取像素前恢复原位图，并在成功和失败
路径释放全部 GDI 资源。公开的 capture_monitor 返回独立拥有 bytes 的 RawBGRAFrame；
直接运行时将整屏保存为 PNG，默认覆盖 script/monitor_<index>.png。

主要变量信息：RawBGRAFrame 保存 width、height 和顶部起始的 BGRA bytes；capture_rect
是虚拟桌面绝对物理像素区域；monitor_index 是 EnumDisplayMonitors 的系统顺序编号。

修改记录：2026-07-31，按冻结计划 Screen Capture Validation Scripts 新增整屏捕获
验证脚本，并采用当前 gist 的 DPI 物理像素与 GDI 清理逻辑。
"""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Mapping

from PIL import Image

if __package__:
    from .list_monitors import MonitorRegion, enumerate_monitors, physical_pixel_context
else:
    from list_monitors import MonitorRegion, enumerate_monitors, physical_pixel_context


__all__ = ["RawBGRAFrame", "capture_monitor", "save_frame_png"]

SRCCOPY = 0x00CC0020
BI_RGB = 0
HGDI_ERROR = ctypes.c_void_p(-1).value


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


@dataclass(frozen=True)
class RawBGRAFrame:
    """保存已脱离 GDI 生命周期、按顶部起始排列的 BGRA 帧。"""

    width: int
    height: int
    data: bytes

    def __post_init__(self) -> None:
        if self.width <= 0 or self.height <= 0:
            raise ValueError("原始帧的 width 和 height 必须为正数")
        owned_data = bytes(self.data)
        if len(owned_data) != self.width * self.height * 4:
            raise ValueError("原始 BGRA 缓冲区长度与帧尺寸不一致")
        object.__setattr__(self, "data", owned_data)


def _load_win32_api():
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
    user32.GetDC.argtypes = [wintypes.HWND]
    user32.GetDC.restype = wintypes.HDC
    user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
    user32.ReleaseDC.restype = ctypes.c_int
    user32.SetThreadDpiAwarenessContext.argtypes = [wintypes.HANDLE]
    user32.SetThreadDpiAwarenessContext.restype = wintypes.HANDLE
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


def _win32_error() -> OSError:
    return ctypes.WinError(ctypes.get_last_error())


def _select_monitor(monitor_index: int) -> MonitorRegion:
    monitors = enumerate_monitors()
    if monitor_index < 0 or monitor_index >= len(monitors):
        raise ValueError(
            f"显示器编号 {monitor_index} 无效，可用范围为 0..{len(monitors) - 1}"
        )
    return monitors[monitor_index]


def _build_capture_rect(
    monitor: MonitorRegion,
    region: Mapping[str, int] | None = None,
) -> MonitorRegion:
    if region is None:
        return dict(monitor)

    left = int(region["left"])
    top = int(region["top"])
    right = int(region["right"])
    bottom = int(region["bottom"])
    if left < 0 or top < 0:
        raise ValueError("相对区域不能使用负坐标")
    if right <= left or bottom <= top:
        raise ValueError("相对区域的 right/bottom 必须大于 left/top")
    if right > monitor["width"] or bottom > monitor["height"]:
        raise ValueError("相对区域超出了显示器范围")
    return {
        "left": monitor["left"] + left,
        "top": monitor["top"] + top,
        "right": monitor["left"] + right,
        "bottom": monitor["top"] + bottom,
        "width": right - left,
        "height": bottom - top,
    }


def _read_bgra(gdi32, memory_dc, bitmap, width: int, height: int) -> RawBGRAFrame:
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
    return RawBGRAFrame(width=width, height=height, data=bytes(pixel_buffer))


def _capture_bgra(
    monitor: MonitorRegion,
    region: Mapping[str, int] | None = None,
) -> RawBGRAFrame:
    """捕获显示器或其相对区域，并在读取前解除位图选择。"""

    capture_rect = _build_capture_rect(monitor, region)
    width = capture_rect["width"]
    height = capture_rect["height"]
    user32, gdi32 = _load_win32_api()
    with physical_pixel_context(user32):
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
            bitmap = gdi32.CreateCompatibleBitmap(screen_dc, width, height)
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
                width,
                height,
                screen_dc,
                capture_rect["left"],
                capture_rect["top"],
                SRCCOPY,
            ):
                raise _win32_error()

            # GetDIBits 要求目标位图未被 DC 选中。
            restore_attempted = True
            restored_bitmap = gdi32.SelectObject(memory_dc, old_bitmap)
            if not restored_bitmap or restored_bitmap == HGDI_ERROR:
                raise _win32_error()
            bitmap_selected = False
            return _read_bgra(gdi32, memory_dc, bitmap, width, height)
        finally:
            cleanup_error = None
            if memory_dc and bitmap_selected and not restore_attempted:
                restore_attempted = True
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
            if bitmap and not bitmap_selected:
                gdi32.DeleteObject(bitmap)
            if memory_dc:
                gdi32.DeleteDC(memory_dc)
            user32.ReleaseDC(0, screen_dc)
            if cleanup_error is not None:
                raise cleanup_error


def capture_monitor(monitor_index: int = 0) -> RawBGRAFrame:
    """按系统枚举编号捕获整块显示器。"""

    return _capture_bgra(_select_monitor(int(monitor_index)))


def save_frame_png(frame: RawBGRAFrame, output_path: Path) -> None:
    """把 BGRA 帧保存为 PNG。"""

    image = Image.frombytes(
        "RGB", (frame.width, frame.height), frame.data, "raw", "BGRX"
    )
    image.save(output_path)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="捕获指定显示器并保存 PNG")
    parser.add_argument("--monitor", type=int, default=0, help="系统枚举显示器编号")
    parser.add_argument("--output", type=Path, help="PNG 输出路径")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    output_path = args.output or Path(__file__).resolve().parent / f"monitor_{args.monitor}.png"
    try:
        frame = capture_monitor(args.monitor)
        save_frame_png(frame, output_path)
        print(f"saved={output_path} width={frame.width} height={frame.height}")
        return 0
    except Exception as error:
        print(f"显示器捕获失败: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
