"""Build Lua files with ``python -m obfuscator.main`` or direct invocation."""

from __future__ import annotations

import argparse
import contextlib
import io
import json
import logging
from dataclasses import dataclass
from pathlib import Path
import shutil
import sys
from typing import Callable, Sequence

if __package__ in (None, ""):
    project_root = str(Path(__file__).resolve().parents[1])
    if project_root not in sys.path:
        sys.path.insert(0, project_root)

from obfuscator.lua_obfuscator import obfuscator as upstream_obfuscator
from obfuscator.lua_obfuscator import stringencoder
from obfuscator.lua_obfuscator import stringstripper


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_DIR = PROJECT_ROOT / "src"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "dist"
DEFAULT_SETTINGS_PATH = Path(__file__).with_name("settings.json")
GLOBALS_PATH = Path(__file__).with_name("lua_obfuscator") / "globals.json"
OBFUSCATION_LEVEL = 2
LOGGER_NAME = "phantom.obfuscator"


class BuildError(RuntimeError):
    """Base exception for an obfuscation build failure."""


class ConfigurationError(BuildError):
    """Raised when the settings file is missing or invalid."""


class DiscoveryError(BuildError):
    """Raised when Lua inputs cannot be discovered safely."""


class ConversionError(BuildError):
    """Raised when the vendored converter cannot transform an input."""


class InstallationError(BuildError):
    """Raised when staged output cannot be installed or rolled back safely."""

    def __init__(self, message: str, *, state_summary: str, cleanup_staging: bool = True) -> None:
        super().__init__(message)
        self.state_summary = state_summary
        self.cleanup_staging = cleanup_staging


@dataclass(frozen=True)
class LoggingSettings:
    enabled: bool
    level: str
    path: Path


