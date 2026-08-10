"""验证图标三级识别、UTF 仅新增持久化与数据库启动恢复分支。"""

from __future__ import annotations

import base64
import io
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import MagicMock, patch

import numpy as np
from PIL import Image

from copilot.decoder.database import (
    DatabaseResetDeclined,
    DatabaseStartupError,
    IncompleteDatabaseCleanupError,
    prepare_icon_database,
)
from copilot.decoder.title_manager import (
    CACHE_MISS,
    CACHE_SIMILAR,
    IconDatabaseError,
    IconTitleManager,
    icon_hash,
)


class IconTitleManagerTests(unittest.TestCase):
    def test_utf_learning_creates_once_and_preserves_existing_title(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            manager = IconTitleManager(Path(temporary_dir) / "database.sqlite")
            array = np.full((6, 6, 3), 77, dtype=np.uint8)
            record_hash = icon_hash(array)

            self.assertTrue(
                manager.add_record_if_absent(
                    array,
                    "PLAYER_SPELL",
                    "自动标题",
                    record_hash,
                )
            )
            self.assertTrue(manager.has_persistent_record(record_hash))
            self.assertFalse(
                manager.add_record_if_absent(
                    array,
                    "PLAYER_SPELL",
                    "不应覆盖",
                    record_hash,
                )
            )
            self.assertEqual(
                manager.resolve(array, "PLAYER_SPELL", record_hash),
                "自动标题",
            )
            self.assertEqual(manager.list_database_records()[0]["title"], "自动标题")
            manager.close()

    def test_utf_learning_database_failure_keeps_memory_unchanged(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            manager = IconTitleManager(Path(temporary_dir) / "database.sqlite")
            array = np.full((6, 6, 3), 78, dtype=np.uint8)
            record_hash = icon_hash(array)
            original_connection = manager.connection
            failing_connection = MagicMock(wraps=original_connection)
            failing_connection.__enter__.return_value = failing_connection
            failing_connection.execute.side_effect = sqlite3.OperationalError("write")
            manager.connection = failing_connection

            with self.assertRaises(sqlite3.OperationalError):
                manager.add_record_if_absent(
                    array,
                    "PLAYER_SPELL",
                    "不应进入缓存",
                    record_hash,
                )

            self.assertFalse(manager.has_persistent_record(record_hash))
            manager.connection = original_connection
            manager.close()

    def test_exact_similarity_category_isolation_and_live_update(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            manager = IconTitleManager(path)
            original = np.full((6, 6, 3), 100, dtype=np.uint8)
            original_hash = manager.add_record(original, "PLAYER_SPELL", "Spell A")
            self.assertEqual(
                manager.resolve(original, "PLAYER_SPELL", original_hash),
                "Spell A",
            )

            similar = original.copy()
            similar[0, 0, 0] = 101
            similar_hash = icon_hash(similar)
            self.assertEqual(
                manager.resolve(similar, "PLAYER_SPELL", similar_hash),
                "Spell A",
            )

            isolated = original.copy()
            isolated[0, 0, 1] = 102
            isolated_hash = icon_hash(isolated)
            self.assertEqual(
                manager.resolve(
                    isolated,
                    "ENEMY_SPELL_INTERRUPTIBLE",
                    isolated_hash,
                ),
                isolated_hash,
            )
            self.assertEqual(
                manager.records_by_hash[isolated_hash].cache_kind,
                CACHE_MISS,
            )
            manager.add_record(
                isolated,
                "ENEMY_SPELL_INTERRUPTIBLE",
                "Enemy Spell",
            )
            self.assertEqual(
                manager.resolve(
                    isolated,
                    "ENEMY_SPELL_INTERRUPTIBLE",
                    isolated_hash,
                ),
                "Enemy Spell",
            )
            manager.close()

    def test_crud_other_cache_and_derived_cache_invalidation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            manager = IconTitleManager(Path(temporary_dir) / "database.sqlite")
            original = np.full((6, 6, 3), 100, dtype=np.uint8)
            record_hash = manager.add_record(original, "PLAYER_SPELL", "Spell A")
            manager.cache_other(original, "UNKNOWN", record_hash)
            manager.cache_other(original, "BUFF_ON_FRIENDLY", record_hash)
            same_hash_records = [
                record
                for record in manager.list_memory_records()
                if record["hash"] == record_hash
            ]
            self.assertEqual(
                {record["title_type"] for record in same_hash_records},
                {"PLAYER_SPELL", "UNKNOWN", "BUFF_ON_FRIENDLY"},
            )
            similar = original.copy()
            similar[0, 0, 0] = 101
            similar_hash = icon_hash(similar)
            self.assertEqual(manager.resolve(similar, "PLAYER_SPELL"), "Spell A")
            self.assertEqual(
                manager.records_by_hash[similar_hash].cache_kind, CACHE_SIMILAR
            )

            other = np.full((6, 6, 3), 17, dtype=np.uint8)
            other_hash = manager.cache_other(other, "BUFF_ON_FRIENDLY")
            self.assertEqual(
                manager.other_records[(other_hash, "BUFF_ON_FRIENDLY")].category,
                "BUFF_ON_FRIENDLY",
            )
            with self.assertRaises(IconDatabaseError):
                manager.add_record(other, "BUFF_ON_FRIENDLY", "Unsupported")

            manager.update_record(record_hash, "Spell B")
            self.assertNotIn(similar_hash, manager.records_by_hash)
            self.assertIn((other_hash, "BUFF_ON_FRIENDLY"), manager.other_records)
            self.assertEqual(
                manager.list_database_records()[0]["title"], "Spell B"
            )
            manager.delete_record(record_hash)
            self.assertEqual(manager.list_database_records(), [])
            manager.close()

    def test_threshold_change_clears_similarity_and_miss_caches(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            manager = IconTitleManager(
                Path(temporary_dir) / "database.sqlite", similarity_threshold=0.98
            )
            original = np.full((6, 6, 3), 100, dtype=np.uint8)
            manager.add_record(original, "PLAYER_SPELL", "Spell")
            similar = original.copy()
            similar[0, 0, 0] = 120
            manager.resolve(similar, "PLAYER_SPELL")
            missed = np.full((6, 6, 3), 240, dtype=np.uint8)
            manager.resolve(missed, "PLAYER_SPELL")
            self.assertGreater(len(manager.records_by_hash), 1)
            manager.set_similarity_threshold(0.999)
            self.assertEqual(manager.similarity_threshold, 0.999)
            self.assertTrue(
                all(record.persistent for record in manager.records_by_hash.values())
            )
            manager.close()

    def test_terminal_json_round_trip_overwrite_and_atomic_rejection(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            manager = IconTitleManager(base / "database.sqlite")
            array = np.full((6, 6, 3), 33, dtype=np.uint8)
            manager.add_record(array, "PLAYER_SPELL", "Original")
            export_path = manager.export_json(base / "titles.json")
            payload = json.loads(export_path.read_text(encoding="utf-8"))
            payload[0]["title"] = "Imported"
            export_path.write_text(json.dumps(payload), encoding="utf-8")
            manager.import_json(export_path)
            self.assertEqual(
                manager.list_database_records()[0]["title"], "Imported"
            )

            payload[0]["title"] = "Must Roll Back"
            unsupported = dict(payload[0])
            unsupported["title_type"] = "MAGIC"
            payload.append(unsupported)
            export_path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaises(IconDatabaseError):
                manager.import_json(export_path)
            self.assertEqual(
                manager.list_database_records()[0]["title"], "Imported"
            )

            malformed = [dict(payload[0])]
            malformed[0]["valid_array"] = np.full(
                (6, 6, 3), 300, dtype=np.int16
            ).tolist()
            export_path.write_text(json.dumps(malformed), encoding="utf-8")
            with self.assertRaises(IconDatabaseError):
                manager.import_json(export_path)

            malformed[0]["valid_array"] = array.tolist()
            malformed[0]["hash"] = icon_hash(array)
            malformed[0]["png_base64"] = base64.b64encode(b"not png").decode(
                "ascii"
            )
            export_path.write_text(json.dumps(malformed), encoding="utf-8")
            with self.assertRaises(IconDatabaseError):
                manager.import_json(export_path)

            png_buffer = io.BytesIO()
            Image.fromarray(
                np.full((6, 6, 3), 255, dtype=np.uint8), mode="RGB"
            ).save(png_buffer, format="PNG")
            malformed[0]["png_base64"] = base64.b64encode(
                png_buffer.getvalue()
            ).decode("ascii")
            export_path.write_text(json.dumps(malformed), encoding="utf-8")
            with self.assertRaises(IconDatabaseError):
                manager.import_json(export_path)
            self.assertEqual(
                manager.list_database_records()[0]["title"], "Imported"
            )
            manager.close()


class DatabasePreparationTests(unittest.TestCase):
    def test_missing_and_healthy_database_need_no_reset(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            prompts: list[str] = []
            self.assertEqual(
                prepare_icon_database(path, lambda reason: prompts.append(reason) or False),
                path,
            )
            self.assertTrue(path.exists())
            self.assertEqual(
                prepare_icon_database(path, lambda reason: prompts.append(reason) or False),
                path,
            )
            self.assertEqual(prompts, [])

    def test_invalid_database_can_be_declined_or_reset_with_backup(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            path = base / "database.sqlite"
            path.write_bytes(b"invalid sqlite")
            with self.assertRaises(DatabaseResetDeclined):
                prepare_icon_database(path, lambda _reason: False)
            self.assertEqual(path.read_bytes(), b"invalid sqlite")

            self.assertEqual(prepare_icon_database(path, lambda _reason: True), path)
            backups = list(base.glob("database.*.backup.sqlite"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_bytes(), b"invalid sqlite")
            prepare_icon_database(path, lambda _reason: False)

    def test_reset_initialization_failure_keeps_backup_and_removes_new_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            base = Path(temporary_dir)
            path = base / "database.sqlite"
            path.write_bytes(b"invalid sqlite")
            with patch(
                "copilot.decoder.database._initialize_database",
                side_effect=OSError("initialize"),
            ), self.assertRaises(DatabaseStartupError):
                prepare_icon_database(path, lambda _reason: True)
            self.assertFalse(path.exists())
            self.assertEqual(len(list(base.glob("database.*.backup.sqlite"))), 1)

    def test_missing_database_creation_failure_removes_partial_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"

            def fail_initialization(target: Path) -> None:
                target.write_bytes(b"partial")
                raise OSError("initialize")

            with patch(
                "copilot.decoder.database._initialize_database",
                side_effect=fail_initialization,
            ), self.assertRaises(DatabaseStartupError):
                prepare_icon_database(path, lambda _reason: False)
            self.assertFalse(path.exists())

    def test_backup_rename_failure_preserves_original(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            path.write_bytes(b"invalid sqlite")
            with patch.object(
                Path,
                "rename",
                side_effect=OSError("rename"),
            ), self.assertRaises(DatabaseStartupError):
                prepare_icon_database(path, lambda _reason: True)
            self.assertEqual(path.read_bytes(), b"invalid sqlite")

    def test_cleanup_failure_reports_actual_residual_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            path = Path(temporary_dir) / "database.sqlite"
            path.write_bytes(b"invalid sqlite")

            def fail_initialization(target: Path) -> None:
                target.write_bytes(b"partial")
                raise OSError("initialize")

            with (
                patch(
                    "copilot.decoder.database._initialize_database",
                    side_effect=fail_initialization,
                ),
                patch.object(Path, "unlink", side_effect=OSError("unlink")),
                self.assertRaises(IncompleteDatabaseCleanupError) as raised,
            ):
                prepare_icon_database(path, lambda _reason: True)
            self.assertEqual(raised.exception.path, path)
            self.assertTrue(path.exists())
            path.unlink()


if __name__ == "__main__":
    unittest.main()
