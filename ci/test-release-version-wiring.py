#!/usr/bin/env python3
"""Ensure release metadata and tests follow the tag-built image contract."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")
step_start = workflow.index("- name: Run complete base-owned test suite on the built release image")
step_end = workflow.index("- name: Scan exact tested release candidate", step_start)
step = workflow[step_start:step_end]

assert "IMAGE: runner-release:test" in step
assert "EXPECTED_RUNNER_VERSION: ${{ steps.semver.outputs.version }}" in step
assert "EXPECTED_IMAGE_VERSION: ${{ steps.semver.outputs.version }}" in step

parent_start = workflow.index("- name: Read pinned base image metadata")
parent_end = workflow.index("- name: Define Docker image metadata", parent_start)
parent = workflow[parent_start:parent_end]
assert "python3 ci/parent-reference.py --field reference" in parent
assert "python3 ci/parent-reference.py --field digest" in parent
assert "echo \"reference=${reference}\"" in parent
assert "echo \"digest=${digest}\"" in parent

metadata_start = workflow.index("- name: Define Docker image metadata")
metadata_end = workflow.index("- name: Log in to GitHub Container Registry", metadata_start)
metadata = workflow[metadata_start:metadata_end]
assert "org.opencontainers.image.base.name=${{ steps.parent.outputs.name }}" in metadata
assert "org.opencontainers.image.base.digest=${{ steps.parent.outputs.digest }}" in metadata

evidence_start = workflow.index("- name: Write and validate release evidence")
evidence_end = workflow.index("- name: Publish release evidence assets", evidence_start)
evidence = workflow[evidence_start:evidence_end]
assert "RUNNER_RELEASE_PARENT_REFERENCE: ${{ steps.parent.outputs.reference }}" in evidence
assert "RUNNER_RELEASE_PARENT_DIGEST: ${{ steps.parent.outputs.digest }}" in evidence

print("==> Release workflow wiring tests passed")
