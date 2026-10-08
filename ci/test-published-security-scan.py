#!/usr/bin/env python3
"""Keep the published-image scan digest-pinned and independently scheduled."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "published-security-scan.yml").read_text(encoding="utf-8")

assert "schedule:" in workflow
assert "workflow_dispatch:" in workflow
assert "releases/latest" in workflow
assert "tag=\"$(gh api" in workflow
assert "docker buildx imagetools inspect --raw" in workflow
assert 'image "${REFERENCE}@${DIGEST}"' in workflow
scanner = "aquasec/trivy:0.71.0@sha256:016eae51fdcf989332a5404af7e8f625cd5d95d7c0907a221d080a996f556500"
for name in ("ci.yml", "release.yml", "published-security-scan.yml"):
    source = (ROOT / ".github" / "workflows" / name).read_text(encoding="utf-8")
    assert source.count(scanner) == 1, f"scanner pin drift in {name}"
    assert "--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1" in source

assert "security-events: write" in workflow
assert '--volume "${PWD}:/work"' in workflow
assert "--format sarif --output /work/trivy.sarif" in workflow
upload = workflow[workflow.index("- name: Publish vulnerability report"):]
assert "if: ${{ !cancelled() && hashFiles('trivy.sarif') != '' }}" in upload
assert re.search(r"github/codeql-action/upload-sarif@[0-9a-f]{40} ", upload)
assert "sarif_file: trivy.sarif" in upload
assert "category: trivy-published-image" in upload
assert "continue-on-error:" not in workflow
assert "--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1" in workflow

print("==> Published security scan workflow tests passed")
