#!/usr/bin/env bash
# =============================================================================
# Image identity tests
#
# These tests must pass in ALL images.
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Image identity: image.env exists"
docker run --rm "$IMAGE" exec test -f /etc/runner/image.env

echo "==> Image identity: about output"
docker run --rm "$IMAGE" about | grep -q "Image:"
docker run --rm "$IMAGE" about | grep -q "Domain:"

echo "==> Image identity tests passed"
