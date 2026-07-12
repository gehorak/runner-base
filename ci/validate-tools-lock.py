#!/usr/bin/env python3
"""Validate the dependency-free v001 derived tool-integrity lock."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


NAME = re.compile(r"^[a-z][a-z0-9-]*$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate(document: Any) -> list[str]:
    require(isinstance(document, dict), "tools lock root must be an object")
    require(set(document) == {"schema_version", "tools"}, "tools lock has unsupported keys")
    require(document.get("schema_version") == 1, "schema_version must be 1")
    tools = document.get("tools")
    require(isinstance(tools, list), "tools must be an array")
    names: list[str] = []
    for index, tool in enumerate(tools):
        require(isinstance(tool, dict), f"tools[{index}] must be an object")
        require(set(tool) == {"name", "version", "source", "sha256"}, f"tools[{index}] has unsupported or missing keys")
        name = tool["name"]
        version = tool["version"]
        source = tool["source"]
        sha256 = tool["sha256"]
        require(isinstance(name, str) and NAME.fullmatch(name) is not None, f"tools[{index}].name is invalid")
        require(isinstance(version, str) and version, f"tools[{index}].version must be non-empty")
        require(isinstance(source, str) and source.startswith("https://"), f"tools[{index}].source must use HTTPS")
        require(isinstance(sha256, str) and SHA256.fullmatch(sha256) is not None, f"tools[{index}].sha256 is invalid")
        names.append(name)
    require(names == sorted(names), "tools must be sorted lexically by name")
    require(len(names) == len(set(names)), "tools must not contain duplicate names")
    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("tools_lock", type=Path)
    args = parser.parse_args()
    try:
        names = validate(json.loads(args.tools_lock.read_text(encoding="utf-8")))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: invalid tools lock: {exc}", file=sys.stderr)
        return 1
    print(f"OK: tools lock is valid: {args.tools_lock} ({', '.join(names) or 'no tools'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
