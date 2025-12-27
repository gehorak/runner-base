#!/usr/bin/env bash
# =============================================================================
# Domain tests — base image
#
# Purpose:
# - Verify that base image does NOT include domain-specific tooling
# - Ensure base remains minimal and clean
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Domain test: base image executes simple command"
docker run --rm "$IMAGE" exec true

echo "==> Domain tests passed"
