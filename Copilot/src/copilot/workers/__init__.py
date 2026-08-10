"""摘要：公开 Copilot 的后台 worker。

描述：导出截图定位 ``CaptureWorker``、Matrix 解析 ``DecoderWorker`` 与标准库 HTTP
服务 ``WebServerWorker``；导入包不会创建线程、定时器、数据库连接、socket 或执行
截图和解码。

主要变量信息：无。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增 worker 包。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划导出解码 worker。
2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划导出 WebServerWorker。
"""

from .capture_worker import CaptureWorker
from .decoder_worker import DecoderWorker
from .web_server_worker import WebServerWorker

__all__ = ["CaptureWorker", "DecoderWorker", "WebServerWorker"]
