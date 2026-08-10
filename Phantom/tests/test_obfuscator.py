import json
from pathlib import Path
import re
import subprocess
import sys

import pytest

from obfuscator import main


def write_settings(path: Path, *, enabled: bool, level: str = "INFO", log_path: str = "build.log") -> None:
    path.write_text(
        json.dumps(
            {
                "logging": {
                    "enabled": enabled,
                    "level": level,
                    "path": log_path,
                }
            }
        ),
        encoding="utf-8",
    )


def write_required_release_resources(
    source: Path,
    *,
    include_toc: bool = True,
    include_media: bool = True,
) -> None:
    source.mkdir(parents=True, exist_ok=True)
    if include_toc:
        (source / "Phantom.toc").write_text("## Interface: 120100\n", encoding="utf-8")
    if include_media:
        (source / "media" / "nested").mkdir(parents=True)
        (source / "media" / "icon.tga").write_bytes(b"root-media")
        (source / "media" / "nested" / "sound.ogg").write_bytes(b"nested-media")


def test_discovery_is_sorted_and_excludes_only_root_libs(tmp_path: Path) -> None:
    source = tmp_path / "src"
    (source / "nested" / "libs").mkdir(parents=True)
    (source / "libs").mkdir()
    (source / "LiBs" / "nested").mkdir(parents=True)
    (source / "z.LUA").write_text("return 3", encoding="utf-8")
    (source / "nested" / "a.lua").write_text("return 1", encoding="utf-8")
    (source / "nested" / "libs" / "kept.lua").write_text("return 2", encoding="utf-8")
    (source / "libs" / "excluded.lua").write_text("return 4", encoding="utf-8")
    (source / "LiBs" / "nested" / "excluded.lua").write_text("return 5", encoding="utf-8")
    (source / "asset.txt").write_text("not Lua", encoding="utf-8")

    assert main.discover_lua_files(source) == [
        Path("nested/a.lua"),
        Path("nested/libs/kept.lua"),
        Path("z.LUA"),
    ]


