#!/usr/bin/env bash
# =============================================================================
# Negative tests
#
# Purpose:
# - Ensure forbidden behaviors remain forbidden
# - Protect explicit execution model
#
# These tests must pass in ALL images.
# =============================================================================

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Negative test: implicit command execution must fail"

if docker run --rm "$IMAGE" ls >/dev/null 2>&1; then
  echo "ERROR: implicit command execution succeeded"
  exit 1
else
  echo "OK: implicit command execution failed as expected"
fi

echo "==> Negative test: unknown runner command must fail"

if docker run --rm "$IMAGE" unknown >/dev/null 2>&1; then
  echo "ERROR: unknown runner command succeeded"
  exit 1
else
  echo "OK: unknown runner command failed as expected"
fi

echo "==> Negative tests passed"
