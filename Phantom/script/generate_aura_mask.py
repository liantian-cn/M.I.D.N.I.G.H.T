"""Generate the PNG and TGA aura mask assets using only the standard library."""

from __future__ import annotations

import binascii
import json
import logging
from pathlib import Path
import struct
import sys
import zlib


IMAGE_WIDTH = 16
IMAGE_HEIGHT = 16
OPAQUE_REGION_START = 10
TRANSPARENT_PIXEL = bytes((0, 0, 0, 0))
OPAQUE_WHITE_PIXEL = bytes((255, 255, 255, 255))

SCRIPT_DIRECTORY = Path(__file__).resolve().parent
REPOSITORY_ROOT = SCRIPT_DIRECTORY.parent
SETTINGS_PATH = SCRIPT_DIRECTORY / "aura_mask_settings.json"
PNG_OUTPUT_PATH = REPOSITORY_ROOT / "src/media/aura/aura_border_32_4px.png"
TGA_OUTPUT_PATH = REPOSITORY_ROOT / "src/media/aura/aura_border_32_4px.tga"

LOGGER = logging.getLogger("aura_mask_generator")


def load_settings() -> dict[str, object]:
    with SETTINGS_PATH.open("r", encoding="utf-8") as settings_file:
        settings = json.load(settings_file)

    if not isinstance(settings, dict):
        raise ValueError("Settings root must be a JSON object")

    return settings


def configure_logging(settings: dict[str, object]) -> None:
    logging_settings = settings.get("logging")
    if not isinstance(logging_settings, dict):
        raise ValueError("Settings must contain a 'logging' object")

    enabled = logging_settings.get("enabled", True)
    if not isinstance(enabled, bool):
        raise ValueError("logging.enabled must be a boolean")

    if not enabled:
        logging.disable(logging.CRITICAL)
        return

    level_name = logging_settings.get("level", "INFO")
    if not isinstance(level_name, str):
        raise ValueError("logging.level must be a string")

    level = logging.getLevelNamesMapping().get(level_name.upper())
    if level is None:
        raise ValueError(f"Unsupported logging level: {level_name}")

    output_path = logging_settings.get("output_path")
    if output_path is not None and not isinstance(output_path, str):
        raise ValueError("logging.output_path must be a string or null")

    if output_path:
        resolved_output_path = REPOSITORY_ROOT / output_path
        resolved_output_path.parent.mkdir(parents=True, exist_ok=True)
        handler: logging.Handler = logging.FileHandler(
            resolved_output_path,
            encoding="utf-8",
        )
    else:
        handler = logging.StreamHandler()

    handler.setFormatter(
        logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
    )
    LOGGER.handlers.clear()
    LOGGER.addHandler(handler)
    LOGGER.setLevel(level)
    LOGGER.propagate = False


def build_rgba_pixels() -> bytes:
    pixels = bytearray()

    for y in range(IMAGE_HEIGHT):
        for x in range(IMAGE_WIDTH):
            if x >= OPAQUE_REGION_START and y >= OPAQUE_REGION_START:
                pixels.extend(OPAQUE_WHITE_PIXEL)
            else:
                pixels.extend(TRANSPARENT_PIXEL)

    return bytes(pixels)


def validate_pixels(pixels: bytes) -> None:
    expected_byte_count = IMAGE_WIDTH * IMAGE_HEIGHT * 4
    if len(pixels) != expected_byte_count:
        raise ValueError(
            f"Generated {len(pixels)} pixel bytes; expected {expected_byte_count}"
        )

    pixel_values = [
        pixels[index : index + 4] for index in range(0, len(pixels), 4)
    ]
    opaque_count = pixel_values.count(OPAQUE_WHITE_PIXEL)
    transparent_count = pixel_values.count(TRANSPARENT_PIXEL)

    if opaque_count != 36 or transparent_count != 220:
        raise ValueError(
            "Generated pixels do not match the expected mask: "
            f"opaque={opaque_count}, transparent={transparent_count}"
        )


def make_png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    checksum = binascii.crc32(chunk_type + data) & 0xFFFFFFFF
    return (
        struct.pack(">I", len(data))
        + chunk_type
        + data
        + struct.pack(">I", checksum)
    )


def encode_png(pixels: bytes) -> bytes:
    scanlines = bytearray()
    row_byte_count = IMAGE_WIDTH * 4

    for row_index in range(IMAGE_HEIGHT):
        row_start = row_index * row_byte_count
        scanlines.append(0)
        scanlines.extend(pixels[row_start : row_start + row_byte_count])

    header = struct.pack(">IIBBBBB", IMAGE_WIDTH, IMAGE_HEIGHT, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + b"".join(
        (
            make_png_chunk(b"IHDR", header),
            make_png_chunk(b"IDAT", zlib.compress(bytes(scanlines), level=9)),
            make_png_chunk(b"IEND", b""),
        )
    )


def encode_tga(pixels: bytes) -> bytes:
    header = struct.pack(
        "<BBBHHBHHHHBB",
        0,
        0,
        2,
        0,
        0,
        0,
        0,
        0,
        IMAGE_WIDTH,
        IMAGE_HEIGHT,
        32,
        0x28,
    )
    bgra_pixels = bytearray()

    for index in range(0, len(pixels), 4):
        red, green, blue, alpha = pixels[index : index + 4]
        bgra_pixels.extend((blue, green, red, alpha))

    return header + bytes(bgra_pixels)


def write_asset(path: Path, data: bytes) -> None:
    LOGGER.info("Writing %d bytes to %s", len(data), path)
    path.write_bytes(data)


def ensure_fallback_logging() -> None:
    if LOGGER.handlers:
        return

    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(levelname)s %(name)s: %(message)s"))
    LOGGER.addHandler(handler)
    LOGGER.setLevel(logging.INFO)
    LOGGER.propagate = False


def main() -> int:
    try:
        settings = load_settings()
        configure_logging(settings)
        LOGGER.info(
            "Generating %dx%d RGBA mask with opaque region x=%d..%d, y=%d..%d",
            IMAGE_WIDTH,
            IMAGE_HEIGHT,
            OPAQUE_REGION_START,
            IMAGE_WIDTH - 1,
            OPAQUE_REGION_START,
            IMAGE_HEIGHT - 1,
        )

        pixels = build_rgba_pixels()
        validate_pixels(pixels)
        write_asset(PNG_OUTPUT_PATH, encode_png(pixels))
        write_asset(TGA_OUTPUT_PATH, encode_tga(pixels))
        LOGGER.info("Aura mask generation completed successfully")
        return 0
    except Exception:
        ensure_fallback_logging()
        LOGGER.exception("Aura mask generation failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
