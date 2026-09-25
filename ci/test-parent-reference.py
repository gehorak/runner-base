#!/usr/bin/env python3
"""Check that the Dockerfile parent parser rejects label drift."""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = (ROOT / "Dockerfile").read_text(encoding="utf-8")


def parent_digest() -> str:
    result = subprocess.run(
        [sys.executable, str(ROOT / "ci/parent-reference.py"), "--field", "digest"],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    return result.stdout.strip()


with tempfile.TemporaryDirectory() as directory:
    dockerfile = Path(directory) / "Dockerfile"
    dockerfile.write_text(SOURCE, encoding="utf-8")
    assert subprocess.run([sys.executable, str(ROOT / "ci/parent-reference.py"), "--dockerfile", str(dockerfile), "--field", "reference"], check=False).returncode == 0
    digest = parent_digest()
    dockerfile.write_text(SOURCE.replace(f'org.opencontainers.image.base.digest="{digest}"', 'org.opencontainers.image.base.digest="sha256:0000000000000000000000000000000000000000000000000000000000000000"', 1), encoding="utf-8")
    assert subprocess.run([sys.executable, str(ROOT / "ci/parent-reference.py"), "--dockerfile", str(dockerfile), "--field", "reference"], check=False).returncode == 1

print("==> Parent reference consistency tests passed")
