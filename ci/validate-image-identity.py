#!/usr/bin/env python3
"""Validate the actual JSON identity emitted by a Runner candidate image."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--image")
    source.add_argument("--input", type=Path)
    parser.add_argument("--runner-version", required=True)
    parser.add_argument("--image-version", required=True)
    parser.add_argument("--image-revision", required=True)
    parser.add_argument("--image-name", default="runner-base")
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def load_identity(args: argparse.Namespace) -> dict:
    if args.input:
        return json.loads(args.input.read_text(encoding="utf-8"))
    result = subprocess.run(
        ["docker", "run", "--rm", args.image, "info", "--format", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def require(value: object, expected: object, label: str) -> None:
    if value != expected:
        raise ValueError(f"{label} expected {expected!r}, got {value!r}")


def main() -> int:
    args = parse_args()
    try:
        value = load_identity(args)
        require(value.get("schema_version"), 1, "schema_version")
        runner = value.get("runner")
        image = value.get("image")
        runtime = value.get("runtime")
        if not isinstance(runner, dict) or not isinstance(image, dict) or not isinstance(runtime, dict):
            raise ValueError("identity must contain runner, image, and runtime objects")
        require(runner.get("name"), "runner", "runner.name")
        require(runner.get("version"), args.runner_version, "runner.version")
        require(runner.get("contract_version"), "v001", "runner.contract_version")
        require(image.get("name"), args.image_name, "image.name")
        require(image.get("version"), args.image_version, "image.version")
        require(image.get("revision"), args.image_revision, "image.revision")
        require(runtime.get("platform"), "linux", "runtime.platform")
        require(runtime.get("architecture"), "amd64", "runtime.architecture")
        if args.output:
            args.output.write_text(json.dumps(value, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: candidate image identity validation failed: {exc}", file=sys.stderr)
        return 1
    print("OK: candidate image identity matches release expectations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
