"""摘要：验证所有首版模块导入均无运行时副作用。

描述：在临时目录子进程导入入口、应用、UI、捕获、decoder、worker 和日志模块，确认
没有创建 QApplication 或任何磁盘文件，不运行项目主入口。

主要变量信息：无。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增导入副作用测试。
2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划改为独立进程验证。
2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划加入 copilot.httpd 导入检查。
"""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

class ImportSideEffectTests(unittest.TestCase):
    def test_imports_do_not_create_qapplication(self) -> None:
        source_path = Path(__file__).resolve().parents[1] / "src"
        script = """
import importlib
from pathlib import Path
from PySide6.QtWidgets import QApplication
assert QApplication.instance() is None
for name in [
    'main', 'copilot.application', 'copilot.ui', 'copilot.capture',
    'copilot.decoder', 'copilot.workers', 'copilot.httpd',
    'copilot.logging_setup'
]:
    importlib.import_module(name)
assert QApplication.instance() is None
assert list(Path.cwd().iterdir()) == []
"""
        with tempfile.TemporaryDirectory() as temporary_dir:
            environment = os.environ.copy()
            environment["PYTHONPATH"] = str(source_path)
            environment["QT_QPA_PLATFORM"] = "offscreen"
            completed = subprocess.run(
                [sys.executable, "-c", script],
                cwd=temporary_dir,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
        self.assertEqual(completed.returncode, 0, completed.stderr)


if __name__ == "__main__":
    unittest.main()
