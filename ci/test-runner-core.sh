#!/usr/bin/env bash
# =============================================================================
# Runner core contract tests
#
# Purpose:
# - Verify the stable runner interface (CORE)
# - Protect backward compatibility
#
# These tests MUST pass in all images.
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Runner core: help"
docker run --rm "$IMAGE" help >/dev/null

echo "==> Runner core: about"
docker run --rm "$IMAGE" about >/dev/null

echo "==> Runner core: info"
docker run --rm "$IMAGE" info >/dev/null

echo "==> Runner core: exec"
docker run --rm "$IMAGE" exec true

echo "==> Runner core: version"
docker run --rm "$IMAGE" version >/dev/null

echo "==> Runner core tests passed"
