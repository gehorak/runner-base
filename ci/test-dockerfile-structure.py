#!/usr/bin/env python3
"""Check Dockerfile invariants that are unsafe to leave to review alone."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    dockerfile = (root / "Dockerfile").read_text(encoding="utf-8")
    require(
        re.search(r"^FROM debian:bookworm-slim@sha256:[0-9a-f]{64}$", dockerfile, re.MULTILINE)
        is not None,
        "Dockerfile must pin the Debian base image by digest",
    )
    require("SHELL [\"/bin/bash\", \"-Eeuo\", \"pipefail\", \"-c\"]" in dockerfile, "Dockerfile must use fail-fast Bash")
    require("COPY image.manifest /tmp/image.manifest" in dockerfile, "Dockerfile must materialize the declared manifest")
    require("USER runner" in dockerfile, "Dockerfile must end with the declared non-root user")
    require(re.search(r"^ADD\\s", dockerfile, re.MULTILINE) is None, "Dockerfile must not use ADD")
    require(re.search(r"^ARG RUNTIME_", dockerfile, re.MULTILINE) is None, "runtime identity must not be a Docker build argument")
    print("==> Dockerfile structure tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
