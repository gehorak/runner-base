#!/usr/bin/env python3
"""Exercise the versioned derived tool-integrity lock contract."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VALIDATOR = ROOT / "ci" / "validate-tools-lock.py"
TEMPLATE = ROOT / "contracts" / "tools-lock" / "v001" / "template.json"


def validate(path: Path, expected: int) -> None:
    result = subprocess.run([sys.executable, str(VALIDATOR), str(path)], check=False)
    assert result.returncode == expected


with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "tools.lock.json"
    document = json.loads(TEMPLATE.read_text(encoding="utf-8"))
    path.write_text(json.dumps(document), encoding="utf-8")
    validate(path, 0)

    del document["tools"][0]["sha256"]
    path.write_text(json.dumps(document), encoding="utf-8")
    validate(path, 1)

    document = json.loads(TEMPLATE.read_text(encoding="utf-8"))
    document["tools"].append({"name": "aaa-tool", "version": "1", "source": "https://example.invalid/aaa", "sha256": "1" * 64})
    path.write_text(json.dumps(document), encoding="utf-8")
    validate(path, 1)

print("==> Tool lock contract tests passed")