def load_logging_settings(settings_path: Path = DEFAULT_SETTINGS_PATH) -> LoggingSettings:
    """Load and validate logging configuration from a UTF-8 JSON file."""
    settings_path = Path(settings_path)
    try:
        document = json.loads(settings_path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ConfigurationError(f"Settings file does not exist: {settings_path}") from exc
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ConfigurationError(f"Cannot read settings file {settings_path}: {exc}") from exc

    logging_document = document.get("logging") if isinstance(document, dict) else None
    if not isinstance(logging_document, dict):
        raise ConfigurationError(f"Settings file {settings_path} must contain a logging object")

    enabled = logging_document.get("enabled")
    level = logging_document.get("level")
    configured_path = logging_document.get("path")
    if not isinstance(enabled, bool):
        raise ConfigurationError("logging.enabled must be a boolean")
    if not isinstance(level, str) or not isinstance(getattr(logging, level.upper(), None), int):
        raise ConfigurationError("logging.level must be a valid logging level name")
    if not isinstance(configured_path, str) or not configured_path.strip():
        raise ConfigurationError("logging.path must be a non-empty string")

    log_path = Path(configured_path)
    if not log_path.is_absolute():
        log_path = settings_path.parent / log_path
    return LoggingSettings(enabled=enabled, level=level.upper(), path=log_path)


def configure_logging(settings: LoggingSettings) -> logging.Logger:
    """Configure and return the build's private logger."""
    logger = logging.getLogger(LOGGER_NAME)
    logger.propagate = False
    for handler in list(logger.handlers):
        logger.removeHandler(handler)
        handler.close()

    logger.disabled = not settings.enabled
    if settings.enabled:
        try:
            settings.path.parent.mkdir(parents=True, exist_ok=True)
            handler = logging.FileHandler(settings.path, encoding="utf-8")
        except OSError as exc:
            raise ConfigurationError(f"Cannot open log file {settings.path}: {exc}") from exc
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
        logger.addHandler(handler)
        logger.setLevel(getattr(logging, settings.level))
    return logger


def discover_lua_files(source_dir: Path) -> list[Path]:
    """Return deterministic source-relative Lua paths, excluding root ``libs``."""
    source_dir = Path(source_dir)
    if not source_dir.is_dir():
        raise DiscoveryError(f"Source directory does not exist or is not a directory: {source_dir}")

    discovered: list[Path] = []
    try:
        candidates = source_dir.rglob("*")
        for candidate in candidates:
            if candidate.is_symlink() or not candidate.is_file() or candidate.suffix.casefold() != ".lua":
                continue
            relative_path = candidate.relative_to(source_dir)
            if relative_path.parts and relative_path.parts[0].casefold() == "libs":
                continue
            discovered.append(relative_path)
    except OSError as exc:
        raise DiscoveryError(f"Cannot discover Lua files under {source_dir}: {exc}") from exc

    return sorted(discovered, key=lambda path: (path.as_posix().casefold(), path.as_posix()))


def _load_upstream_globals() -> list[str]:
    try:
        document = json.loads(GLOBALS_PATH.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ConversionError(f"Cannot load vendored globals from {GLOBALS_PATH}: {exc}") from exc
    if not isinstance(document, list) or not all(isinstance(item, str) for item in document):
        raise ConversionError(f"Vendored globals file is not a string array: {GLOBALS_PATH}")
    return document


def _reset_upstream_state() -> None:
    upstream_obfuscator.current_step = 0
    upstream_obfuscator.debug_mode = False
    upstream_obfuscator.USED_LOCAL_NAMES.clear()
    stringstripper.string_index = -1


def convert_lua(lua_text: str, logger: logging.Logger | None = None) -> str:
    """Convert one Lua source string with isolated upstream level 2 state."""
    if not isinstance(lua_text, str):
        raise TypeError("lua_text must be a string")

    _reset_upstream_state()
    globals_list = _load_upstream_globals()
    encoder = stringencoder.get_by_level(OBFUSCATION_LEVEL)
    upstream_output = io.StringIO()
    try:
        with contextlib.redirect_stdout(upstream_output):
            result, _tokens, _strings, _comments = upstream_obfuscator.obfuscate(
                lua_text,
                encoder,
                globals_list,
            )
    except SystemExit as exc:
        raise ConversionError(f"Vendored converter exited unexpectedly with code {exc.code!r}") from exc
    except Exception as exc:
        raise ConversionError(f"Vendored converter failed: {exc}") from exc
    finally:
        if logger is not None:
            for line in upstream_output.getvalue().splitlines():
                logger.debug("upstream: %s", line)

    if not isinstance(result, str):
        raise ConversionError("Vendored converter returned a non-string result")
    return result


def _remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def _recover_interrupted_install(output_dir: Path, backup_dir: Path, logger: logging.Logger) -> None:
    if not backup_dir.exists():
        return
    if output_dir.exists():
        raise InstallationError(
            f"Ambiguous install state: output {output_dir} and backup {backup_dir} both exist",
            state_summary=f"output remains at {output_dir}; backup remains at {backup_dir}",
        )

    logger.warning("Restoring output from interrupted build backup: %s", backup_dir)
    try:
        backup_dir.replace(output_dir)
    except OSError as exc:
        output_exists = output_dir.exists()
        backup_exists = backup_dir.exists()
        if output_exists and not backup_exists:
            logger.warning("Backup restoration completed despite a late rename error: %s", exc)
            return
        if backup_exists and not output_exists:
            state_summary = f"output is absent; backup remains at {backup_dir}"
        elif output_exists and backup_exists:
            state_summary = f"output remains at {output_dir}; backup also remains at {backup_dir}"
        else:
            state_summary = "output and backup are both absent; previous output could not be confirmed"
        raise InstallationError(
            f"Failed to restore interrupted-build backup {backup_dir} at {output_dir}: {exc}",
            state_summary=state_summary,
        ) from exc


def _paths_overlap(first: Path, second: Path) -> bool:
    return first == second or first in second.parents or second in first.parents


def _validate_build_paths(
    source_dir: Path,
    settings_path: Path,
    log_path: Path,
    output_dir: Path,
    staging_dir: Path,
    backup_dir: Path,
) -> None:
    paths = {
        "source": source_dir.resolve(),
        "settings": settings_path.resolve(),
        "log": log_path.resolve(),
        "output": output_dir.resolve(),
        "staging": staging_dir.resolve(),
        "backup": backup_dir.resolve(),
    }
    labels = list(paths)
    for index, first_label in enumerate(labels):
        for second_label in labels[index + 1 :]:
            first_path = paths[first_label]
            second_path = paths[second_label]
            if _paths_overlap(first_path, second_path):
                raise BuildError(
                    f"Build paths overlap: {first_label}={first_path} and "
                    f"{second_label}={second_path}"
                )


def _install_staging(staging_dir: Path, output_dir: Path, backup_dir: Path) -> None:
    had_previous_output = output_dir.exists()
    if had_previous_output:
        try:
            output_dir.replace(backup_dir)
        except OSError as exc:
            output_exists = output_dir.exists()
            backup_exists = backup_dir.exists()
            if backup_exists and not output_exists:
                pass
            else:
                if output_exists and not backup_exists:
                    state_summary = f"previous output was never moved and remains unchanged at {output_dir}"
                elif output_exists and backup_exists:
                    state_summary = f"output remains at {output_dir}; backup also remains at {backup_dir}"
                else:
                    state_summary = "previous output could not be confirmed at output or backup"
                raise InstallationError(
                    f"Failed to move previous output {output_dir} to backup {backup_dir}: {exc}",
                    state_summary=state_summary,
                ) from exc

    install_error: OSError | None = None
    try:
        staging_dir.replace(output_dir)
    except OSError as exc:
        output_exists = output_dir.exists()
        staging_exists = staging_dir.exists()
        if output_exists and not staging_exists:
            install_error = None
        elif output_exists and staging_exists:
            raise InstallationError(
                f"Failed to install staged output {staging_dir} at {output_dir}: {exc}",
                state_summary=f"output remains at {output_dir}; staging also remains at {staging_dir}",
                cleanup_staging=False,
            ) from exc
        else:
            install_error = exc

    if install_error is not None:
        if not had_previous_output:
            if staging_dir.exists():
                state_summary = f"output is absent; staged output remains at {staging_dir}"
            else:
                state_summary = "output and staging are both absent; staged output could not be confirmed"
            raise InstallationError(
                f"Failed to install staged output {staging_dir} at {output_dir}: {install_error}",
                state_summary=state_summary,
            ) from install_error

        try:
            backup_dir.replace(output_dir)
        except OSError as rollback_exc:
            output_exists = output_dir.exists()
            backup_exists = backup_dir.exists()
            if output_exists and not backup_exists:
                raise InstallationError(
                    f"Failed to install staged output {staging_dir} at {output_dir}: {install_error}; "
                    f"backup rollback reported an error after restoring output: {rollback_exc}",
                    state_summary=f"previous output was restored at {output_dir}",
                ) from rollback_exc
            if backup_exists and not output_exists:
                preserved_backup = backup_dir
                detail = f"Previous output backup remains at {preserved_backup}."
            elif output_exists and backup_exists:
                detail = f"Output remains at {output_dir}; backup also remains at {backup_dir}."
            else:
                detail = "Previous output could not be confirmed at the output or backup path."
            raise InstallationError(
                f"Failed to install staged output {staging_dir} at {output_dir}: {install_error}; "
                f"failed to restore backup {backup_dir}: {rollback_exc}. {detail}",
                state_summary=detail,
            ) from rollback_exc
        raise InstallationError(
            f"Failed to install staged output {staging_dir} at {output_dir}: {install_error}; "
            f"prior output was restored at {output_dir}",
            state_summary=f"previous output was restored at {output_dir}",
        ) from install_error

    if had_previous_output:
        try:
            _remove_path(backup_dir)
        except OSError as exc:
            if backup_dir.exists():
                state_summary = (
                    f"new output remains installed at {output_dir}; "
                    f"remaining backup data is preserved at {backup_dir}"
                )
            else:
                state_summary = (
                    f"new output remains installed at {output_dir}; "
                    "backup no longer exists after cleanup failure"
                )
            raise InstallationError(
                f"Installed new output at {output_dir}, but failed to clean backup {backup_dir}: {exc}",
                state_summary=state_summary,
            ) from exc


def build_obfuscated_lua(
    source_dir: Path = DEFAULT_SOURCE_DIR,
    output_dir: Path = DEFAULT_OUTPUT_DIR,
    settings_path: Path = DEFAULT_SETTINGS_PATH,
    converter: Callable[[str, logging.Logger | None], str] = convert_lua,
) -> list[Path]:
    """Build all selected Lua files transactionally and return relative outputs."""
    source_dir = Path(source_dir).resolve()
    output_dir = Path(output_dir).resolve()
    settings_path = Path(settings_path).resolve()
    staging_dir = output_dir.with_name(output_dir.name + ".staging")
    backup_dir = output_dir.with_name(output_dir.name + ".backup")
    settings = load_logging_settings(settings_path)
    _validate_build_paths(
        source_dir,
        settings_path,
        settings.path,
        output_dir,
        staging_dir,
        backup_dir,
    )
    logger = configure_logging(settings)
    staging_owned = False

    try:
        _recover_interrupted_install(output_dir, backup_dir, logger)
        if staging_dir.exists():
            logger.warning("Removing stale staging directory: %s", staging_dir)
            _remove_path(staging_dir)

        inputs = discover_lua_files(source_dir)
        logger.info("Discovered %d Lua files under %s", len(inputs), source_dir)
        staging_dir.mkdir(parents=True)
        staging_owned = True

        for relative_path in inputs:
            source_path = source_dir / relative_path
            destination_path = staging_dir / relative_path
            logger.info("Obfuscating %s", relative_path.as_posix())
            try:
                lua_text = source_path.read_text(encoding="utf-8")
                converted = converter(lua_text, logger)
                destination_path.parent.mkdir(parents=True, exist_ok=True)
                destination_path.write_text(converted, encoding="utf-8", newline="")
            except Exception as exc:
                raise BuildError(f"Failed to build {relative_path.as_posix()}: {exc}") from exc

        logger.info("Preparing release resources from %s", source_dir)
        try:
            shutil.copy2(source_dir / "Phantom.toc", staging_dir / "Phantom.toc")
            shutil.copytree(source_dir / "media", staging_dir / "media", dirs_exist_ok=True)
            _remove_path(staging_dir / "bak")
            _remove_path(staging_dir / "demo")
        except Exception as exc:
            raise BuildError(f"Failed to prepare release resources from {source_dir}: {exc}") from exc

        _install_staging(staging_dir, output_dir, backup_dir)
        logger.info("Installed %d obfuscated Lua files into %s", len(inputs), output_dir)
        return inputs
    except BaseException as exc:
        cleanup_staging = not isinstance(exc, InstallationError) or exc.cleanup_staging
        if staging_owned and cleanup_staging and staging_dir.exists():
            try:
                _remove_path(staging_dir)
            except OSError as cleanup_exc:
                logger.exception("Failed to remove staging directory %s: %s", staging_dir, cleanup_exc)
        if isinstance(exc, InstallationError):
            logger.exception("Obfuscation build failed; %s", exc.state_summary)
        else:
            logger.exception("Obfuscation build failed before new output was installed")
        raise


def main(argv: Sequence[str] | None = None) -> int:
    """Run the guarded command-line interface."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--settings", type=Path, default=DEFAULT_SETTINGS_PATH)
    arguments = parser.parse_args(argv)
    try:
        outputs = build_obfuscated_lua(arguments.source, arguments.output, arguments.settings)
    except BuildError as exc:
        parser.exit(1, f"error: {exc}\n")
    print(f"Built {len(outputs)} Lua files into {arguments.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
