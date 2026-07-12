#!/usr/bin/env python3
"""Write the tag-bound runtime manifest used by a release build."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


TAG = re.compile(r"^v([0-9]+\.[0-9]+\.[0-9]+)$")
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
REQUIRED_KEYS = ("RUNNER_VERSION", "RUNNER_IMAGE_VERSION", "RUNNER_IMAGE_REVISION")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a release manifest bound to a SemVer tag and commit SHA."
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--revision", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    match = TAG.fullmatch(args.tag)
    if match is None:
        print("ERROR: tag must be strict SemVer in the form vMAJOR.MINOR.PATCH", file=sys.stderr)
        return 1
    if GIT_SHA.fullmatch(args.revision) is None:
        print("ERROR: revision must be a lowercase 40-character Git SHA", file=sys.stderr)
        return 1

    version = match.group(1)
    replacements = {
        "RUNNER_VERSION": version,
        "RUNNER_IMAGE_VERSION": version,
        "RUNNER_IMAGE_REVISION": args.revision,
    }
    seen: set[str] = set()
    output_lines: list[str] = []
    try:
        for line in args.input.read_text(encoding="utf-8").splitlines():
            key, separator, _value = line.partition("=")
            if separator and key in replacements:
                if key in seen:
                    raise ValueError(f"duplicate {key} in {args.input}")
                seen.add(key)
                output_lines.append(f"{key}={replacements[key]}")
            else:
                output_lines.append(line)
    except (OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    missing = [key for key in REQUIRED_KEYS if key not in seen]
    if missing:
        print(f"ERROR: input manifest is missing {', '.join(missing)}", file=sys.stderr)
        return 1

    try:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text("\n".join(output_lines) + "\n", encoding="utf-8")
    except OSError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
