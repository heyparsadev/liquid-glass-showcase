from PIL import Image, JpegImagePlugin

import make_web_images as web


def make_screenshot(path, size=(1206, 2622), mode="RGB"):
    path.parent.mkdir(parents=True, exist_ok=True)
    fill = (200, 120, 40, 255) if mode == "RGBA" else (200, 120, 40)
    image = Image.new(mode, size, fill)
    image.paste((20, 20, 20), (50, 100, size[0] - 50, 160))
    image.save(path, "PNG")


def written(root):
    return sorted(p.relative_to(root).as_posix() for p in (root / "web").rglob("*.jpg"))


def test_a_screenshot_becomes_a_600_px_wide_jpeg(tmp_path):
    source = tmp_path / "light" / "02-place.png"
    target = tmp_path / "web" / "light" / "02-place.jpg"
    make_screenshot(source)

    web.convert(source, target)

    with Image.open(target) as copy:
        assert copy.format == "JPEG"
        assert copy.size == (600, 1304)                 # 1206 x 2622 scaled to the same aspect ratio


def test_an_image_narrower_than_the_width_is_not_enlarged(tmp_path):
    source = tmp_path / "light" / "02-place.png"
    target = tmp_path / "web" / "light" / "02-place.jpg"
    make_screenshot(source, size=(402, 874))

    web.convert(source, target)

    with Image.open(target) as copy:
        assert copy.size == (402, 874)


def test_a_png_with_an_alpha_channel_still_converts(tmp_path):
    source = tmp_path / "light" / "02-place.png"
    target = tmp_path / "web" / "light" / "02-place.jpg"
    make_screenshot(source, mode="RGBA")                # JPEG cannot store alpha

    web.convert(source, target)

    with Image.open(target) as copy:
        assert copy.mode == "RGB"


def test_colour_is_not_subsampled_so_small_text_stays_crisp(tmp_path):
    source = tmp_path / "light" / "02-place.png"
    target = tmp_path / "web" / "light" / "02-place.jpg"
    make_screenshot(source)

    web.convert(source, target)

    with Image.open(target) as copy:
        assert JpegImagePlugin.get_sampling(copy) == 0  # 4:4:4


def test_main_writes_a_copy_for_each_screenshot_in_both_appearances(tmp_path, capsys):
    for appearance in ("light", "dark"):
        for slug in ("02-place", "03-discover"):
            make_screenshot(tmp_path / appearance / f"{slug}.png")

    code = web.main([str(tmp_path)])

    assert code == 0
    assert written(tmp_path) == [
        "web/dark/02-place.jpg", "web/dark/03-discover.jpg",
        "web/light/02-place.jpg", "web/light/03-discover.jpg",
    ]
    assert "wrote 4 web image(s)" in capsys.readouterr().out


def test_only_limits_the_work_to_one_screen(tmp_path):
    for appearance in ("light", "dark"):
        for slug in ("02-place", "03-discover"):
            make_screenshot(tmp_path / appearance / f"{slug}.png")

    code = web.main([str(tmp_path), "--only", "02-place"])

    assert code == 0
    assert written(tmp_path) == ["web/dark/02-place.jpg", "web/light/02-place.jpg"]


def test_an_unknown_screen_is_an_error_and_writes_nothing(tmp_path, capsys):
    make_screenshot(tmp_path / "light" / "02-place.png")

    code = web.main([str(tmp_path), "--only", "09-nothing"])

    assert code == 1
    assert "09-nothing" in capsys.readouterr().err
    assert not (tmp_path / "web").exists()


def test_a_tree_without_screenshots_is_an_error(tmp_path, capsys):
    code = web.main([str(tmp_path)])

    assert code == 1
    assert "no screenshots" in capsys.readouterr().err


def test_running_twice_gives_the_same_file_and_leaves_no_temporary_file(tmp_path):
    make_screenshot(tmp_path / "light" / "02-place.png")
    web.main([str(tmp_path)])
    first = (tmp_path / "web" / "light" / "02-place.jpg").read_bytes()

    web.main([str(tmp_path)])

    assert (tmp_path / "web" / "light" / "02-place.jpg").read_bytes() == first
    assert [p.name for p in (tmp_path / "web" / "light").iterdir()] == ["02-place.jpg"]
