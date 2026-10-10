import sys
from pathlib import Path

import pytest

# Let tests import the single-file scripts in scripts/.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


@pytest.fixture(autouse=True)
def run_in_an_empty_directory(tmp_path, monkeypatch):
    """The scripts' defaults are relative to the repo root (photos/sources.json, CREDITS.md, ...).
    Run every test from an empty directory so it never reads or writes the real ones."""
    monkeypatch.chdir(tmp_path)
