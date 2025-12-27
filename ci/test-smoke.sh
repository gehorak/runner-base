#!/usr/bin/env bash
# =============================================================================
# Smoke tests
#
# Purpose:
# - Verify that the image starts correctly
# - Verify core runner commands work
# - Provide a fast sanity check for local development
#
# These tests must pass in ALL images.
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Smoke test: runner info"
docker run --rm "$IMAGE" info

echo "==> Smoke test: exec whoami (non-root check)"
docker run --rm "$IMAGE" exec whoami | grep -q '^iac$'

echo "==> Smoke test: shell availability (non-interactive)"
docker run --rm "$IMAGE" exec bash -c "echo shell-ok" | grep -q 'shell-ok'

echo "==> Smoke tests passed"
