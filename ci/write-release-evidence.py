#!/usr/bin/env python3
"""Write deterministic release evidence for a published runner-base image."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


REQUIRED = (
    "RUNNER_RELEASE_EVIDENCE_OUTPUT",
    "RUNNER_RELEASE_SOURCE_COMMIT",
    "RUNNER_RELEASE_TAG",
    "RUNNER_RELEASE_CANDIDATE_IMAGE_ID",
    "RUNNER_RELEASE_ACTUAL_IDENTITY_FILE",
    "RUNNER_RELEASE_PUBLISHED_REFERENCE",
    "RUNNER_RELEASE_PUBLISHED_DIGEST",
    "RUNNER_RELEASE_PARENT_REFERENCE",
    "RUNNER_RELEASE_PARENT_DIGEST",
    "RUNNER_RELEASE_SBOM_REFERENCE",
    "RUNNER_RELEASE_PROVENANCE_REFERENCE",
    "RUNNER_RELEASE_PREVIOUS_REFERENCE",
    "RUNNER_RELEASE_PREVIOUS_DIGEST",
)


def require(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise ValueError(f"missing required environment variable: {name}")
    return value


def main() -> int:
    try:
        values = {name: require(name) for name in REQUIRED}
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    try:
        actual_identity = json.loads(Path(values["RUNNER_RELEASE_ACTUAL_IDENTITY_FILE"]).read_text(encoding="utf-8"))
        runner = actual_identity["runner"]
        image = actual_identity["image"]
        runtime = actual_identity["runtime"]
        if runner != {"name": "runner", "version": values["RUNNER_RELEASE_TAG"][1:], "contract_version": "v001"}:
            raise ValueError("actual runner identity does not match release tag and contract")
        if image.get("name") != "runner-base" or image.get("version") != values["RUNNER_RELEASE_TAG"][1:] or image.get("revision") != values["RUNNER_RELEASE_SOURCE_COMMIT"]:
            raise ValueError("actual image identity does not match release source")
        if runtime.get("platform") != "linux" or runtime.get("architecture") != "amd64":
            raise ValueError("actual runtime platform is unsupported")
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: invalid RUNNER_RELEASE_ACTUAL_IDENTITY_FILE: {exc}", file=sys.stderr)
        return 1

    tests = [item for item in os.environ.get("RUNNER_RELEASE_TESTS", "").split(",") if item]
    if not tests:
        print("ERROR: RUNNER_RELEASE_TESTS must list at least one test", file=sys.stderr)
        return 1

    evidence = {
        "schema_version": 1,
        "project": "runner-base",
        "source": {
            "repository": "gehorak/runner-base",
            "commit": values["RUNNER_RELEASE_SOURCE_COMMIT"],
            "tag": values["RUNNER_RELEASE_TAG"],
        },
        "image": {
            "candidate_reference": "runner-release:test",
            "candidate_image_id": values["RUNNER_RELEASE_CANDIDATE_IMAGE_ID"],
            "manifest_version": image["version"],
            "manifest_revision": image["revision"],
            "published_reference": values["RUNNER_RELEASE_PUBLISHED_REFERENCE"],
            "published_digest": values["RUNNER_RELEASE_PUBLISHED_DIGEST"],
            "parent_reference": values["RUNNER_RELEASE_PARENT_REFERENCE"],
            "parent_digest": values["RUNNER_RELEASE_PARENT_DIGEST"],
        },
        "contract": {
            "runner_contract_version": "v001",
            "cli_contract_track": "compatibility-bridge-v0.3",
        },
        "platform": "linux/amd64",
        "tests": tests,
        "artifacts": {
            "sbom_reference": values["RUNNER_RELEASE_SBOM_REFERENCE"],
            "provenance_reference": values["RUNNER_RELEASE_PROVENANCE_REFERENCE"],
        },
        "release_decision": {
            "status": "published",
            "decided_by": "release-tag",
            "rationale": "A reviewed SemVer tag triggered the required release checks and publication workflow.",
        },
        "rollback_reference": {
            "previous_reference": values["RUNNER_RELEASE_PREVIOUS_REFERENCE"],
            "previous_digest": values["RUNNER_RELEASE_PREVIOUS_DIGEST"],
            "notes": "Rollback uses the recorded previous immutable digest; no published tag is replaced.",
        },
    }

    output = Path(values["RUNNER_RELEASE_EVIDENCE_OUTPUT"])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
