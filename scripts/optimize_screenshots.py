#!/usr/bin/env python3
"""Shrink the captured PNGs without changing a pixel.

  python3 -I scripts/optimize_screenshots.py screenshots

simctl writes weakly compressed PNGs. This re-saves each one with the best zlib setting and
keeps the new file only when it is smaller and decodes to exactly the same pixels. Only 8-bit
PNGs are touched: Pillow would cut a 16-bit one to 8 bits, which is not the same pixels.
"""
from __future__ import annotations

import argparse
import io
import os
import sys
from pathlib import Path

from PIL import Image


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def is_8_bit(data: bytes) -> bool:
    """True for a PNG whose IHDR says 8 bits per channel (the byte at offset 24)."""
    return data[:8] == PNG_SIGNATURE and data[12:16] == b"IHDR" and data[24] == 8


def optimize(path: Path) -> int:
    """Re-save `path` smaller when that changes no pixel. Returns the bytes saved."""
    if not is_8_bit(path.read_bytes()[:32]):
        return 0
    original = path.stat().st_size
    with Image.open(path) as image:
        image.load()
        buffer = io.BytesIO()
        image.save(buffer, "PNG", optimize=True, compress_level=9)
        pixels = image.tobytes()
    data = buffer.getvalue()
    if len(data) >= original:
        return 0
    with Image.open(io.BytesIO(data)) as check:
        if check.mode != image.mode or check.tobytes() != pixels:
            return 0
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, path)                      # atomic: an interrupted run keeps the old file
    return original - len(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Shrink captured PNGs without changing a pixel.")
    parser.add_argument("root", type=Path)
    parser.add_argument("--only", help="a screen slug such as 02-place; default is every screenshot")
    args = parser.parse_args(argv)

    files = sorted(args.root.glob(f"*/{args.only}.png" if args.only else "*/*.png"))
    saved = sum(optimize(path) for path in files)
    print(f"optimized {len(files)} file(s), saved {saved / 1_048_576:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
