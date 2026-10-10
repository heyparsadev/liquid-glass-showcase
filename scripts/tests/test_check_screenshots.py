from PIL import Image

import check_screenshots as cs

SIZE = cs.EXPECTED_SIZE


def noise(size=SIZE):
    return Image.effect_noise(size, 64).convert("RGB")


def test_noisy_screenshot_passes(tmp_path):
    path = tmp_path / "02-place.png"
    noise().save(path)
    assert cs.check_image(path, "02-place") == []


def test_uniform_screenshot_looks_blank(tmp_path):
    path = tmp_path / "02-place.png"
    Image.new("RGB", SIZE, (255, 255, 255)).save(path)
    assert any("looks blank" in p for p in cs.check_image(path, "02-place"))


def test_mostly_uniform_screenshot_with_a_little_text_looks_blank(tmp_path):
    image = Image.new("RGB", SIZE, (255, 255, 255))
    image.paste((0, 0, 0), (500, 1200, 700, 1260))      # one short line of "text"
    path = tmp_path / "02-place.png"
    image.save(path)
    assert any("looks blank" in p for p in cs.check_image(path, "02-place"))


def test_wrong_size_is_flagged(tmp_path):
    path = tmp_path / "02-place.png"
    noise((1179, 2556)).save(path)
    assert any("size" in p for p in cs.check_image(path, "02-place"))


def test_missing_file_is_flagged(tmp_path):
    assert cs.check_image(tmp_path / "nope.png", "02-place") == [f"{tmp_path / 'nope.png'}: missing"]


def test_satellite_screen_with_flat_top_is_flagged(tmp_path):
    image = noise()
    width, height = SIZE
    image.paste((210, 210, 205), (0, 0, width, int(height * 0.5)))   # unloaded map: flat gray
    path = tmp_path / "01-explore.png"
    image.save(path)
    assert any("map tiles" in p for p in cs.check_image(path, "01-explore"))


def test_satellite_screen_with_texture_passes(tmp_path):
    path = tmp_path / "01-explore.png"
    noise().save(path)
    assert cs.check_image(path, "01-explore") == []


def test_main_checks_light_and_dark_for_each_slug(tmp_path, capsys):
    screens = tmp_path / "screens.txt"
    screens.write_text("01-explore\n02-place\n")
    for appearance in ("light", "dark"):
        (tmp_path / appearance).mkdir()
        noise().save(tmp_path / appearance / "02-place.png")

    code = cs.main([str(tmp_path), "--screens", str(screens), "--only", "02-place"])

    assert code == 0
    assert "checked 2 screenshot(s), 0 problem(s)" in capsys.readouterr().out


def test_main_fails_on_missing_screens(tmp_path):
    screens = tmp_path / "screens.txt"
    screens.write_text("01-explore\n")
    assert cs.main([str(tmp_path), "--screens", str(screens)]) == 1
