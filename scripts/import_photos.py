#!/usr/bin/env python3
"""Import Unsplash downloads into the asset catalog.

Run from the repo root, with -I because the photos are downloaded files:

  python3 -I scripts/import_photos.py kyoto=<file>.jpg santorini=<file>.jpg ...

For each slug=file pair (file is in --inbox) this resizes the long edge to at most
2000 px, drops metadata, saves JPEG quality 80 into <assets>/<slug>.imageset, and
writes CREDITS.md. It exits 1 if the photos in the catalog are over the 4 MB budget.

The photographer comes from the --sources JSON file when it lists the slug:

  {"kyoto": {"photographer": "Jane Doe", "url": "https://unsplash.com/photos/<title>-<id>"}}

or, when the name was not kept, an explicit declaration that lists the photo as such:

  {"kyoto": {"unrecorded": true}}

and otherwise from the file name, when it is named the way Unsplash names downloads,
"<photographer>-<photo-id>-unsplash.jpg". Every photo in the catalog needs one of these, or
nothing is written. While building, --allow-missing-credits imports anyway and leaves
the photo out of CREDITS.md until its credit is known.
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
DEFAULT_SOURCES = Path("photos/sources.json")
_UNSPLASH_NAME = re.compile(r"^(?P<photographer>.+)-(?P<id>[A-Za-z0-9_-]{11})-unsplash\.jpe?g$")
_UNSPLASH_URL = re.compile(r"https://unsplash\.com/photos/(?:[^/?#]*-)?(?P<id>[A-Za-z0-9_-]{11})/?")


@dataclass(frozen=True)
class Credit:
    slug: str
    photographer: str | None          # None: declared as not recorded
    photo_id: str | None = None

    @property
    def url(self) -> str | None:
        return f"https://unsplash.com/photos/{self.photo_id}" if self.photo_id else None


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


def load_sources(path: Path | None) -> dict[str, Credit]:
    """Credits listed in the sources file. The default path may be absent; an explicit one may not."""
    explicit = path is not None
    path = path or DEFAULT_SOURCES
    if not path.exists():
        if explicit:
            raise ValueError(f"sources file not found: {path}")
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as problem:
        raise ValueError(f"{path} is not valid JSON: {problem}") from None
    credits: dict[str, Credit] = {}
    for slug, entry in data.items():
        if isinstance(entry, dict) and entry.get("unrecorded") is True:
            credits[slug] = Credit(slug, None, None)
            continue
        if not isinstance(entry, dict) or "photographer" not in entry or "url" not in entry:
            raise ValueError(f'{path}: {slug} needs a photographer and a url (or "unrecorded": true)')
        try:
            credits[slug] = Credit(slug, entry["photographer"], photo_id_from_url(entry["url"]))
        except ValueError as problem:
            raise ValueError(f"{path}: {slug}: {problem}") from None
    return credits


def credit_for(slug: str, filename: str, sources: dict[str, Credit]) -> Credit | None:
    """The credit from the sources file when it lists the slug, else from the file name."""
    if slug in sources:
        return sources[slug]
    try:
        photographer, photo_id = parse_unsplash_filename(filename)
    except ValueError:
        return None
    return Credit(slug, photographer, photo_id)


def fit_long_edge(size: tuple[int, int], max_edge: int = MAX_EDGE) -> tuple[int, int]:
    width, height = size
    long_edge = max(width, height)
    if long_edge <= max_edge:
        return width, height
    scale = max_edge / long_edge
    return max(1, round(width * scale)), max(1, round(height * scale))


def _decode(src: Path) -> tuple[Image.Image, bytes | None]:
    with Image.open(src) as original:
        icc = original.info.get("icc_profile")
        return ImageOps.exif_transpose(original).convert("RGB"), icc


def open_rgb(src: Path) -> tuple[Image.Image, bytes | None]:
    try:
        return _decode(src)
    except OSError:
        # Some downloads lose their last bytes. A progressive JPEG then only misses its final
        # refinement scan, so the picture is intact: allow it, say so, and restore the flag.
        tolerated = ImageFile.LOAD_TRUNCATED_IMAGES
        ImageFile.LOAD_TRUNCATED_IMAGES = True
        try:
            result = _decode(src)
        finally:
            ImageFile.LOAD_TRUNCATED_IMAGES = tolerated
        print(f"warning: {src.name} is cut off; used what could be decoded", file=sys.stderr)
        return result


def process_image(src: Path, dst: Path, max_edge: int = MAX_EDGE, quality: int = QUALITY) -> int:
    image, icc = open_rgb(src)
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
    ]
    if any(c.photographer is None for c in credits):
        lines += [
            "Where the photographer is listed as not recorded, the name wasn't kept when the photo "
            "was downloaded. The license doesn't require attribution.",
            "",
        ]
    lines += ["| Asset | Photographer | Photo |", "|---|---|---|"]
    lines += [f"| `{c.slug}` | {c.photographer or 'not recorded'} | {c.url or ''} |" for c in credits]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Import Unsplash downloads into the asset catalog.")
    parser.add_argument("--inbox", type=Path, default=Path("photos/inbox"))
    parser.add_argument("--assets", type=Path, default=Path("Resources/Assets.xcassets"))
    parser.add_argument("--credits", type=Path, default=Path("CREDITS.md"))
    parser.add_argument("--sources", type=Path, default=None,
                        help=f"JSON file with {{slug: {{photographer, url}}}} (default {DEFAULT_SOURCES} if it exists)")
    parser.add_argument("--allow-missing-credits", action="store_true",
                        help="import photos whose photographer is not known yet (while building)")
    parser.add_argument("pairs", nargs="+", metavar="slug=file")
    args = parser.parse_args(argv)

    try:
        sources = load_sources(args.sources)
    except ValueError as problem:
        parser.error(str(problem))

    jobs: list[tuple[str, str]] = []
    problems: list[str] = []
    for pair in args.pairs:
        slug, separator, filename = pair.partition("=")
        if not separator or not slug or not filename:
            problems.append(f"expected slug=file, got {pair!r}")
        elif not (args.inbox / filename).is_file():
            problems.append(f"{filename} is not in {args.inbox}")
        else:
            jobs.append((slug, filename))
    if problems:
        parser.error("; ".join(problems))

    known = dict(sources)
    for slug, filename in jobs:
        credit = credit_for(slug, filename, sources)
        if credit:
            known[slug] = credit
    catalog = {path.name.removesuffix(".imageset") for path in args.assets.glob("*.imageset")}
    catalog |= {slug for slug, _ in jobs}
    uncredited = sorted(catalog - known.keys())
    if uncredited and not args.allow_missing_credits:
        parser.error(
            f"no photographer for {', '.join(uncredited)}: name the files the way Unsplash does, "
            f"list the slugs in {args.sources or DEFAULT_SOURCES}, or pass --allow-missing-credits while building"
        )

    for slug, filename in jobs:
        imageset = args.assets / f"{slug}.imageset"
        process_image(args.inbox / filename, imageset / f"{slug}.jpg")
        write_contents(imageset, slug)

    args.credits.write_text(credits_markdown([known[slug] for slug in sorted(catalog) if slug in known]))
    for slug in uncredited:
        print(f"warning: no credit yet for {slug}; it is left out of {args.credits}", file=sys.stderr)
    total = sum(path.stat().st_size for path in args.assets.glob("*.imageset/*.jpg"))
    print(f"imported {len(jobs)} photo(s); the catalog holds {total / 1_048_576:.1f} MB")
    if total > BUDGET_BYTES:
        print(f"error: photos total {total} bytes, over the {BUDGET_BYTES}-byte budget", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
