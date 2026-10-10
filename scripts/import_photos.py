#!/usr/bin/env python3
"""Import Unsplash downloads into the asset catalog.

Run from the repo root, with -I because the photos are downloaded files:

  python3 -I scripts/import_photos.py kyoto=<file>.jpg santorini=<file>.jpg ...

For each slug=file pair (file is in --inbox) this resizes the long edge to at most
2000 px, drops metadata, saves JPEG quality 80 into <assets>/<slug>.imageset, and
writes CREDITS.md. It exits 1 if the processed photos are over the 4 MB budget.

The photographer comes from the --sources JSON file when it lists the slug:

  {"kyoto": {"photographer": "Jane Doe", "url": "https://unsplash.com/photos/<title>-<id>"}}

and otherwise from the file name, when it is named the way Unsplash names downloads,
"<photographer>-<photo-id>-unsplash.jpg".
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFile, ImageOps

MAX_EDGE = 2000
QUALITY = 80
BUDGET_BYTES = 4 * 1024 * 1024
_UNSPLASH_NAME = re.compile(r"^(?P<photographer>.+)-(?P<id>[A-Za-z0-9_-]{11})-unsplash\.jpe?g$")
_UNSPLASH_URL = re.compile(r"https://unsplash\.com/photos/(?:[^/?#]*-)?(?P<id>[A-Za-z0-9_-]{11})/?")


@dataclass(frozen=True)
class Credit:
    slug: str
    photographer: str
    photo_id: str

    @property
    def url(self) -> str:
        return f"https://unsplash.com/photos/{self.photo_id}"


def parse_unsplash_filename(name: str) -> tuple[str, str]:
    match = _UNSPLASH_NAME.match(name)
    if not match:
        raise ValueError(f"not an Unsplash download name: {name}")
    photographer = " ".join(part.capitalize() for part in match["photographer"].split("-"))
    return photographer, match["id"]


def photo_id_from_url(url: str) -> str:
    match = _UNSPLASH_URL.fullmatch(url.partition("?")[0])
    if not match:
        raise ValueError(f"not an Unsplash photo URL: {url}")
    return match["id"]


def credit_for(slug: str, filename: str, sources: dict[str, dict[str, str]]) -> Credit:
    """The credit from the sources file when it lists the slug, else from the file name."""
    if slug in sources:
        entry = sources[slug]
        return Credit(slug, entry["photographer"], photo_id_from_url(entry["url"]))
    try:
        photographer, photo_id = parse_unsplash_filename(filename)
    except ValueError:
        raise ValueError(
            f"no photographer known: {filename} is not an Unsplash download name "
            f"and the sources file has no entry for {slug}"
        ) from None
    return Credit(slug, photographer, photo_id)


def fit_long_edge(size: tuple[int, int], max_edge: int = MAX_EDGE) -> tuple[int, int]:
    width, height = size
    long_edge = max(width, height)
    if long_edge <= max_edge:
        return width, height
    scale = max_edge / long_edge
    return max(1, round(width * scale)), max(1, round(height * scale))


def process_image(src: Path, dst: Path, max_edge: int = MAX_EDGE, quality: int = QUALITY) -> int:
    # Some downloads lose their last bytes. A progressive JPEG then only misses its final
    # refinement scan, so the picture is intact: allow it while decoding, then restore.
    tolerated = ImageFile.LOAD_TRUNCATED_IMAGES
    ImageFile.LOAD_TRUNCATED_IMAGES = True
    try:
        with Image.open(src) as original:
            icc = original.info.get("icc_profile")
            image = ImageOps.exif_transpose(original).convert("RGB")
    finally:
        ImageFile.LOAD_TRUNCATED_IMAGES = tolerated
    size = fit_long_edge(image.size, max_edge)
    if size != image.size:
        image = image.resize(size, Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    options = {"quality": quality, "optimize": True, "progressive": True}
    if icc:
        options["icc_profile"] = icc          # keep color; EXIF is not passed, so it is dropped
    image.save(dst, "JPEG", **options)
    return dst.stat().st_size


def write_contents(imageset: Path, slug: str) -> None:
    contents = {
        "images": [{"filename": f"{slug}.jpg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def credits_markdown(credits: list[Credit]) -> str:
    lines = [
        "# Photo credits",
        "",
        "All photos are from [Unsplash](https://unsplash.com) and used under the "
        "[Unsplash License](https://unsplash.com/license).",
        "",
        "| Asset | Photographer | Photo |",
        "|---|---|---|",
    ]
    lines += [f"| `{c.slug}` | {c.photographer} | {c.url} |" for c in credits]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Import Unsplash downloads into the asset catalog.")
    parser.add_argument("--inbox", type=Path, default=Path("photos/inbox"))
    parser.add_argument("--assets", type=Path, default=Path("Resources/Assets.xcassets"))
    parser.add_argument("--credits", type=Path, default=Path("CREDITS.md"))
    parser.add_argument("--sources", type=Path, default=Path("photos/sources.json"),
                        help="JSON file with {slug: {photographer, url}} for files not named by Unsplash")
    parser.add_argument("pairs", nargs="+", metavar="slug=file")
    args = parser.parse_args(argv)

    sources = json.loads(args.sources.read_text()) if args.sources.exists() else {}
    credits: list[Credit] = []
    total = 0
    for pair in args.pairs:
        slug, separator, filename = pair.partition("=")
        if not separator or not slug or not filename:
            parser.error(f"expected slug=file, got {pair!r}")
        try:
            credit = credit_for(slug, filename, sources)
        except ValueError as problem:
            parser.error(f"{slug}: {problem}")
        imageset = args.assets / f"{slug}.imageset"
        total += process_image(args.inbox / filename, imageset / f"{slug}.jpg")
        write_contents(imageset, slug)
        credits.append(credit)

    args.credits.write_text(credits_markdown(credits))
    print(f"imported {len(credits)} photo(s), {total / 1_048_576:.1f} MB")
    if total > BUDGET_BYTES:
        print(f"error: photos total {total} bytes, over the {BUDGET_BYTES}-byte budget", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