def test_successful_build_preserves_paths_and_replaces_stale_output(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    settings = tmp_path / "settings.json"
    write_required_release_resources(source)
    (source / "nested").mkdir()
    (source / "libs").mkdir()
    (source / "bak").mkdir()
    (source / "demo").mkdir()
    output.mkdir()
    (source / "root.lua").write_text('-- 中文\nprint("root")', encoding="utf-8")
    (source / "nested" / "child.lua").write_text("return 2", encoding="utf-8")
    (source / "libs" / "library.lua").write_text("return 3", encoding="utf-8")
    (source / "bak" / "backup.lua").write_text("return 4", encoding="utf-8")
    (source / "demo" / "example.lua").write_text("return 5", encoding="utf-8")
    (source / "media" / "nested" / "runtime.lua").write_text("return 'media source'", encoding="utf-8")
    (source / "image.tga").write_text("asset", encoding="utf-8")
    (output / "stale.lua").write_text("stale", encoding="utf-8")
    write_settings(settings, enabled=False, log_path="disabled.log")

    def deterministic_converter(lua_text: str, _logger: object) -> str:
        return "-- converted\n" + lua_text

    built = main.build_obfuscated_lua(source, output, settings, deterministic_converter)

    assert built == [
        Path("bak/backup.lua"),
        Path("demo/example.lua"),
        Path("media/nested/runtime.lua"),
        Path("nested/child.lua"),
        Path("root.lua"),
    ]
    assert (output / "root.lua").read_text(encoding="utf-8") == '-- converted\n-- 中文\nprint("root")'
    assert (output / "nested" / "child.lua").read_text(encoding="utf-8") == "-- converted\nreturn 2"
    assert (output / "Phantom.toc").read_text(encoding="utf-8") == "## Interface: 120100\n"
    assert (output / "media" / "icon.tga").read_bytes() == b"root-media"
    assert (output / "media" / "nested" / "sound.ogg").read_bytes() == b"nested-media"
    assert (output / "media" / "nested" / "runtime.lua").read_text(encoding="utf-8") == "return 'media source'"
    assert not (output / "bak").exists()
    assert not (output / "demo").exists()
    assert not (output / "stale.lua").exists()
    assert not (output / "libs").exists()
    assert not (output / "image.tga").exists()
    assert not (tmp_path / "disabled.log").exists()
    assert not (tmp_path / "dist.staging").exists()
    assert not (tmp_path / "dist.backup").exists()


@pytest.mark.parametrize("missing_resource", ["Phantom.toc", "media"])
def test_missing_required_release_resource_preserves_output(
    tmp_path: Path,
    missing_resource: str,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    settings = tmp_path / "settings.json"
    write_required_release_resources(
        source,
        include_toc=missing_resource != "Phantom.toc",
        include_media=missing_resource != "media",
    )
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)

    with pytest.raises(main.BuildError, match="Failed to prepare release resources"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: text)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not (output / "input.lua").exists()
    assert not (tmp_path / "dist.staging").exists()
    assert not (tmp_path / "dist.backup").exists()


@pytest.mark.parametrize("failure_stage", ["copy", "cleanup"])
def test_release_preparation_failure_preserves_output(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    failure_stage: str,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    settings = tmp_path / "settings.json"
    write_required_release_resources(source)
    (source / "bak").mkdir()
    (source / "bak" / "removed.lua").write_text("return false", encoding="utf-8")
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)

    if failure_stage == "copy":
        def fail_release_copy(_source: Path, _destination: Path) -> None:
            raise OSError("injected release copy failure")

        monkeypatch.setattr(main.shutil, "copy2", fail_release_copy)
    else:
        original_remove_path = main._remove_path

        def fail_staged_cleanup(path: Path) -> None:
            if path == staging / "bak":
                raise OSError("injected staged cleanup failure")
            original_remove_path(path)

        monkeypatch.setattr(main, "_remove_path", fail_staged_cleanup)

    with pytest.raises(main.BuildError, match="Failed to prepare release resources"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: text)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not (output / "input.lua").exists()
    assert not staging.exists()
    assert not (tmp_path / "dist.backup").exists()


def test_failed_build_logs_file_cleans_staging_and_preserves_output(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    settings = tmp_path / "settings.json"
    source.mkdir()
    output.mkdir()
    (source / "bad.lua").write_bytes(b"\xff\xfe")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=True, level="INFO", log_path="logs/build.log")

    with pytest.raises(main.BuildError, match="bad[.]lua"):
        main.build_obfuscated_lua(source, output, settings)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert {path.relative_to(output) for path in output.rglob("*") if path.is_file()} == {
        Path("previous.lua")
    }
    assert not (tmp_path / "dist.staging").exists()
    assert not (tmp_path / "dist.backup").exists()
    log_text = (tmp_path / "logs" / "build.log").read_text(encoding="utf-8")
    assert "bad.lua" in log_text
    assert "before new output was installed" in log_text


def test_default_logging_configuration_is_enabled_and_resolved_from_settings() -> None:
    settings = main.load_logging_settings()

    assert settings.enabled is True
    assert settings.level == "INFO"
    assert settings.path == main.DEFAULT_SETTINGS_PATH.parent / "logs" / "build.log"


def test_public_converter_always_requests_level_2_and_runs_real_smoke(monkeypatch: pytest.MonkeyPatch) -> None:
    requested_levels: list[int] = []
    original_get_by_level = main.stringencoder.get_by_level

    def recording_get_by_level(level: int):
        requested_levels.append(level)
        return original_get_by_level(level)

    monkeypatch.setattr(main.stringencoder, "get_by_level", recording_get_by_level)

    converted = main.convert_lua('print("hello")')

    assert requested_levels == [2]
    assert "hello" not in converted
    assert "(_,16)" in converted
    assert converted.startswith("local")


def test_source_equal_to_staging_is_rejected_before_deletion_or_logging(tmp_path: Path) -> None:
    output = tmp_path / "dist"
    source = tmp_path / "dist.staging"
    settings = tmp_path / "settings.json"
    source.mkdir()
    sentinel = source / "must-remain.lua"
    sentinel.write_text("return true", encoding="utf-8")
    write_settings(settings, enabled=True, log_path="build.log")

    with pytest.raises(main.BuildError, match="source=.*staging="):
        main.build_obfuscated_lua(source, output, settings)

    assert sentinel.read_text(encoding="utf-8") == "return true"
    assert not output.exists()
    assert not (tmp_path / "build.log").exists()


def test_source_nested_in_backup_is_rejected_before_recovery(tmp_path: Path) -> None:
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    source = backup / "nested-source"
    settings = tmp_path / "settings.json"
    source.mkdir(parents=True)
    sentinel = source / "must-remain.lua"
    sentinel.write_text("return true", encoding="utf-8")
    write_settings(settings, enabled=True, log_path="build.log")

    with pytest.raises(main.BuildError, match="source=.*backup="):
        main.build_obfuscated_lua(source, output, settings)

    assert sentinel.read_text(encoding="utf-8") == "return true"
    assert backup.exists()
    assert not output.exists()
    assert not (tmp_path / "build.log").exists()


def test_log_inside_output_is_rejected_before_log_creation(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    settings = tmp_path / "settings.json"
    source.mkdir()
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    sentinel = output / "must-remain.lua"
    sentinel.write_text("old", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(output / "build.log"))

    with pytest.raises(main.BuildError, match="log=.*output=|output=.*log="):
        main.build_obfuscated_lua(source, output, settings)

    assert sentinel.read_text(encoding="utf-8") == "old"
    assert not (output / "build.log").exists()


def test_settings_inside_staging_is_read_then_rejected_without_cleanup(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    settings = staging / "settings.json"
    source.mkdir()
    staging.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    write_settings(settings, enabled=True, log_path="build.log")

    with pytest.raises(main.BuildError, match="settings=.*staging="):
        main.build_obfuscated_lua(source, output, settings)

    assert settings.exists()
    assert not output.exists()
    assert not (staging / "build.log").exists()


def test_resolved_path_alias_is_rejected_without_filesystem_links(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    settings = tmp_path / "settings.json"
    source.mkdir()
    sentinel = source / "must-remain.lua"
    sentinel.write_text("return true", encoding="utf-8")
    write_settings(settings, enabled=True, log_path="build.log")
    canonical_source = source.resolve()
    canonical_staging = staging.resolve()
    original_resolve = Path.resolve

    def resolve_with_controlled_alias(path: Path, strict: bool = False) -> Path:
        resolved = original_resolve(path, strict=strict)
        if resolved == canonical_staging:
            return canonical_source
        return resolved

    monkeypatch.setattr(Path, "resolve", resolve_with_controlled_alias)

    with pytest.raises(main.BuildError, match="source=.*staging="):
        main.build_obfuscated_lua(source, output, settings)

    assert sentinel.read_text(encoding="utf-8") == "return true"
    assert not output.exists()
    assert not (tmp_path / "build.log").exists()


def test_initial_output_move_failure_leaves_old_output_unmoved(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_replace = Path.replace

    def fail_initial_move(path: Path, target: Path):
        if path == output and Path(target) == backup:
            raise OSError("injected initial move failure")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", fail_initial_move)

    with pytest.raises(main.InstallationError, match="Failed to move previous output"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: text)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not backup.exists()
    assert not (tmp_path / "dist.staging").exists()
    log_text = log_path.read_text(encoding="utf-8")
    assert f"previous output was never moved and remains unchanged at {output}" in log_text
    assert "was restored" not in log_text


def test_initial_output_move_late_error_continues_with_observed_backup(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)
    original_replace = Path.replace

    def move_then_raise(path: Path, target: Path):
        if path == output and Path(target) == backup:
            original_replace(path, target)
            raise OSError("injected late initial move error")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", move_then_raise)

    built = main.build_obfuscated_lua(source, output, settings, lambda text, _logger: "new output")

    assert built == [Path("input.lua")]
    assert (output / "input.lua").read_text(encoding="utf-8") == "new output"
    assert not (output / "previous.lua").exists()
    assert not backup.exists()


def test_first_build_install_late_error_recognizes_completed_output(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    write_required_release_resources(source)
    (source / "input.lua").write_text("new source", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_replace = Path.replace

    def install_then_raise(path: Path, target: Path):
        if path == staging and Path(target) == output:
            original_replace(path, target)
            raise OSError("injected late staging install error")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", install_then_raise)

    built = main.build_obfuscated_lua(source, output, settings, lambda text, _logger: "new output")

    assert built == [Path("input.lua")]
    assert (output / "input.lua").read_text(encoding="utf-8") == "new output"
    assert not staging.exists()
    log_text = log_path.read_text(encoding="utf-8")
    assert "Installed 1 obfuscated Lua files" in log_text
    assert "not installed" not in log_text


def test_install_failure_restores_previous_output(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    settings = tmp_path / "settings.json"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)
    original_replace = Path.replace

    def fail_staging_install(path: Path, target: Path):
        if path == staging and Path(target) == output:
            raise OSError("injected install rename failure")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", fail_staging_install)

    with pytest.raises(main.InstallationError, match="prior output was restored"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: text)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not staging.exists()
    assert not (tmp_path / "dist.backup").exists()


def test_rollback_late_error_recognizes_restored_old_output(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_replace = Path.replace

    def fail_install_then_restore_and_raise(path: Path, target: Path):
        if path == staging and Path(target) == output:
            raise OSError("injected install failure")
        if path == backup and Path(target) == output:
            original_replace(path, target)
            raise OSError("injected late rollback error")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", fail_install_then_restore_and_raise)

    with pytest.raises(main.InstallationError, match="reported an error after restoring output"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: "new output")

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not staging.exists()
    assert not backup.exists()
    log_text = log_path.read_text(encoding="utf-8")
    assert f"previous output was restored at {output}" in log_text
    assert "backup remains" not in log_text


def test_rollback_failure_preserves_and_reports_backup(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("return true", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_replace = Path.replace

    def fail_install_and_rollback(path: Path, target: Path):
        if (path == staging or path == backup) and Path(target) == output:
            raise OSError(f"injected rename failure for {path.name}")
        return original_replace(path, target)

    monkeypatch.setattr(Path, "replace", fail_install_and_rollback)

    with pytest.raises(main.InstallationError, match=re.escape(f"Previous output backup remains at {backup}")):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: text)

    assert not output.exists()
    assert not staging.exists()
    assert (backup / "previous.lua").read_text(encoding="utf-8") == "previous"
    log_text = log_path.read_text(encoding="utf-8")
    assert f"Previous output backup remains at {backup}" in log_text
    assert "previous output was preserved" not in log_text


def test_partial_backup_cleanup_failure_preserves_new_output_and_blocks_next_build(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    staging = tmp_path / "dist.staging"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    write_required_release_resources(source)
    output.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (output / "old-a.lua").write_text("old a", encoding="utf-8")
    (output / "old-b.lua").write_text("old b", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_remove_path = main._remove_path

    def partially_delete_backup_then_fail(path: Path) -> None:
        if path == backup:
            (path / "old-a.lua").unlink()
            raise OSError("injected partial backup cleanup failure")
        original_remove_path(path)

    monkeypatch.setattr(main, "_remove_path", partially_delete_backup_then_fail)

    with pytest.raises(main.InstallationError, match="failed to clean backup"):
        main.build_obfuscated_lua(source, output, settings, lambda text, _logger: "new output")

    assert (output / "input.lua").read_text(encoding="utf-8") == "new output"
    assert not (output / "old-a.lua").exists()
    assert (backup / "old-b.lua").read_text(encoding="utf-8") == "old b"
    first_output = (output / "input.lua").read_bytes()
    first_backup = (backup / "old-b.lua").read_bytes()
    first_log = log_path.read_text(encoding="utf-8")
    assert f"new output remains installed at {output}" in first_log
    assert f"remaining backup data is preserved at {backup}" in first_log
    assert "was restored" not in first_log

    staging.mkdir()
    staging_sentinel = staging / "must-remain.lua"
    staging_sentinel.write_text("stale staging", encoding="utf-8")
    converter_called = False

    def converter_must_not_run(lua_text: str, _logger: object) -> str:
        nonlocal converter_called
        converter_called = True
        return lua_text

    with pytest.raises(main.InstallationError, match="Ambiguous install state"):
        main.build_obfuscated_lua(source, output, settings, converter_must_not_run)

    assert converter_called is False
    assert (output / "input.lua").read_bytes() == first_output
    assert (backup / "old-b.lua").read_bytes() == first_backup
    assert staging_sentinel.read_text(encoding="utf-8") == "stale staging"


def test_backup_only_interrupted_recovery_restores_before_conversion_failure(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    source.mkdir()
    backup.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (backup / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)

    def fail_after_recovery(_text: str, _logger: object) -> str:
        raise main.ConversionError("stop after recovery")

    with pytest.raises(main.BuildError, match="stop after recovery"):
        main.build_obfuscated_lua(source, output, settings, fail_after_recovery)

    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not backup.exists()
    assert not (tmp_path / "dist.staging").exists()


def test_backup_only_recovery_late_error_recognizes_completed_rename(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    source.mkdir()
    backup.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (backup / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)
    original_replace = Path.replace
    converter_observed_recovery = False

    def recover_then_raise(path: Path, target: Path):
        if path == backup and Path(target) == output:
            original_replace(path, target)
            raise OSError("injected late recovery error")
        return original_replace(path, target)

    def fail_after_observing_recovery(_text: str, _logger: object) -> str:
        nonlocal converter_observed_recovery
        converter_observed_recovery = True
        assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
        assert not backup.exists()
        raise main.ConversionError("stop after observing late recovery")

    monkeypatch.setattr(Path, "replace", recover_then_raise)

    with pytest.raises(main.BuildError, match="stop after observing late recovery"):
        main.build_obfuscated_lua(source, output, settings, fail_after_observing_recovery)

    assert converter_observed_recovery is True
    assert not backup.exists()
    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not (tmp_path / "dist.staging").exists()


def test_backup_only_recovery_failure_reports_observed_state(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    backup = tmp_path / "dist.backup"
    settings = tmp_path / "settings.json"
    log_path = tmp_path / "logs" / "build.log"
    source.mkdir()
    backup.mkdir()
    (source / "input.lua").write_text("new source", encoding="utf-8")
    (backup / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=True, log_path=str(log_path))
    original_replace = Path.replace
    converter_called = False

    def fail_recovery(path: Path, target: Path):
        if path == backup and Path(target) == output:
            raise OSError("injected recovery failure")
        return original_replace(path, target)

    def converter_must_not_run(text: str, _logger: object) -> str:
        nonlocal converter_called
        converter_called = True
        return text

    monkeypatch.setattr(Path, "replace", fail_recovery)

    with pytest.raises(main.InstallationError, match="Failed to restore interrupted-build backup"):
        main.build_obfuscated_lua(source, output, settings, converter_must_not_run)

    assert converter_called is False
    assert not output.exists()
    assert (backup / "previous.lua").read_text(encoding="utf-8") == "previous"
    log_text = log_path.read_text(encoding="utf-8")
    assert f"output is absent; backup remains at {backup}" in log_text


def test_second_conversion_failure_cleans_partial_staging_and_preserves_output(tmp_path: Path) -> None:
    source = tmp_path / "src"
    output = tmp_path / "dist"
    settings = tmp_path / "settings.json"
    source.mkdir()
    output.mkdir()
    (source / "a.lua").write_text("return 1", encoding="utf-8")
    (source / "b.lua").write_text("return 2", encoding="utf-8")
    (output / "previous.lua").write_text("previous", encoding="utf-8")
    write_settings(settings, enabled=False)
    calls = 0

    def fail_second_conversion(lua_text: str, _logger: object) -> str:
        nonlocal calls
        calls += 1
        if calls == 2:
            raise main.ConversionError("injected second conversion failure")
        return lua_text

    with pytest.raises(main.BuildError, match="b[.]lua"):
        main.build_obfuscated_lua(source, output, settings, fail_second_conversion)

    assert calls == 2
    assert (output / "previous.lua").read_text(encoding="utf-8") == "previous"
    assert not (tmp_path / "dist.staging").exists()
    assert not (tmp_path / "dist.backup").exists()


def test_consecutive_real_conversions_reset_upstream_state() -> None:
    source = 'local value = "hello"\nprint(value)'

    main.upstream_obfuscator.random.seed(1729)
    first = main.convert_lua(source)
    main.upstream_obfuscator.random.seed(1729)
    second = main.convert_lua(source)

    assert first == second


def test_direct_file_import_is_isolated_and_uses_local_package(tmp_path: Path) -> None:
    module_path = Path(main.__file__).resolve()
    project_root = module_path.parents[1]
    probe = """
import importlib.util
from pathlib import Path
import sys

module_path = Path(sys.argv[1]).resolve()
project_root = Path(sys.argv[2]).resolve()
assert str(project_root) not in sys.path
assert "obfuscator" not in sys.modules
spec = importlib.util.spec_from_file_location("isolated_direct_import", module_path)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
loaded_package = Path(sys.modules["obfuscator"].__file__).resolve()
assert loaded_package == project_root / "obfuscator" / "__init__.py"
assert callable(module.build_obfuscated_lua)
print("isolated-direct-import-ok")
"""

    completed = subprocess.run(
        [sys.executable, "-I", "-c", probe, str(module_path), str(project_root)],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        check=False,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "isolated-direct-import-ok"
