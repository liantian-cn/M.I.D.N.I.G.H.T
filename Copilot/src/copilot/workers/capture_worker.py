"""摘要：在独立 QThread 事件循环中调度矩阵区域连续截图。

描述：启动后先捕获选中显示器全帧并严格定位两个标记，再立即捕获第一张固定矩阵区域
帧，最后用 PreciseTimer 按当前 FPS 连续捕获。整屏、定位或区域截图任一失败都会停止
会话并发射失败，不自动重试；停止、FPS 更新和 shutdown 通过 worker 所在线程的 Qt
事件循环执行，shutdown 会先停止活动会话并确认，再请求所属线程退出。

主要变量信息：``_monitor`` 是当前物理显示器；``_bounds`` 是显示器相对半开矩阵区域；
``_is_running`` 门控定时截图；``_fps`` 决定精确定时器间隔。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增截图 worker；
2026-08-01，根据 audit finding 增加 worker 线程内的有序 shutdown。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划增加稳定错误码分流。
2026-08-01，根据 GUI Log Business Channel 冻结计划把业务事件改为 business_log 通道，
异常诊断仍走 logger 仅进入文件日志。
"""

from __future__ import annotations

import logging

from PySide6.QtCore import QObject, QTimer, Qt, Signal, Slot

from ..capture import (
    MonitorRegion,
    capture_monitor,
    capture_region,
    locate_matrix,
)
from ..logging_setup import business_log


class CaptureWorker(QObject):
    """按 Terminal 的 QTimer 调度结构执行严格定位和固定区域截图。"""

    capture_started = Signal(object)
    frame_ready = Signal(object)
    capture_failed = Signal(str, str)
    capture_stopped = Signal()
    shutdown_ready = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._logger = logging.getLogger("copilot")
        self._is_running = False
        self._fps = 30
        self._monitor: MonitorRegion | None = None
        self._bounds: tuple[int, int, int, int] | None = None
        self._timer = QTimer(self)
        self._timer.setSingleShot(False)
        self._timer.setTimerType(Qt.TimerType.PreciseTimer)
        self._timer.timeout.connect(self._capture_current_region)
        self._update_timer_interval()

    @property
    def is_running(self) -> bool:
        return self._is_running

    @Slot(int)
    def set_fps(self, value: int) -> None:
        """限制 FPS 到界面契约范围并立即更新活动定时器。"""

        self._fps = min(40, max(1, int(value)))
        self._update_timer_interval()

    @Slot(object, int)
    def start_capture(self, monitor: MonitorRegion, fps: int) -> None:
        """先定位并取得第一张区域帧，成功后进入连续截图。"""

        if self._is_running:
            business_log("截图 worker 已在运行，忽略重复启动请求")
            return
        self._monitor = monitor
        self._bounds = None
        self._is_running = True
        self.set_fps(fps)
        business_log("截图 worker 开始整屏定位")

        try:
            full_frame = capture_monitor(monitor)
        except Exception:
            self._logger.exception("整屏截图失败")
            self._fail_and_reset("capture_failed", "整屏截图失败，截图已停止")
            return

        try:
            bounds = locate_matrix(full_frame)
        except Exception:
            self._logger.exception("矩阵定位处理失败")
            self._fail_and_reset("matrix_not_found", "矩阵定位失败，截图已停止")
            return
        if bounds is None:
            business_log("矩阵定位失败：标记数量不是恰好两个或边界无效", error=True)
            self._fail_and_reset(
                "matrix_not_found",
                "未找到恰好两个有效定位标记，截图已停止",
            )
            return

        self._bounds = bounds
        business_log(
            "矩阵定位成功："
            f"left={bounds[0]} top={bounds[1]} right={bounds[2]} bottom={bounds[3]}"
        )
        self.capture_started.emit(bounds)
        self._capture_current_region()
        if self._is_running:
            self._timer.start()

    @Slot()
    def stop_capture(self) -> None:
        """停止定时器并清理本次会话状态。"""

        was_running = self._is_running or self._timer.isActive()
        self._timer.stop()
        self._is_running = False
        self._monitor = None
        self._bounds = None
        if was_running:
            business_log("截图 worker 已停止")
            self.capture_stopped.emit()

    @Slot()
    def shutdown(self) -> None:
        """在 worker 线程内先停止活动会话，再通知线程事件循环退出。"""

        self.stop_capture()
        self.shutdown_ready.emit()

    def _update_timer_interval(self) -> None:
        self._timer.setInterval(max(1, round(1000 / self._fps)))

    @Slot()
    def _capture_current_region(self) -> None:
        """捕获已锁定区域；失败时终止整个会话。"""

        if not self._is_running:
            return
        if self._monitor is None or self._bounds is None:
            business_log("截图 worker 缺少已定位区域", error=True)
            self._fail_and_reset("capture_failed", "截图区域未准备好，截图已停止")
            return
        try:
            frame = capture_region(self._monitor, self._bounds)
        except Exception:
            self._logger.exception("矩阵区域截图失败")
            self._fail_and_reset("capture_failed", "矩阵区域截图失败，截图已停止")
            return
        self.frame_ready.emit(frame)

    def _fail_and_reset(self, error_code: str, reason: str) -> None:
        self._timer.stop()
        self._is_running = False
        self._monitor = None
        self._bounds = None
        self.capture_failed.emit(error_code, reason)


__all__ = ["CaptureWorker"]
