"""摘要：管理 IconCell 标题的 SQLite 记录与三级识别缓存。

描述：持久记录使用 icon hash、四类标题类别、标题、中心 6x6 RGB JSON 和 PNG。
解析先查精确 hash，再在同类别持久记录中计算余弦相似度，最后把未知 hash 缓存在内存。
人工新增记录立即覆盖同 hash 的 miss；UTF 自动学习仅创建尚未持久化的 hash，保护人工编辑
或导入的已有标题，并使后续帧无需重启即可获得新标题。

主要变量信息：`records_by_hash` 保存持久、相似命中和 miss；
`persistent_hashes_by_category` 只索引可参与余弦匹配的 SQLite 记录。

修改记录：2026-08-01，根据 Matrix Decoder for Player and Environment 冻结计划新增。
2026-08-01，根据 Phase 2.5 Player Matrix Decoder 冻结计划增加完整标题维护、阈值和
JSON 导入导出。
2026-08-02，根据 Phase 2.12 Matrix Decoder 冻结计划增加 UTF 标题仅新增持久化。
"""

from __future__ import annotations

import base64
import io
import json
from dataclasses import dataclass
from pathlib import Path
import sqlite3
from typing import Any, Final

import numpy as np
from PIL import Image
import xxhash

from .color import ICON_CATEGORIES, OTHER_ICON_TYPES

CACHE_PERSISTENT: Final = "persistent"
CACHE_SIMILAR: Final = "similar_match"
CACHE_MISS: Final = "miss"
SIMILARITY_THRESHOLD: Final = 0.999


class IconDatabaseError(RuntimeError):
    """图标数据库内容或操作不符合当前契约。"""


@dataclass(slots=True)
class IconTitleRecord:
    icon_hash: str
    category: str
    title: str
    valid_array: np.ndarray
    png_bytes: bytes
    persistent: bool
    cache_kind: str


def normalize_icon_array(valid_array: np.ndarray) -> np.ndarray:
    array = np.asarray(valid_array, dtype=np.uint8)
    if array.shape != (6, 6, 3):
        raise IconDatabaseError(f"图标特征必须是 6x6x3，当前是 {array.shape}")
    return np.ascontiguousarray(array.copy())


def icon_hash(valid_array: np.ndarray) -> str:
    return xxhash.xxh3_64_hexdigest(normalize_icon_array(valid_array), seed=0)


def cosine_similarity(first: np.ndarray, second: np.ndarray) -> float:
    first_flat = first.reshape(-1).astype(np.float32)
    second_flat = second.reshape(-1).astype(np.float32)
    first_norm = np.linalg.norm(first_flat)
    second_norm = np.linalg.norm(second_flat)
    if first_norm == 0 or second_norm == 0:
        return 0.0
    return float(np.dot(first_flat, second_flat) / (first_norm * second_norm))


def _normalize_category(category: str) -> str:
    normalized = category.strip().upper()
    if normalized not in ICON_CATEGORIES:
        raise IconDatabaseError(f"不支持的图标类别: {category}")
    return normalized


def _normalize_title(title: str) -> str:
    normalized = str(title).strip()
    if not normalized:
        raise IconDatabaseError("图标标题不能为空")
    return normalized


def _normalize_other_type(title_type: str) -> str:
    normalized = str(title_type).strip().upper()
    if normalized not in OTHER_ICON_TYPES:
        normalized = "UNKNOWN"
    return normalized


def _array_to_json(valid_array: np.ndarray) -> str:
    return json.dumps(valid_array.tolist(), separators=(",", ":"))


def _array_from_json(payload: str) -> np.ndarray:
    try:
        return normalize_icon_array(np.array(json.loads(payload), dtype=np.uint8))
    except Exception as exc:
        raise IconDatabaseError("图标特征 JSON 无效") from exc


def _array_from_import(payload: object) -> np.ndarray:
    array = np.asarray(payload)
    if array.shape != (6, 6, 3) or array.dtype.kind not in {"i", "u"}:
        raise IconDatabaseError("导入图标特征必须是 6x6x3 整数数组")
    if np.any(array < 0) or np.any(array > 255):
        raise IconDatabaseError("导入图标特征像素必须位于 0..255")
    return normalize_icon_array(array)


def _array_to_png(valid_array: np.ndarray) -> bytes:
    buffer = io.BytesIO()
    Image.fromarray(valid_array, mode="RGB").save(buffer, format="PNG")
    return buffer.getvalue()


