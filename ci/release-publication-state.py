#!/usr/bin/env python3
"""Choose safe release publication recovery from immutable config digests."""

from __future__ import annotations

import argparse
import re
import sys


SHA256 = re.compile(r"^sha256:[0-9a-f]{64}$")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--existing-config-digest", required=True)
    parser.add_argument("--candidate-config-digest", required=True)
    args = parser.parse_args()
    try:
        if SHA256.fullmatch(args.candidate_config_digest) is None:
            raise ValueError("candidate config digest must be sha256")
        if args.existing_config_digest == "absent":
            print("publish")
            return 0
        if SHA256.fullmatch(args.existing_config_digest) is None:
            raise ValueError("existing config digest must be sha256 or absent")
        if args.existing_config_digest != args.candidate_config_digest:
            raise ValueError("existing immutable release does not match the tested candidate configuration digest")
        print("resume")
        return 0
    except ValueError as exc:
        print(f"ERROR: unsafe release recovery: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
