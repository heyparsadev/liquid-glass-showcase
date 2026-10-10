#!/usr/bin/env python3
"""Make small JPEG copies of the screenshots for READMEs and web pages.

  python3 -I scripts/make_web_images.py screenshots [--only 02-place]

Writes screenshots/web/<light|dark>/<slug>.jpg, 600 px wide, from the full-size PNGs. The PNGs
stay the reference images: a README shows these copies and links the PNGs. Colour is not
subsampled (4:4:4), so small text keeps its edges.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from PIL import Image

APPEARANCES = ("light", "dark")
WIDTH = 600
QUALITY = 85


def convert(source: Path, target: Path) -> None:
    """Write a JPEG copy of `source` at `target`, at most WIDTH px wide."""
    with Image.open(source) as image:
        copy = image.convert("RGB")                         # JPEG has no alpha channel
    if copy.width > WIDTH:
        copy = copy.resize((WIDTH, round(copy.height * WIDTH / copy.width)), Image.Resampling.LANCZOS)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".tmp")
    copy.save(temporary, "JPEG", quality=QUALITY, optimize=True, progressive=True, subsampling=0)
    os.replace(temporary, target)                           # atomic: an interrupted run keeps the old file


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Make small JPEG copies of the screenshots.")
    parser.add_argument("root", type=Path)
    parser.add_argument("--only", help="a screen slug such as 02-place; default is every screenshot")
    args = parser.parse_args(argv)

    pattern = f"{args.only}.png" if args.only else "*.png"
    sources = [path for appearance in APPEARANCES for path in sorted((args.root / appearance).glob(pattern))]
    if not sources:
        what = f"for {args.only} " if args.only else ""
        print(f"error: no screenshots {what}under {args.root}", file=sys.stderr)
        return 1

    total = 0
    for source in sources:
        target = args.root / "web" / source.parent.name / f"{source.stem}.jpg"
        convert(source, target)
        total += target.stat().st_size
    print(f"wrote {len(sources)} web image(s), {total / 1_048_576:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
