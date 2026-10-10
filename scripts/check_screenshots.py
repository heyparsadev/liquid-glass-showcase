#!/usr/bin/env python3
"""Sanity-check captured screenshots.

  python3 -I scripts/check_screenshots.py screenshots [--only 02-place]

Fails (exit 1) when a screenshot is missing, has the wrong size, looks blank, or
(for the satellite map screen) still shows MapKit's flat loading grid.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageStat

EXPECTED_SIZE = (1206, 2622)            # iPhone 18 Pro, @3x
APPEARANCES = ("light", "dark")
SATELLITE_SCREENS = {"01-explore"}
BLANK_DOMINANT_FRACTION = 0.95          # 95%+ of pixels within ±6 levels of one gray = blank
FLAT_TILE_STDDEV = 2.0
MAX_FLAT_FRACTION = 0.5


def read_slugs(path: Path) -> list[str]:
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


def stddev(image: Image.Image) -> float:
    return ImageStat.Stat(image.convert("L")).stddev[0]


def dominant_fraction(image: Image.Image, tolerance: int = 6) -> float:
    """Share of pixels whose gray level is within `tolerance` of the most common level."""
    histogram = image.convert("L").histogram()
    peak = max(range(256), key=histogram.__getitem__)
    near = sum(histogram[max(0, peak - tolerance): peak + tolerance + 1])
    return near / sum(histogram)


def flat_tile_fraction(image: Image.Image, box: tuple[int, int, int, int], tile: int = 32) -> float:
    region = image.convert("L").crop(box)
    width, height = region.size
    total = flat = 0
    for x in range(0, width - tile + 1, tile):
        for y in range(0, height - tile + 1, tile):
            total += 1
            if stddev(region.crop((x, y, x + tile, y + tile))) < FLAT_TILE_STDDEV:
                flat += 1
    return flat / total if total else 0.0


def check_image(path: Path, slug: str, size: tuple[int, int] = EXPECTED_SIZE) -> list[str]:
    if not path.exists():
        return [f"{path}: missing"]
    problems: list[str] = []
    with Image.open(path) as image:
        if image.size != size:
            problems.append(f"{path}: size {image.size}, expected {size}")
        if dominant_fraction(image) > BLANK_DOMINANT_FRACTION:
            problems.append(f"{path}: looks blank")
        if slug in SATELLITE_SCREENS:
            width, height = image.size
            band = (0, int(height * 0.10), width, int(height * 0.45))   # above the half-height sheet
            if flat_tile_fraction(image, band) > MAX_FLAT_FRACTION:
                problems.append(f"{path}: map tiles probably not loaded")
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Sanity-check captured screenshots.")
    parser.add_argument("root", type=Path)
    parser.add_argument("--only")
    parser.add_argument("--screens", type=Path, default=Path(__file__).with_name("screens.txt"))
    args = parser.parse_args(argv)

    slugs = read_slugs(args.screens)
    if args.only:
        slugs = [slug for slug in slugs if slug == args.only]
    problems = [
        problem
        for appearance in APPEARANCES
        for slug in slugs
        for problem in check_image(args.root / appearance / f"{slug}.png", slug)
    ]
    for problem in problems:
        print(problem, file=sys.stderr)
    print(f"checked {len(slugs) * len(APPEARANCES)} screenshot(s), {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
