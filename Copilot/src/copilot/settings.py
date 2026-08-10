"""摘要：读取并校验 Copilot 的日志设置。

描述：从启动入口同级 ``settings.json`` 读取嵌套 ``logging`` 对象，对文件开关、路径、
轮转大小、备份数和级别逐字段独立校验。缺失文件直接使用默认值；损坏 JSON、错误对象
或无效字段产生警告，但有效字段继续生效。本模块只读取，不创建、修复或写回设置文件。

主要变量信息：``LoggingSettings`` 保存有效日志配置；``warnings`` 保存可展示的设置警告；
``DEFAULT_LOGGING_SETTINGS`` 是独立字段回退使用的默认值。

修改记录：2026-08-01，根据 Copilot GUI and Capture 冻结计划新增日志设置 schema；
2026-08-01，根据 audit finding 修正含波浪号相对日志路径的入口目录解析。
"""

from __future__ import annotations

from dataclasses import dataclass
import json
import logging
from pathlib import Path
from typing import Any

VALID_LEVELS = {
    "DEBUG": logging.DEBUG,
    "INFO": logging.INFO,
    "WARNING": logging.WARNING,
    "ERROR": logging.ERROR,
    "CRITICAL": logging.CRITICAL,
}


@dataclass(frozen=True, slots=True)
class LoggingSettings:
    file_enabled: bool = True
    path: str = "logs/copilot.log"
    max_bytes: int = 5 * 1024 * 1024
    backup_count: int = 3
    level: str = "INFO"


DEFAULT_LOGGING_SETTINGS = LoggingSettings()


@dataclass(frozen=True, slots=True)
class SettingsLoadResult:
    logging: LoggingSettings
    warnings: tuple[str, ...] = ()


def _is_positive_integer(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def _parse_logging_fields(raw_logging: dict[str, Any]) -> SettingsLoadResult:
    """按字段解析日志对象，保留其他有效字段。"""

    values = {
        "file_enabled": DEFAULT_LOGGING_SETTINGS.file_enabled,
        "path": DEFAULT_LOGGING_SETTINGS.path,
        "max_bytes": DEFAULT_LOGGING_SETTINGS.max_bytes,
        "backup_count": DEFAULT_LOGGING_SETTINGS.backup_count,
        "level": DEFAULT_LOGGING_SETTINGS.level,
    }
    warnings: list[str] = []

    if "file_enabled" in raw_logging:
        value = raw_logging["file_enabled"]
        if isinstance(value, bool):
            values["file_enabled"] = value
        else:
            warnings.append("logging.file_enabled 必须是布尔值，已使用默认值")

    if "path" in raw_logging:
        value = raw_logging["path"]
        if isinstance(value, str) and value.strip():
            values["path"] = value
        else:
            warnings.append("logging.path 必须是非空字符串，已使用默认值")

    for field_name in ("max_bytes", "backup_count"):
        if field_name not in raw_logging:
            continue
        value = raw_logging[field_name]
        if _is_positive_integer(value):
            values[field_name] = value
        else:
            warnings.append(f"logging.{field_name} 必须是正整数，已使用默认值")

    if "level" in raw_logging:
        value = raw_logging["level"]
        normalized_level = value.upper() if isinstance(value, str) else ""
        if normalized_level in VALID_LEVELS:
            values["level"] = normalized_level
        else:
            warnings.append("logging.level 无效，已使用默认值")

    return SettingsLoadResult(LoggingSettings(**values), tuple(warnings))


def load_settings(entry_dir: Path) -> SettingsLoadResult:
    """读取入口目录中的设置文件，缺失时安静地使用默认值。"""

    settings_path = Path(entry_dir) / "settings.json"
    if not settings_path.exists():
        return SettingsLoadResult(DEFAULT_LOGGING_SETTINGS)
    try:
        raw_settings = json.loads(settings_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return SettingsLoadResult(
            DEFAULT_LOGGING_SETTINGS,
            (f"settings.json 无法读取或解析，已使用默认值：{error}",),
        )
    if not isinstance(raw_settings, dict):
        return SettingsLoadResult(
            DEFAULT_LOGGING_SETTINGS,
            ("settings.json 顶层必须是对象，已使用默认值",),
        )
    raw_logging = raw_settings.get("logging", {})
    if not isinstance(raw_logging, dict):
        return SettingsLoadResult(
            DEFAULT_LOGGING_SETTINGS,
            ("logging 必须是对象，已使用默认值",),
        )
    return _parse_logging_fields(raw_logging)


def resolve_log_path(entry_dir: Path, configured_path: str) -> Path:
    """把相对日志路径解析到启动入口目录，保留绝对覆盖路径。"""

    path = Path(configured_path)
    return path if path.is_absolute() else Path(entry_dir) / path


__all__ = [
    "DEFAULT_LOGGING_SETTINGS",
    "LoggingSettings",
    "SettingsLoadResult",
    "VALID_LEVELS",
    "load_settings",
    "resolve_log_path",
]
