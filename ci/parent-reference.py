#!/usr/bin/env python3
"""Read and cross-check the pinned Debian parent from the Dockerfile."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


PARENT = re.compile(r"^FROM (debian:bookworm-slim@sha256:([0-9a-f]{64}))$", re.MULTILINE)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dockerfile", type=Path, default=Path("Dockerfile"))
    parser.add_argument("--field", choices=("reference", "digest"), required=True)
    args = parser.parse_args()
    try:
        text = args.dockerfile.read_text(encoding="utf-8")
        match = PARENT.search(text)
        if match is None:
            raise ValueError("missing pinned Debian FROM reference")
        reference, digest = match.groups()
        if f'org.opencontainers.image.base.name="debian:bookworm-slim"' not in text or f'org.opencontainers.image.base.digest="sha256:{digest}"' not in text:
            raise ValueError("OCI base labels do not match the pinned FROM reference")
    except (OSError, ValueError) as exc:
        print(f"ERROR: parent reference validation failed: {exc}", file=sys.stderr)
        return 1
    print(reference if args.field == "reference" else f"sha256:{digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
