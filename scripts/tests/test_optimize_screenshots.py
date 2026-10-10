from PIL import Image

import optimize_screenshots as opt


def make_screenshot(path, color=(200, 120, 40)):
    image = Image.new("RGB", (600, 1300), color)
    image.paste((20, 20, 20), (50, 100, 550, 160))          # something to compress around
    image.save(path, "PNG", compress_level=1)               # a deliberately weak first save


def test_a_weakly_compressed_png_shrinks_and_keeps_every_pixel(tmp_path):
    path = tmp_path / "02-place.png"
    make_screenshot(path)
    before = path.stat().st_size
    pixels = Image.open(path).tobytes()

    opt.optimize(path)

    assert path.stat().st_size < before
    assert Image.open(path).tobytes() == pixels


def test_a_png_that_cannot_shrink_is_left_alone(tmp_path):
    path = tmp_path / "02-place.png"
    make_screenshot(path)
    opt.optimize(path)
    once = path.read_bytes()

    opt.optimize(path)

    assert path.read_bytes() == once


def test_main_optimizes_every_png_under_root_and_reports(tmp_path, capsys):
    for appearance in ("light", "dark"):
        (tmp_path / appearance).mkdir()
        make_screenshot(tmp_path / appearance / "02-place.png")

    code = opt.main([str(tmp_path)])

    assert code == 0
    assert "optimized 2 file(s)" in capsys.readouterr().out
