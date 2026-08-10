"""摘要：公开 HTTP 输出包的 handler 与序列化组件。

描述：本包只导出模块级定义，导入不创建 socket、线程、QApplication 或读取任何
共享快照；实际服务由主线程构造 ``HTTPServer`` 并交由 ``WebServerWorker`` 运行。

主要变量信息：无。

修改记录：2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划新增。
2026-08-09，根据审计 finding 导出 SnapshotReaderError。
"""

from .handler import SnapshotHandler, SnapshotReaderError
from .serializer import build_internal_error_fallback, json_default

__all__ = [
    "SnapshotHandler",
    "SnapshotReaderError",
    "build_internal_error_fallback",
    "json_default",
]
