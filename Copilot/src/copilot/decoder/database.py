"""摘要：在 worker 启动前验证并恢复部署目录图标数据库。

描述：缺失数据库直接初始化；现有数据库只读检查 SQLite 完整性、精确表结构和每条图标
记录。无效数据库由 GUI 回调决定是否重置；同意后先重命名时间戳备份，再初始化新库。
初始化失败时删除本次不完整文件，备份始终保留时间戳名称。

主要变量信息：`EXPECTED_COLUMNS` 是当前 icon_titles schema；`confirm_reset` 把唯一用户
决定留给 GUI；返回路径供 DecoderWorker 在自己的线程中重新打开。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import datetime
import json
from pathlib import Path
import sqlite3

import numpy as np

from .color import ICON_CATEGORIES
from .title_manager import IconDatabaseError, IconTitleManager, icon_hash, normalize_icon_array

EXPECTED_COLUMNS = (
    "hash",
    "title_type",
    "title",
    "valid_array_json",
    "png_bytes",
)


class DatabaseStartupError(RuntimeError):
    """数据库启动检查无法安全完成。"""


class DatabaseResetDeclined(DatabaseStartupError):
    """用户拒绝重置现有数据库。"""


class IncompleteDatabaseCleanupError(DatabaseStartupError):
    """新数据库初始化失败后仍有不完整文件残留。"""

    def __init__(self, path: Path) -> None:
        self.path = path
        super().__init__(f"不完整数据库清理失败: {path}")


def _initialize_database(path: Path) -> None:
    manager = IconTitleManager(path)
    manager.close()


def _validate_existing_database(path: Path) -> None:
    uri = f"{path.resolve().as_uri()}?mode=ro"
    connection = sqlite3.connect(uri, uri=True)
    connection.row_factory = sqlite3.Row
    try:
        quick_check = connection.execute("PRAGMA quick_check").fetchone()
        if quick_check is None or quick_check[0] != "ok":
            raise IconDatabaseError("SQLite quick_check 未通过")
        columns = connection.execute("PRAGMA table_info(icon_titles)").fetchall()
        if tuple(row[1] for row in columns) != EXPECTED_COLUMNS:
            raise IconDatabaseError("icon_titles 表结构不匹配")
        rows = connection.execute(
            "SELECT hash, title_type, title, valid_array_json, png_bytes FROM icon_titles"
        ).fetchall()
        for row in rows:
            array = normalize_icon_array(
                np.array(json.loads(row["valid_array_json"]), dtype=np.uint8)
            )
            if icon_hash(array) != row["hash"]:
                raise IconDatabaseError("图标 hash 与特征不一致")
            if row["title_type"] not in ICON_CATEGORIES:
                raise IconDatabaseError("图标类别无效")
            if not isinstance(row["title"], str) or not isinstance(
                row["png_bytes"], bytes
            ):
                raise IconDatabaseError("图标标题或 PNG 数据无效")
    finally:
        connection.close()


def _remove_incomplete(path: Path) -> None:
    if not path.exists():
        return
    try:
        path.unlink()
    except OSError as exc:
        raise IncompleteDatabaseCleanupError(path) from exc


def prepare_icon_database(
    path: str | Path,
    confirm_reset: Callable[[str], bool],
) -> Path:
    """准备可由 DecoderWorker 打开的数据库，失败时不做路径降级。"""

    database_path = Path(path)
    if not database_path.exists():
        try:
            _initialize_database(database_path)
        except Exception as exc:
            try:
                _remove_incomplete(database_path)
            except DatabaseStartupError as cleanup_error:
                raise cleanup_error from exc
            raise DatabaseStartupError("图标数据库创建失败") from exc
        return database_path

    try:
        _validate_existing_database(database_path)
        return database_path
    except Exception as validation_error:
        if not confirm_reset(str(validation_error)):
            raise DatabaseResetDeclined("用户拒绝重置图标数据库") from validation_error

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup_path = database_path.with_name(
        f"{database_path.stem}.{timestamp}.backup{database_path.suffix}"
    )
    try:
        database_path.rename(backup_path)
    except OSError as exc:
        raise DatabaseStartupError("图标数据库备份失败") from exc

    try:
        _initialize_database(database_path)
    except Exception as exc:
        try:
            _remove_incomplete(database_path)
        except DatabaseStartupError as cleanup_error:
            raise cleanup_error from exc
        raise DatabaseStartupError("备份成功，但新图标数据库初始化失败") from exc
    return database_path


__all__ = [
    "DatabaseResetDeclined",
    "DatabaseStartupError",
    "IncompleteDatabaseCleanupError",
    "prepare_icon_database",
]
