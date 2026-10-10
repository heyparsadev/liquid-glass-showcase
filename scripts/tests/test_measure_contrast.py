import json
from pathlib import Path

import pytest
from PIL import Image

import measure_contrast as mc


def screenshot_with_text(background, text, box=(100, 100, 400, 160)):
    image = Image.new("RGB", mc.EXPECTED_SIZE, background)
    # a few strokes of "text" inside the box
    for x in range(box[0] + 20, box[2] - 20, 40):
        image.paste(text, (x, box[1] + 15, x + 12, box[3] - 15))
    return image


def write_boxes(tmp_path, kind, slug="02-place"):
    path = tmp_path / "boxes.json"
    path.write_text(json.dumps({slug: [{"name": "label", "box": [100, 100, 400, 160], "kind": kind}]}))
    return path


def save_both(tmp_path, image, slug="02-place"):
    for appearance in ("light", "dark"):
        (tmp_path / appearance).mkdir(exist_ok=True)
        image.save(tmp_path / appearance / f"{slug}.png")


def test_black_on_white_measures_21():
    ratio, text, background = mc.measure(screenshot_with_text((255, 255, 255), (0, 0, 0)), (100, 100, 400, 160))
    assert round(ratio, 1) == 21.0
    assert text == (0, 0, 0) and background == (255, 255, 255)


def test_white_on_black_measures_21_too():
    ratio, _, _ = mc.measure(screenshot_with_text((0, 0, 0), (255, 255, 255)), (100, 100, 400, 160))
    assert round(ratio, 1) == 21.0


def test_text_below_4_5_fails_the_gate(tmp_path, capsys):
    save_both(tmp_path, screenshot_with_text((255, 255, 255), (150, 150, 150)))        # about 3:1
    code = mc.main([str(tmp_path), "--boxes", str(write_boxes(tmp_path, "text"))])
    assert code == 1
    assert "below 4.5" in capsys.readouterr().err


def test_an_icon_only_needs_3(tmp_path):
    save_both(tmp_path, screenshot_with_text((255, 255, 255), (140, 140, 140)))        # about 3.4:1, under 4.5
    assert mc.main([str(tmp_path), "--boxes", str(write_boxes(tmp_path, "icon"))]) == 0


@pytest.mark.parametrize("kind", ["system", "decorative"])
def test_system_and_decorative_boxes_are_reported_not_gated(tmp_path, kind, capsys):
    save_both(tmp_path, screenshot_with_text((255, 255, 255), (200, 200, 200)))        # about 1.7:1
    code = mc.main([str(tmp_path), "--boxes", str(write_boxes(tmp_path, kind))])
    assert code == 0
    assert kind in capsys.readouterr().out


def test_a_missing_screenshot_is_an_error(tmp_path, capsys):
    code = mc.main([str(tmp_path), "--boxes", str(write_boxes(tmp_path, "text"))])
    assert code == 1
    assert "missing" in capsys.readouterr().err


def test_only_limits_the_screens(tmp_path):
    save_both(tmp_path, screenshot_with_text((255, 255, 255), (150, 150, 150)), slug="02-place")
    boxes = tmp_path / "boxes.json"
    boxes.write_text(json.dumps({
        "02-place": [{"name": "label", "box": [100, 100, 400, 160], "kind": "text"}],
        "03-discover": [{"name": "label", "box": [100, 100, 400, 160], "kind": "text"}],
    }))
    # 03-discover has no screenshot, but --only skips it; 02-place fails on contrast
    assert mc.main([str(tmp_path), "--boxes", str(boxes), "--only", "03-discover"]) == 1
    assert mc.main([str(tmp_path), "--boxes", str(boxes), "--only", "02-place"]) == 1


def test_an_unknown_kind_is_an_error_not_a_silent_pass(tmp_path, capsys):
    code = mc.main([str(tmp_path), "--boxes", str(write_boxes(tmp_path, "txt"))])
    assert code == 2
    assert "kind" in capsys.readouterr().err


@pytest.mark.parametrize("box", [[0, 0, 10], [10, 10, 10, 20], [0, 0, 1207, 100], [0, 0, 10.5, 20], [-1, 0, 10, 10]])
def test_a_malformed_or_out_of_range_box_is_an_error(tmp_path, box, capsys):
    path = tmp_path / "boxes.json"
    path.write_text(json.dumps({"02-place": [{"name": "label", "kind": "text", "box": box}]}))
    assert mc.main([str(tmp_path), "--boxes", str(path)]) == 2
    assert "box" in capsys.readouterr().err


def test_a_missing_boxes_file_is_an_error(tmp_path):
    assert mc.main([str(tmp_path), "--boxes", str(tmp_path / "nope.json")]) == 2


def test_the_committed_boxes_are_valid_and_cover_every_screen():
    boxes = mc.load_boxes(mc.DEFAULT_BOXES)
    screens = Path(mc.__file__).with_name("screens.txt").read_text().split()
    assert sorted(boxes) == sorted(screens)
    assert all(boxes[slug] for slug in screens)
