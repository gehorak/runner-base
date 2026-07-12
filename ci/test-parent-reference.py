#!/usr/bin/env python3
"""Check that the Dockerfile parent parser rejects label drift."""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = (ROOT / "Dockerfile").read_text(encoding="utf-8")

with tempfile.TemporaryDirectory() as directory:
    dockerfile = Path(directory) / "Dockerfile"
    dockerfile.write_text(SOURCE, encoding="utf-8")
    assert subprocess.run([sys.executable, str(ROOT / "ci/parent-reference.py"), "--dockerfile", str(dockerfile), "--field", "reference"], check=False).returncode == 0
    dockerfile.write_text(SOURCE.replace('org.opencontainers.image.base.digest="sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df"', 'org.opencontainers.image.base.digest="sha256:0000000000000000000000000000000000000000000000000000000000000000"'), encoding="utf-8")
    assert subprocess.run([sys.executable, str(ROOT / "ci/parent-reference.py"), "--dockerfile", str(dockerfile), "--field", "reference"], check=False).returncode == 1

print("==> Parent reference consistency tests passed")
