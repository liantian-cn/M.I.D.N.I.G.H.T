"""摘要：通过旁路测试对当前 Windows 桌面执行一次真实 GDI 截图。

描述：不运行项目入口，直接枚举第一块物理显示器并捕获完整 RGB 帧，验证尺寸、dtype、
通道数和独立内存所有权。非 Windows 环境跳过；无交互桌面时系统异常作为测试失败保留。

主要变量信息：``monitor`` 是排序后的第一块显示器；``frame`` 是一次真实 owned RGB 帧。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增 Windows 截图冒烟测试。
"""

from __future__ import annotations

import sys
import unittest

import numpy as np

from copilot.capture import capture_monitor, enumerate_monitors


@unittest.skipUnless(sys.platform == "win32", "仅 Windows 支持 GDI 截图")
class WindowsCaptureSmokeTests(unittest.TestCase):
    def test_capture_first_monitor_returns_owned_rgb(self) -> None:
        monitors = enumerate_monitors()
        self.assertTrue(monitors)
        monitor = monitors[0]
        frame = capture_monitor(monitor)
        self.assertEqual(frame.shape, (monitor.height, monitor.width, 3))
        self.assertEqual(frame.dtype, np.uint8)
        self.assertTrue(frame.flags.owndata)


if __name__ == "__main__":
    unittest.main()
