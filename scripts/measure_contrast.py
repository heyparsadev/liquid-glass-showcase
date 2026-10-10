#!/usr/bin/env python3
"""Measure the contrast of the text and icons in the captured screenshots (WCAG 2.x).

  python3 -I scripts/measure_contrast.py screenshots [--only 02-place]

scripts/contrast_boxes.json lists boxes in screenshot pixels. Inside a box the text colour is
whichever extreme (the lightest or the darkest 0.5% of pixels) lies farther from the median
colour, and the median is the background. A box has a kind:

  text         needs 4.5:1
  icon         needs 3:1
  system       drawn by iOS (placeholder, navigation subtitle, the Maps "Legal" link): reported
  decorative   white glyph on a system-colour disc next to a text label: reported

Keep each box on one background. When a box straddles two (the scrolled Discover subtitle sits
on the edge of a blurred card), the lightest or darkest pixels can be the other background, not
the text; the report prints both colours so a wrong pick is visible.

Exits 1 when a text or icon box falls below its limit, or a screenshot is missing; 2 when the
boxes file is missing or malformed.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

EXPECTED_SIZE = (1206, 2622)
APPEARANCES = ("light", "dark")
LIMITS = {"text": 4.5, "icon": 3.0}
KINDS = ("text", "icon", "system", "decorative")
DEFAULT_BOXES = Path(__file__).with_name("contrast_boxes.json")


def _linear(channel: int) -> float:
    value = channel / 255
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = rgb
    return 0.2126 * _linear(r) + 0.7152 * _linear(g) + 0.0722 * _linear(b)


def ratio(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def _mean(pixels: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    return tuple(sum(p[i] for p in pixels) // len(pixels) for i in range(3))  # type: ignore[return-value]


def measure(image: Image.Image, box: tuple[int, int, int, int]) -> tuple[float, tuple, tuple]:
    """Returns (contrast ratio, text colour, background colour) for the box."""
    pixels = sorted(image.convert("RGB").crop(box).getdata(), key=luminance)
    background = pixels[len(pixels) // 2]
    k = max(1, len(pixels) // 200)
    darkest, lightest = _mean(pixels[:k]), _mean(pixels[-k:])
    text = lightest if abs(luminance(lightest) - luminance(background)) > abs(luminance(darkest) - luminance(background)) else darkest
    return ratio(text, background), text, background


def load_boxes(path: Path) -> dict[str, list[dict]]:
    """Read the boxes file. Raises ValueError naming the first bad entry, so a typo in a kind
    (which would silently skip the gate) or a box off the screenshot cannot go unnoticed."""
    boxes = json.loads(path.read_text())
    width, height = EXPECTED_SIZE
    for slug, entries in boxes.items():
        for entry in entries:
            name = entry.get("name")
            where = f"{path.name}: {slug}: {name!r}"
            if not isinstance(name, str) or not name:
                raise ValueError(f"{path.name}: {slug}: an entry has no name")
            if entry.get("kind") not in KINDS:
                raise ValueError(f"{where}: kind must be one of {', '.join(KINDS)}")
            box = entry.get("box")
            if not (isinstance(box, list) and len(box) == 4 and all(isinstance(v, int) for v in box)):
                raise ValueError(f"{where}: box must be [x0, y0, x1, y1] in whole pixels")
            x0, y0, x1, y1 = box
            if not (0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height):
                raise ValueError(f"{where}: box {box} is empty or outside the {width} x {height} screenshot")
    return boxes


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Measure text and icon contrast in screenshots.")
    parser.add_argument("root", type=Path)
    parser.add_argument("--only", help="a screen slug such as 02-place")
    parser.add_argument("--boxes", type=Path, default=DEFAULT_BOXES)
    args = parser.parse_args(argv)

    try:
        boxes = load_boxes(args.boxes)
    except (OSError, ValueError) as error:             # a bad JSON file is a ValueError too
        print(f"error: {error}", file=sys.stderr)
        return 2
    problems: list[str] = []
    for slug, entries in boxes.items():
        if args.only and slug != args.only:
            continue
        for appearance in APPEARANCES:
            path = args.root / appearance / f"{slug}.png"
            if not path.exists():
                problems.append(f"{path}: missing")
                continue
            with Image.open(path) as image:
                image.load()
                print(f"{slug} {appearance}")
                for entry in entries:
                    value, text, background = measure(image, tuple(entry["box"]))
                    limit = LIMITS.get(entry["kind"])
                    flag = ""
                    if limit is not None and value < limit:
                        flag = f"  <-- below {limit}"
                        problems.append(f"{path}: {entry['name']} is {value:.2f}:1, below {limit}:1")
                    print(f"  {entry['name']:24s} {value:5.2f}:1  {entry['kind']:10s} text {text} on {background}{flag}")
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
