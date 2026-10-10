import json
import random

import pytest
from PIL import Image

import import_photos as ip


def make_jpeg(path, size=(3000, 2000)):
    exif = Image.Exif()
    exif[0x010F] = "Camera maker"          # Make
    exif[0x010E] = "private description"   # ImageDescription
    Image.new("RGB", size, (200, 120, 40)).save(path, "JPEG", exif=exif.tobytes())


def test_parse_unsplash_filename_splits_photographer_and_id():
    assert ip.parse_unsplash_filename("pawel-czerwinski-LqKhnDzSF-8-unsplash.jpg") == (
        "Pawel Czerwinski",
        "LqKhnDzSF-8",
    )


def test_parse_unsplash_filename_rejects_other_names():
    with pytest.raises(ValueError):
        ip.parse_unsplash_filename("IMG_1234.jpg")


@pytest.mark.parametrize(
    "size, expected",
    [((4000, 3000), (2000, 1500)), ((3000, 4000), (1500, 2000)), ((1200, 800), (1200, 800))],
)
def test_fit_long_edge(size, expected):
    assert ip.fit_long_edge(size) == expected


def test_process_image_resizes_and_drops_metadata(tmp_path):
    src = tmp_path / "in.jpg"
    make_jpeg(src)
    dst = tmp_path / "out" / "photo.jpg"

    written = ip.process_image(src, dst)

    with Image.open(dst) as out:
        assert out.size == (2000, 1333)
        assert len(out.getexif()) == 0
    assert written == dst.stat().st_size


def test_write_contents_names_the_jpeg(tmp_path):
    imageset = tmp_path / "kyoto.imageset"
    imageset.mkdir()
    ip.write_contents(imageset, "kyoto")
    contents = json.loads((imageset / "Contents.json").read_text())
    assert contents["images"] == [{"filename": "kyoto.jpg", "idiom": "universal"}]
    assert contents["info"] == {"author": "xcode", "version": 1}


def test_credits_markdown_links_every_photo():
    text = ip.credits_markdown([ip.Credit("kyoto", "Jane Doe", "AbCdEfGhIjK")])
    assert "Unsplash License" in text
    assert "| `kyoto` | Jane Doe | https://unsplash.com/photos/AbCdEfGhIjK |" in text


def test_main_imports_photos_and_writes_credits(tmp_path):
    inbox = tmp_path / "inbox"
    inbox.mkdir()
    make_jpeg(inbox / "jane-doe-AbCdEfGhIjK-unsplash.jpg")
    assets = tmp_path / "Assets.xcassets"
    credits = tmp_path / "CREDITS.md"

    code = ip.main([
        "--inbox", str(inbox), "--assets", str(assets), "--credits", str(credits),
        "kyoto=jane-doe-AbCdEfGhIjK-unsplash.jpg",
    ])

    assert code == 0
    assert (assets / "kyoto.imageset" / "kyoto.jpg").exists()
    assert (assets / "kyoto.imageset" / "Contents.json").exists()
    assert "Jane Doe" in credits.read_text()


def test_main_fails_when_over_budget(tmp_path, monkeypatch, capsys):
    inbox = tmp_path / "inbox"
    inbox.mkdir()
    make_jpeg(inbox / "jane-doe-AbCdEfGhIjK-unsplash.jpg")
    monkeypatch.setattr(ip, "BUDGET_BYTES", 10)

    code = ip.main([
        "--inbox", str(inbox), "--assets", str(tmp_path / "a"), "--credits", str(tmp_path / "c.md"),
        "kyoto=jane-doe-AbCdEfGhIjK-unsplash.jpg",
    ])

    assert code == 1
    assert "budget" in capsys.readouterr().err


def make_noisy_progressive_jpeg(path, size=(800, 600)):
    noise = random.Random(0).randbytes(size[0] * size[1] * 3)
    Image.frombytes("RGB", size, noise).save(path, "JPEG", quality=90, progressive=True)


def test_process_image_accepts_a_jpeg_missing_its_last_bytes(tmp_path):
    src = tmp_path / "cut.jpg"
    make_noisy_progressive_jpeg(src)
    src.write_bytes(src.read_bytes()[:-300])
    with pytest.raises(OSError):            # the premise: Pillow rejects such a file by default
        with Image.open(src) as probe:
            probe.load()
    dst = tmp_path / "out.jpg"

    ip.process_image(src, dst)

    with Image.open(dst) as out:
        out.load()                          # the re-encoded file is complete
        assert out.size == (800, 600)


@pytest.mark.parametrize(
    "url, expected",
    [
        ("https://unsplash.com/photos/AbCdEfGhIjK", "AbCdEfGhIjK"),
        ("https://unsplash.com/photos/white-houses-LqKhnDzSF-8", "LqKhnDzSF-8"),
        ("https://unsplash.com/photos/white-houses-AbCdEfGhIjK?utm_source=x", "AbCdEfGhIjK"),
    ],
)
def test_photo_id_from_url(url, expected):
    assert ip.photo_id_from_url(url) == expected


def test_photo_id_from_url_rejects_other_hosts():
    with pytest.raises(ValueError):
        ip.photo_id_from_url("https://example.com/photos/AbCdEfGhIjK")


def test_main_reads_credits_from_a_sources_file_when_the_name_is_not_unsplash_style(tmp_path):
    inbox = tmp_path / "inbox"
    inbox.mkdir()
    make_jpeg(inbox / "santorai.jpeg")
    sources = tmp_path / "sources.json"
    sources.write_text(json.dumps({
        "santorini": {"photographer": "Jane Doe", "url": "https://unsplash.com/photos/white-domes-AbCdEfGhIjK"},
    }))
    credits = tmp_path / "CREDITS.md"

    code = ip.main([
        "--inbox", str(inbox), "--assets", str(tmp_path / "a"), "--credits", str(credits),
        "--sources", str(sources), "santorini=santorai.jpeg",
    ])

    assert code == 0
    assert "| `santorini` | Jane Doe | https://unsplash.com/photos/AbCdEfGhIjK |" in credits.read_text()


def test_main_asks_for_a_photographer_when_the_file_name_gives_none(tmp_path, capsys):
    inbox = tmp_path / "inbox"
    inbox.mkdir()
    make_jpeg(inbox / "santorai.jpeg")

    with pytest.raises(SystemExit) as raised:
        ip.main([
            "--inbox", str(inbox), "--assets", str(tmp_path / "a"), "--credits", str(tmp_path / "c.md"),
            "--sources", str(tmp_path / "missing.json"), "santorini=santorai.jpeg",
        ])

    assert raised.value.code == 2
    err = capsys.readouterr().err
    assert "photographer" in err and "santorini" in err
