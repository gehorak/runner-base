#!/usr/bin/env python3
"""Validate the deterministic subset used by runner-base release evidence."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


SHA256 = re.compile(r"^sha256:[0-9a-f]{64}$")
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
TAG = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")
PUBLISHED_REFERENCE = re.compile(r"^ghcr\.io/gehorak/runner-base:[0-9]+\.[0-9]+\.[0-9]+$")
PARENT_REFERENCE = re.compile(r"^debian:bookworm-slim@sha256:[0-9a-f]{64}$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def string_at(document: dict[str, Any], *path: str) -> str:
    current: Any = document
    for key in path:
        require(isinstance(current, dict) and key in current, f"missing {'.'.join(path)}")
        current = current[key]
    require(isinstance(current, str) and current, f"{'.'.join(path)} must be a non-empty string")
    return current


def validate(document: dict[str, Any]) -> None:
    require(document.get("schema_version") == 1, "schema_version must be 1")
    require(document.get("project") == "runner-base", "project must be runner-base")
    require(GIT_SHA.fullmatch(string_at(document, "source", "commit")) is not None, "source.commit must be a full SHA")
    source_tag = string_at(document, "source", "tag")
    require(TAG.fullmatch(source_tag) is not None, "source.tag must be SemVer")
    require(string_at(document, "source", "repository") == "gehorak/runner-base", "unexpected source.repository")
    require(string_at(document, "image", "candidate_reference") == "runner-release:test", "unexpected candidate reference")
    require(SHA256.fullmatch(string_at(document, "image", "candidate_image_id")) is not None, "candidate image ID must be sha256")
    published_reference = string_at(document, "image", "published_reference")
    require(PUBLISHED_REFERENCE.fullmatch(published_reference) is not None, "published reference must be the release SemVer reference")
    require(published_reference.endswith(f":{source_tag[1:]}"), "published reference must match source.tag")
    require(SHA256.fullmatch(string_at(document, "image", "published_digest")) is not None, "published digest must be sha256")
    require(PARENT_REFERENCE.fullmatch(string_at(document, "image", "parent_reference")) is not None, "parent reference must be the pinned Debian base")
    require(SHA256.fullmatch(string_at(document, "image", "parent_digest")) is not None, "parent digest must be sha256")
    require(string_at(document, "contract", "runner_contract_version") == "v001", "unexpected runner contract version")
    require(string_at(document, "contract", "cli_contract_track") == "compatibility-bridge-v0.3", "unexpected CLI contract track")
    require(document.get("platform") == "linux/amd64", "platform must be linux/amd64")
    require(isinstance(document.get("tests"), list) and document["tests"], "tests must be a non-empty list")
    for test in document["tests"]:
        require(isinstance(test, str) and test, "test names must be non-empty strings")
    require(string_at(document, "artifacts", "sbom_reference").endswith(".spdx.json"), "SBOM reference must be an SPDX JSON asset")
    require(string_at(document, "artifacts", "provenance_reference").startswith("https://github.com/"), "provenance reference must be a GitHub URL")
    require(string_at(document, "release_decision", "status") == "published", "release status must be published")
    require(string_at(document, "release_decision", "decided_by") == "release-tag", "release decision must be release-tag")
    require(PUBLISHED_REFERENCE.fullmatch(string_at(document, "rollback_reference", "previous_reference")) is not None, "rollback reference must be a release SemVer reference")
    require(SHA256.fullmatch(string_at(document, "rollback_reference", "previous_digest")) is not None, "rollback digest must be sha256")
    string_at(document, "rollback_reference", "previous_reference")
    string_at(document, "rollback_reference", "notes")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-release-evidence.py <release-evidence.json>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
        require(isinstance(document, dict), "evidence root must be an object")
        validate(document)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(f"OK: release evidence is valid: {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
