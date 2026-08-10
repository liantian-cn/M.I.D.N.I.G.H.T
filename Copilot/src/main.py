"""摘要：提供 Copilot 桌面应用的无导入副作用入口包装。

描述：仅在显式调用 main 时导入应用工厂并启动 Qt 事件循环；导入本文件不会创建
QApplication、窗口、线程、设置文件、日志文件、截图或网络资源。

主要变量信息：无。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划替换项目占位入口。
"""

from __future__ import annotations


def main() -> int:
    """创建应用并进入 Qt 事件循环。"""

    from copilot.application import run_application

    return run_application()


if __name__ == "__main__":
    raise SystemExit(main())
