#!/usr/bin/env python3
"""Shrink the captured PNGs without changing a pixel.

  python3 -I scripts/optimize_screenshots.py screenshots

simctl writes weakly compressed PNGs. This re-saves each one with the best zlib setting and
keeps the new file only when it is smaller and decodes to exactly the same pixels.
"""
from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

from PIL import Image


def optimize(path: Path) -> int:
    """Re-save `path` smaller when that changes no pixel. Returns the bytes saved."""
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
    path.write_bytes(data)
    return original - len(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Shrink captured PNGs without changing a pixel.")
    parser.add_argument("root", type=Path)
    args = parser.parse_args(argv)

    files = sorted(args.root.glob("*/*.png"))
    saved = sum(optimize(path) for path in files)
    print(f"optimized {len(files)} file(s), saved {saved / 1_048_576:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
