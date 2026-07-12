#!/usr/bin/env python3
"""Exercise safe new-publication and resumable-release decisions."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "ci" / "release-publication-state.py"
CANDIDATE = "sha256:" + "a" * 64


def run(existing: str, expected: int, output: str = "") -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--existing-config-digest", existing, "--candidate-config-digest", CANDIDATE],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == expected
    if output:
        assert result.stdout.strip() == output


run("absent", 0, "publish")
run(CANDIDATE, 0, "resume")
run("sha256:" + "b" * 64, 1)
run("not-a-digest", 1)
print("==> Release publication recovery tests passed")
