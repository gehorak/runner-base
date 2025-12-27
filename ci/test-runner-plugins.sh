#!/usr/bin/env bash
# =============================================================================
# Runner plugin tests — base image
#
# Purpose:
# - Verify plugin system exists
# - Verify base image has no domain plugins
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Runner plugins: no plugins expected"
docker run --rm "$IMAGE" info | grep -q "(none)"

echo "==> Runner plugin tests passed"
