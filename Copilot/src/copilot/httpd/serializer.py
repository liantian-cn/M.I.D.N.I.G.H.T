"""摘要：提供 HTTP 快照序列化的最小回退对象与 JSON 默认编码。

描述：``build_internal_error_fallback`` 用快照发布时间戳构建只含固定基础类型的
最小 ``internal_error`` 回退 dict 及其 UTF-8 JSON bytes，由快照发布方在锁外与
新快照同时准备；``json_default`` 只把 datetime 转换为契约时间戳格式，其他不可
序列化值不猜测，交由 handler 的请求级回退路径处理。

主要变量信息：无。

修改记录：2026-08-09，根据 Phase 3.0 HTTP Output 冻结计划新增。
"""

from __future__ import annotations

import json
from datetime import datetime


def build_internal_error_fallback(timestamp: str) -> tuple[dict, bytes]:
    """返回固定基础类型的最小错误对象及其 UTF-8 JSON bytes。"""

    fallback = {
        "error": True,
        "error_msg": "internal_error",
        "timestamp": timestamp,
    }
    return fallback, json.dumps(fallback).encode("utf-8")


def json_default(value: object) -> str:
    """把 datetime 编码为 ``YYYY-MM-DD HH:mm:ss.SSS`` 字符串；其他类型不猜测。"""

    if isinstance(value, datetime):
        return value.isoformat(sep=" ", timespec="milliseconds")
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


__all__ = ["build_internal_error_fallback", "json_default"]
