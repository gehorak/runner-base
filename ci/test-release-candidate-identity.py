#!/usr/bin/env python3
"""Exercise actual-image identity validation without publishing an image."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VALID = {
    "schema_version": 1,
    "runner": {"name": "runner", "version": "0.3.1", "contract_version": "v001"},
    "image": {"name": "runner-base", "version": "0.3.1", "revision": "0123456789abcdef0123456789abcdef01234567"},
    "runtime": {"platform": "linux", "architecture": "amd64"},
    "tools": [],
}


def invoke(path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(ROOT / "ci/validate-image-identity.py"), "--input", str(path), "--runner-version", "0.3.1", "--image-version", "0.3.1", "--image-revision", VALID["image"]["revision"]],
        text=True,
        capture_output=True,
        check=False,
    )


with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "identity.json"
    path.write_text(json.dumps(VALID), encoding="utf-8")
    assert invoke(path).returncode == 0
    for field, value in (("version", "0.3.2"), ("revision", "local")):
        invalid = json.loads(json.dumps(VALID))
        invalid["image"][field] = value
        path.write_text(json.dumps(invalid), encoding="utf-8")
        assert invoke(path).returncode == 1

print("==> Release candidate identity tests passed")