def _validate_png_bytes(png_bytes: bytes, valid_array: np.ndarray) -> bytes:
    try:
        with Image.open(io.BytesIO(png_bytes)) as image:
            if image.format != "PNG" or image.size != (6, 6):
                raise IconDatabaseError("导入图标预览必须是 6x6 PNG")
            png_array = np.asarray(image.convert("RGB"), dtype=np.uint8)
            if not np.array_equal(png_array, valid_array):
                raise IconDatabaseError("导入图标预览与图标特征不一致")
    except IconDatabaseError:
        raise
    except Exception as exc:
        raise IconDatabaseError("导入图标预览 PNG 无效") from exc
    return png_bytes


class IconTitleManager:
    """拥有单线程 SQLite 连接并解析 IconCell 标题。"""

    def __init__(
        self,
        db_path: str | Path,
        similarity_threshold: float = SIMILARITY_THRESHOLD,
    ) -> None:
        self.db_path = Path(db_path)
        self.similarity_threshold = float(similarity_threshold)
        self.connection = sqlite3.connect(self.db_path)
        self.connection.row_factory = sqlite3.Row
        self.records_by_hash: dict[str, IconTitleRecord] = {}
        self.other_records: dict[tuple[str, str], IconTitleRecord] = {}
        self.persistent_hashes_by_category = {
            category: set() for category in ICON_CATEGORIES
        }
        self._closed = False
        try:
            self._create_schema()
            self.reload()
        except Exception:
            self.connection.close()
            self._closed = True
            raise

    def _create_schema(self) -> None:
        self.connection.execute(
            """
            CREATE TABLE IF NOT EXISTS icon_titles (
                hash TEXT PRIMARY KEY,
                title_type TEXT NOT NULL,
                title TEXT NOT NULL,
                valid_array_json TEXT NOT NULL,
                png_bytes BLOB NOT NULL
            )
            """
        )
        self.connection.commit()

    def close(self) -> None:
        if self._closed:
            return
        self.connection.close()
        self._closed = True

    def reload(self) -> None:
        self.records_by_hash.clear()
        self.persistent_hashes_by_category = {
            category: set() for category in ICON_CATEGORIES
        }
        rows = self.connection.execute(
            "SELECT hash, title_type, title, valid_array_json, png_bytes "
            "FROM icon_titles ORDER BY hash"
        ).fetchall()
        for row in rows:
            array = _array_from_json(row["valid_array_json"])
            computed_hash = icon_hash(array)
            if computed_hash != row["hash"]:
                raise IconDatabaseError("数据库图标 hash 与像素特征不一致")
            record = IconTitleRecord(
                icon_hash=computed_hash,
                category=_normalize_category(row["title_type"]),
                title=str(row["title"]),
                valid_array=array,
                png_bytes=bytes(row["png_bytes"]),
                persistent=True,
                cache_kind=CACHE_PERSISTENT,
            )
            self._store_memory(record)

    def _store_memory(self, record: IconTitleRecord) -> None:
        previous = self.records_by_hash.get(record.icon_hash)
        if previous is not None and previous.persistent:
            self.persistent_hashes_by_category[previous.category].discard(
                previous.icon_hash
            )
        self.records_by_hash[record.icon_hash] = record
        if record.persistent:
            self.persistent_hashes_by_category[record.category].add(record.icon_hash)

    @staticmethod
    def _record_to_dict(record: IconTitleRecord) -> dict[str, Any]:
        return {
            "hash": record.icon_hash,
            "title_type": record.category,
            "title": record.title,
            "valid_array": record.valid_array.tolist(),
            "png_bytes": record.png_bytes,
            "from_sqlite": record.persistent,
            "cache_kind": record.cache_kind,
        }

    def list_database_records(self) -> list[dict[str, Any]]:
        records = (record for record in self.records_by_hash.values() if record.persistent)
        return [
            self._record_to_dict(record)
            for record in sorted(records, key=lambda item: item.icon_hash)
        ]

    def list_memory_records(self) -> list[dict[str, Any]]:
        records = list(self.records_by_hash.values()) + list(
            self.other_records.values()
        )
        return [
            self._record_to_dict(record)
            for record in sorted(
                records, key=lambda item: (item.icon_hash, item.category)
            )
        ]

    def has_persistent_record(self, record_hash: str) -> bool:
        record = self.records_by_hash.get(str(record_hash))
        return bool(record is not None and record.persistent)

    def add_record_if_absent(
        self,
        valid_array: np.ndarray,
        category: str,
        title: str,
        expected_hash: str | None = None,
    ) -> bool:
        """新增 UTF 学到的正式记录，已有 hash 保持不变。"""

        array = normalize_icon_array(valid_array)
        normalized_category = _normalize_category(category)
        computed_hash = icon_hash(array)
        if expected_hash is not None and expected_hash != computed_hash:
            raise IconDatabaseError("传入的 hash 与图标特征不一致")
        if self.has_persistent_record(computed_hash):
            return False

        record = IconTitleRecord(
            icon_hash=computed_hash,
            category=normalized_category,
            title=_normalize_title(title),
            valid_array=array,
            png_bytes=_array_to_png(array),
            persistent=True,
            cache_kind=CACHE_PERSISTENT,
        )
        with self.connection:
            cursor = self.connection.execute(
                """
                INSERT INTO icon_titles(
                    hash, title_type, title, valid_array_json, png_bytes
                ) VALUES(?, ?, ?, ?, ?)
                ON CONFLICT(hash) DO NOTHING
                """,
                (
                    record.icon_hash,
                    record.category,
                    record.title,
                    _array_to_json(record.valid_array),
                    sqlite3.Binary(record.png_bytes),
                ),
            )
            inserted = cursor.rowcount == 1
        if not inserted:
            return False
        self._clear_derived_records()
        self._store_memory(record)
        return True

    def _clear_derived_records(self) -> None:
        persistent_records = [
            record for record in self.records_by_hash.values() if record.persistent
        ]
        self.records_by_hash.clear()
        self.persistent_hashes_by_category = {
            category: set() for category in ICON_CATEGORIES
        }
        for record in persistent_records:
            self._store_memory(record)

    def set_similarity_threshold(self, threshold: float) -> None:
        value = float(threshold)
        if not 0.0 <= value < 1.0:
            raise IconDatabaseError("相似度阈值必须大于等于 0 且小于 1")
        self.similarity_threshold = value
        self._clear_derived_records()

    def add_record(
        self,
        valid_array: np.ndarray,
        category: str,
        title: str,
        expected_hash: str | None = None,
    ) -> str:
        array = normalize_icon_array(valid_array)
        normalized_category = _normalize_category(category)
        computed_hash = icon_hash(array)
        if expected_hash is not None and expected_hash != computed_hash:
            raise IconDatabaseError("传入的 hash 与图标特征不一致")
        record = IconTitleRecord(
            icon_hash=computed_hash,
            category=normalized_category,
            title=_normalize_title(title),
            valid_array=array,
            png_bytes=_array_to_png(array),
            persistent=True,
            cache_kind=CACHE_PERSISTENT,
        )
        self.connection.execute(
            """
            INSERT INTO icon_titles(hash, title_type, title, valid_array_json, png_bytes)
            VALUES(?, ?, ?, ?, ?)
            ON CONFLICT(hash) DO UPDATE SET
                title_type=excluded.title_type,
                title=excluded.title,
                valid_array_json=excluded.valid_array_json,
                png_bytes=excluded.png_bytes
            """,
            (
                record.icon_hash,
                record.category,
                record.title,
                _array_to_json(record.valid_array),
                sqlite3.Binary(record.png_bytes),
            ),
        )
        self.connection.commit()
        self.reload()
        return computed_hash

    def update_record(self, record_hash: str, title: str) -> None:
        cursor = self.connection.execute(
            "UPDATE icon_titles SET title = ? WHERE hash = ?",
            (_normalize_title(title), str(record_hash)),
        )
        if cursor.rowcount != 1:
            self.connection.rollback()
            raise IconDatabaseError(f"找不到标题记录: {record_hash}")
        self.connection.commit()
        self.reload()

    def delete_record(self, record_hash: str) -> None:
        cursor = self.connection.execute(
            "DELETE FROM icon_titles WHERE hash = ?", (str(record_hash),)
        )
        if cursor.rowcount != 1:
            self.connection.rollback()
            raise IconDatabaseError(f"找不到标题记录: {record_hash}")
        self.connection.commit()
        self.reload()

    def cache_other(
        self,
        valid_array: np.ndarray,
        title_type: str,
        expected_hash: str | None = None,
    ) -> str:
        """缓存不可持久化的 Other 图标并返回其 hash。"""

        array = normalize_icon_array(valid_array)
        computed_hash = icon_hash(array)
        if expected_hash is not None and expected_hash != computed_hash:
            raise IconDatabaseError("IconCell hash 与中心像素不一致")
        normalized_type = _normalize_other_type(title_type)
        self.other_records[(computed_hash, normalized_type)] = IconTitleRecord(
            icon_hash=computed_hash,
            category=normalized_type,
            title=computed_hash,
            valid_array=array,
            png_bytes=_array_to_png(array),
            persistent=False,
            cache_kind=CACHE_MISS,
        )
        return computed_hash

    def export_json(self, output_path: str | Path) -> Path:
        payload = []
        for record in self.list_database_records():
            payload.append(
                {
                    "hash": record["hash"],
                    "title_type": record["title_type"],
                    "title": record["title"],
                    "valid_array": record["valid_array"],
                    "png_base64": base64.b64encode(record["png_bytes"]).decode(
                        "ascii"
                    ),
                }
            )
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return path

    def import_json(self, input_path: str | Path) -> None:
        """完整验证 Terminal 格式后，以单事务覆盖同 hash 记录。"""

        try:
            payload = json.loads(Path(input_path).read_text(encoding="utf-8"))
            if not isinstance(payload, list):
                raise IconDatabaseError("标题库 JSON 顶层必须是数组")
            records: list[IconTitleRecord] = []
            for item in payload:
                if not isinstance(item, dict):
                    raise IconDatabaseError("标题库记录必须是对象")
                if not isinstance(item.get("hash"), str):
                    raise IconDatabaseError("标题库记录 hash 必须是字符串")
                if not isinstance(item.get("title_type"), str):
                    raise IconDatabaseError("标题库记录分类必须是字符串")
                if not isinstance(item.get("title"), str):
                    raise IconDatabaseError("标题库记录标题必须是字符串")
                array = _array_from_import(item.get("valid_array"))
                category = _normalize_category(item["title_type"])
                computed_hash = icon_hash(array)
                if item["hash"] != computed_hash:
                    raise IconDatabaseError("标题库记录 hash 与图标特征不一致")
                png_payload = item.get("png_base64")
                if png_payload is None:
                    png_bytes = _array_to_png(array)
                elif isinstance(png_payload, str):
                    png_bytes = _validate_png_bytes(
                        base64.b64decode(png_payload.encode("ascii"), validate=True),
                        array,
                    )
                else:
                    raise IconDatabaseError("标题库 PNG 必须是 base64 字符串")
                records.append(
                    IconTitleRecord(
                        icon_hash=computed_hash,
                        category=category,
                        title=_normalize_title(item["title"]),
                        valid_array=array,
                        png_bytes=png_bytes,
                        persistent=True,
                        cache_kind=CACHE_PERSISTENT,
                    )
                )
        except IconDatabaseError:
            raise
        except Exception as exc:
            raise IconDatabaseError(f"导入标题 JSON 失败: {exc}") from exc

        try:
            with self.connection:
                for record in records:
                    self.connection.execute(
                        """
                        INSERT INTO icon_titles(
                            hash, title_type, title, valid_array_json, png_bytes
                        ) VALUES(?, ?, ?, ?, ?)
                        ON CONFLICT(hash) DO UPDATE SET
                            title_type=excluded.title_type,
                            title=excluded.title,
                            valid_array_json=excluded.valid_array_json,
                            png_bytes=excluded.png_bytes
                        """,
                        (
                            record.icon_hash,
                            record.category,
                            record.title,
                            _array_to_json(record.valid_array),
                            sqlite3.Binary(record.png_bytes),
                        ),
                    )
        except Exception as exc:
            raise IconDatabaseError(f"导入标题 JSON 失败: {exc}") from exc
        self.reload()

    def resolve(
        self,
        valid_array: np.ndarray,
        category: str,
        expected_hash: str | None = None,
    ) -> str:
        array = normalize_icon_array(valid_array)
        normalized_category = _normalize_category(category)
        computed_hash = icon_hash(array)
        if expected_hash is not None and expected_hash != computed_hash:
            raise IconDatabaseError("IconCell hash 与中心像素不一致")

        exact = self.records_by_hash.get(computed_hash)
        if exact is not None:
            return exact.title

        best_record: IconTitleRecord | None = None
        best_score = -1.0
        for candidate_hash in self.persistent_hashes_by_category[normalized_category]:
            candidate = self.records_by_hash[candidate_hash]
            score = cosine_similarity(array, candidate.valid_array)
            if score > best_score:
                best_record = candidate
                best_score = score
        if best_record is not None and best_score > self.similarity_threshold:
            matched = IconTitleRecord(
                icon_hash=computed_hash,
                category=normalized_category,
                title=best_record.title,
                valid_array=array,
                png_bytes=_array_to_png(array),
                persistent=False,
                cache_kind=CACHE_SIMILAR,
            )
            self._store_memory(matched)
            return matched.title

        missed = IconTitleRecord(
            icon_hash=computed_hash,
            category=normalized_category,
            title=computed_hash,
            valid_array=array,
            png_bytes=_array_to_png(array),
            persistent=False,
            cache_kind=CACHE_MISS,
        )
        self._store_memory(missed)
        return computed_hash


__all__ = [
    "CACHE_MISS",
    "CACHE_PERSISTENT",
    "CACHE_SIMILAR",
    "IconDatabaseError",
    "IconTitleManager",
    "IconTitleRecord",
    "SIMILARITY_THRESHOLD",
    "cosine_similarity",
    "icon_hash",
    "normalize_icon_array",
]
