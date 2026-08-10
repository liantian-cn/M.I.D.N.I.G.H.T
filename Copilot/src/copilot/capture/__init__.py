"""摘要：公开 Copilot 的 Windows 捕获与矩阵定位原语。

描述：集中导出显示器枚举、RGB 截图、区域校验和严格双标记定位接口；导入包时不访问
Win32 API，也不执行实际截图。

主要变量信息：无。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增捕获包。
"""

from .locator import locate_matrix
from .win32 import MonitorRegion, capture_monitor, capture_region, enumerate_monitors

__all__ = [
    "MonitorRegion",
    "capture_monitor",
    "capture_region",
    "enumerate_monitors",
    "locate_matrix",
]
