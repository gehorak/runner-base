#!/usr/bin/env python3
"""Keep the release workflow wired to the tested recovery decision helper."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")

assert "Inspect immutable release recovery state" in workflow
assert "ci/release-publication-state.py" in workflow
assert "Publish or resume immutable tested image" in workflow
assert "Publish convenience aliases after immutable evidence" in workflow
assert workflow.index("Publish convenience aliases after immutable evidence") > workflow.index("Publish release evidence assets")
assert 'for alias in "${VERSION_MM}" latest' in workflow

print("==> Release workflow recovery wiring tests passed")
