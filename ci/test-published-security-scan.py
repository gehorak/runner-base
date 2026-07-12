#!/usr/bin/env python3
"""Keep the published-image scan digest-pinned and independently scheduled."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "published-security-scan.yml").read_text(encoding="utf-8")

assert "schedule:" in workflow
assert "workflow_dispatch:" in workflow
assert "releases/latest" in workflow
assert "tag=\"$(gh api" in workflow
assert "docker buildx imagetools inspect --raw" in workflow
assert 'image "${REFERENCE}@${DIGEST}"' in workflow
assert "aquasec/trivy@sha256:" in workflow
assert "--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1" in workflow

print("==> Published security scan workflow tests passed")
