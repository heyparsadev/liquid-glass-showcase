import json

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
