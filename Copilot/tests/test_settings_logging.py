"""摘要：验证日志设置 schema、文件诊断日志分级和业务事件通道。

描述：在临时目录中覆盖缺失、损坏、部分无效、关闭、相对/绝对路径、轮转参数和日志
级别行为；业务事件通道只收 ``business_log`` 投递的无级别标记文本，文件 handler 按
配置级别写入诊断。测试不修改仓库设置。

主要变量信息：``temporary_dir`` 隔离 settings.json 和日志文件；``messages`` 接收
业务事件通道经 Qt signal 投递的文本与错误标记。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增设置与日志测试；
2026-08-01，根据 audit finding 增加波浪号相对日志路径回归测试。
2026-08-01，根据 GUI Log Business Channel 冻结计划把 GUI handler 断言改为
business_log 业务事件通道断言，logging 仅验证文件诊断输出。
"""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from PySide6.QtWidgets import QApplication

from copilot.logging_setup import business_log, configure_logging
from copilot.settings import DEFAULT_LOGGING_SETTINGS, load_settings, resolve_log_path


class SettingsTests(unittest.TestCase):
    def test_missing_file_uses_defaults_without_warning(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            result = load_settings(Path(temporary_dir))
        self.assertEqual(result.logging, DEFAULT_LOGGING_SETTINGS)
        self.assertEqual(result.warnings, ())

    def test_valid_fields_unknown_fields_and_case_insensitive_level(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            (base / "settings.json").write_text(
                json.dumps(
                    {
                        "logging": {
                            "file_enabled": False,
                            "path": "custom/app.log",
                            "max_bytes": 128,
                            "backup_count": 2,
                            "level": "warning",
                            "unknown": "ignored",
                        }
                    }
                ),
                encoding="utf-8",
            )
            result = load_settings(base)
        self.assertFalse(result.logging.file_enabled)
        self.assertEqual(result.logging.path, "custom/app.log")
        self.assertEqual(result.logging.max_bytes, 128)
        self.assertEqual(result.logging.backup_count, 2)
        self.assertEqual(result.logging.level, "WARNING")
        self.assertEqual(result.warnings, ())

    def test_invalid_fields_fall_back_independently(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            (base / "settings.json").write_text(
                json.dumps(
                    {
                        "logging": {
                            "file_enabled": 1,
                            "path": "valid.log",
                            "max_bytes": True,
                            "backup_count": 0,
                            "level": "verbose",
                        }
                    }
                ),
                encoding="utf-8",
            )
            result = load_settings(base)
        self.assertTrue(result.logging.file_enabled)
        self.assertEqual(result.logging.path, "valid.log")
        self.assertEqual(result.logging.max_bytes, 5 * 1024 * 1024)
        self.assertEqual(result.logging.backup_count, 3)
        self.assertEqual(result.logging.level, "INFO")
        self.assertEqual(len(result.warnings), 4)

    def test_damaged_json_warns_and_uses_defaults(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            (base / "settings.json").write_text("{", encoding="utf-8")
            result = load_settings(base)
        self.assertEqual(result.logging, DEFAULT_LOGGING_SETTINGS)
        self.assertTrue(result.warnings)

    def test_relative_and_absolute_log_paths(self) -> None:
        base = Path("C:/entry")
        self.assertEqual(resolve_log_path(base, "logs/app.log"), base / "logs/app.log")
        absolute = Path("C:/absolute/app.log")
        self.assertEqual(resolve_log_path(base, str(absolute)), absolute)

    def test_tilde_log_path_stays_relative_to_entry_directory(self) -> None:
        base = Path("C:/entry")
        self.assertEqual(
            resolve_log_path(base, "~/copilot.log"),
            base / "~" / "copilot.log",
        )


class LoggingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def test_file_level_and_business_channel_are_independent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            (base / "settings.json").write_text(
                json.dumps({"logging": {"path": "test.log", "level": "ERROR"}}),
                encoding="utf-8",
            )
            settings = load_settings(base).logging
            messages: list[tuple[str, bool]] = []
            runtime = configure_logging(
                settings, base, lambda text, error: messages.append((text, error))
            )
            self.assertIsNotNone(runtime.file_handler)
            assert runtime.file_handler is not None
            self.assertEqual(runtime.file_handler.maxBytes, 5 * 1024 * 1024)
            self.assertEqual(runtime.file_handler.backupCount, 3)
            runtime.logger.debug("debug")
            runtime.logger.info("info")
            runtime.logger.error("error")
            business_log("业务事件")
            business_log("可读错误", error=True)
            self.app.processEvents()
            runtime.close()
            file_text = (base / "test.log").read_text(encoding="utf-8")
        # 业务通道只收 business_log 投递的文本，不收 logger 输出
        texts = [text for text, _error in messages]
        self.assertEqual(len(texts), 2)
        self.assertTrue(texts[0].endswith("业务事件"))
        self.assertTrue(texts[1].endswith("可读错误"))
        self.assertEqual([error for _text, error in messages], [False, True])
        # 文件日志按级别只记录诊断，不包含业务事件
        self.assertIn("error", file_text)
        self.assertNotIn("info", file_text)
        self.assertNotIn("业务事件", file_text)

    def test_business_log_format_and_error_flag(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            settings = DEFAULT_LOGGING_SETTINGS.__class__(file_enabled=False)
            messages: list[tuple[str, bool]] = []
            runtime = configure_logging(
                settings, base, lambda text, error: messages.append((text, error))
            )
            business_log("收到截图启动请求")
            business_log("Matrix 解码失败", error=True)
            self.app.processEvents()
            runtime.close()
        self.assertEqual(len(messages), 2)
        text, error = messages[0]
        self.assertRegex(
            text,
            r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} 收到截图启动请求$",
        )
        self.assertFalse(error)
        text, error = messages[1]
        self.assertTrue(error)
        self.assertNotIn("INFO", text)
        self.assertNotIn("ERROR", text)

    def test_business_log_is_silent_before_configuration(self) -> None:
        # 未配置时业务通道静默丢弃，不抛异常
        import copilot.logging_setup as logging_setup

        logging_setup._business_emitter = None
        business_log("before configuration")
        business_log("before configuration error", error=True)

    def test_disabled_file_logging_creates_no_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            settings = DEFAULT_LOGGING_SETTINGS.__class__(file_enabled=False)
            runtime = configure_logging(settings, base, lambda _text, _error: None)
            business_log("only window")
            runtime.logger.error("diagnostic only")
            self.app.processEvents()
            runtime.close()
            self.assertFalse((base / "logs" / "copilot.log").exists())

    def test_file_initialization_failure_keeps_window_logging(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            occupied_parent = base / "occupied"
            occupied_parent.write_text("not a directory", encoding="utf-8")
            settings = DEFAULT_LOGGING_SETTINGS.__class__(path="occupied/app.log")
            messages: list[str] = []
            runtime = configure_logging(
                settings, base, lambda text, _error: messages.append(text)
            )
            self.app.processEvents()
            self.assertIsNotNone(runtime.file_error)
            self.assertTrue(any("文件日志初始化失败" in item for item in messages))
            runtime.close()


if __name__ == "__main__":
    unittest.main()
