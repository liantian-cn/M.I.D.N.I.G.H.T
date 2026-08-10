"""验证标题编辑器的五组展示、实时缓存操作和输入保护。"""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

import numpy as np
from PySide6.QtWidgets import QApplication, QLineEdit

from copilot.decoder.title_manager import IconTitleManager
from copilot.ui.title_editor_dialog import TitleEditorDialog


class TitleEditorDialogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.app = QApplication.instance() or QApplication([])

    def test_groups_records_and_preserves_active_miss_input(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            manager = IconTitleManager(Path(temporary_dir) / "database.sqlite")
            original = np.arange(108, dtype=np.uint8).reshape(6, 6, 3)
            manager.add_record(original, "PLAYER_SPELL", "Known Spell")
            similar = original.copy()
            similar[0, 0, 0] = 1
            manager.resolve(similar, "PLAYER_SPELL")
            missed = 255 - original
            manager.resolve(missed, "PLAYER_SPELL")
            manager.cache_other(
                np.full((6, 6, 3), 17, dtype=np.uint8), "BUFF_ON_FRIENDLY"
            )

            dialog = TitleEditorDialog()
            snapshot = {
                "database": manager.list_database_records(),
                "memory": manager.list_memory_records(),
                "threshold": manager.similarity_threshold,
            }
            dialog.apply_records(snapshot)
            self.assertEqual(
                [dialog.tabs.tabText(index) for index in range(dialog.tabs.count())],
                [
                    "玩家技能",
                    "可打断敌方施法",
                    "不可打断敌方施法",
                    "友方减益",
                    "其他",
                    "相似匹配",
                    "未分类",
                ],
            )
            self.assertEqual(dialog.category_tables["玩家技能"].rowCount(), 1)
            self.assertEqual(dialog.other_table.rowCount(), 1)
            source_item = dialog.other_table.item(0, 4)
            self.assertIsNotNone(source_item)
            assert source_item is not None
            self.assertEqual(source_item.text(), "未分类")
            self.assertEqual(dialog.similar_table.rowCount(), 1)
            self.assertEqual(dialog.miss_table.rowCount(), 1)

            editor = dialog.miss_table.cellWidget(0, 4)
            self.assertIsInstance(editor, QLineEdit)
            assert isinstance(editor, QLineEdit)
            dialog.show()
            editor.setFocus()
            editor.setText("Pending title")
            self.app.processEvents()
            dialog.apply_records(snapshot)
            self.assertEqual(editor.text(), "Pending title")
            dialog.close()
            manager.close()

    def test_save_emits_copy_safe_payload(self) -> None:
        dialog = TitleEditorDialog()
        emitted: list[dict] = []
        dialog.record_save_requested.connect(emitted.append)
        array = np.full((6, 6, 3), 21, dtype=np.uint8)
        record = {
            "hash": "hash-value",
            "title_type": "PLAYER_SPELL",
            "title": "hash-value",
            "valid_array": array.tolist(),
            "png_bytes": b"",
            "from_sqlite": False,
            "cache_kind": "miss",
        }
        dialog._save_record(record, "  Saved title  ")
        self.assertEqual(emitted[0]["title"], "Saved title")
        self.assertEqual(emitted[0]["valid_array"], array.tolist())
        dialog.close()


if __name__ == "__main__":
    unittest.main()
