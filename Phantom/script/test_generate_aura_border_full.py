"""Verify the generated opaque 32 by 32 full-overlay assets."""

from __future__ import annotations

import struct
from pathlib import Path
import unittest
import zlib

import generate_aura_border_full as generator


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
REPOSITORY_ROOT = SCRIPT_DIRECTORY.parent
PNG_PATH = REPOSITORY_ROOT / "src/media/aura/aura_border_full.png"
TGA_PATH = REPOSITORY_ROOT / "src/media/aura/aura_border_full.tga"


def read_png_chunks(data: bytes) -> list[tuple[bytes, bytes]]:
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError("PNG signature is invalid")

    chunks = []
    offset = 8
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_data = data[offset + 8 : offset + 8 + length]
        chunks.append((chunk_type, chunk_data))
        offset += 12 + length
    return chunks


class AuraBorderFullGeneratorTests(unittest.TestCase):
    def test_pixels_are_opaque_white(self) -> None:
        pixels = generator.build_rgba_pixels()
        self.assertEqual(len(pixels), 32 * 32 * 4)
        self.assertEqual(pixels, bytes((255, 255, 255, 255)) * (32 * 32))
        generator.validate_pixels(pixels)

    def test_png_has_expected_header_and_scanlines(self) -> None:
        chunks = read_png_chunks(PNG_PATH.read_bytes())
        self.assertEqual(chunks[0][0], b"IHDR")
        self.assertEqual(
            struct.unpack(">IIBBBBB", chunks[0][1]), (32, 32, 8, 6, 0, 0, 0)
        )
        compressed = b"".join(data for chunk_type, data in chunks if chunk_type == b"IDAT")
        expected_scanline = b"\x00" + bytes((255, 255, 255, 255)) * 32
        self.assertEqual(zlib.decompress(compressed), expected_scanline * 32)

    def test_tga_has_expected_header_and_payload(self) -> None:
        data = TGA_PATH.read_bytes()
        self.assertEqual(len(data), 18 + (32 * 32 * 4))
        self.assertEqual(
            struct.unpack("<BBBHHBHHHHBB", data[:18]),
            (0, 0, 2, 0, 0, 0, 0, 0, 32, 32, 32, 0x28),
        )
        self.assertEqual(data[18:], bytes((255, 255, 255, 255)) * (32 * 32))

    def test_encoding_is_deterministic(self) -> None:
        pixels = generator.build_rgba_pixels()
        self.assertEqual(generator.encode_png(pixels), PNG_PATH.read_bytes())
        self.assertEqual(generator.encode_tga(pixels), TGA_PATH.read_bytes())


if __name__ == "__main__":
    unittest.main()
