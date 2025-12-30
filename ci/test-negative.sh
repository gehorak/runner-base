#!/usr/bin/env bash
# =============================================================================
# Negative tests — runner images
#
# Purpose:
# - Ensure forbidden behaviors remain forbidden
# - Protect the explicit execution model
# - Prevent accidental or implicit command execution
#
# These tests assert that invalid usage FAILS explicitly.
# They MUST pass in ALL runner images.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Negative tests for image: ${IMAGE}"
echo


# -----------------------------------------------------------------------------
# Test 1: Implicit system command execution must fail
#
# Verifies:
# - system commands are NOT executed implicitly
# - 'exec' is the only allowed escape hatch
# -----------------------------------------------------------------------------

echo "==> Negative: implicit system command must fail"

if docker run --rm "${IMAGE}" ls >/dev/null 2>&1; then
  echo "ERROR: implicit system command execution succeeded"
  exit 1
fi

echo "OK: implicit system command execution failed as expected"


# -----------------------------------------------------------------------------
# Test 2: Unknown runner command must fail
#
# Verifies:
# - unknown runner commands are rejected
# - runner does not guess or forward commands
# -----------------------------------------------------------------------------

echo "==> Negative: unknown runner command must fail"

if docker run --rm "${IMAGE}" unknown >/dev/null 2>&1; then
  echo "ERROR: unknown runner command succeeded"
  exit 1
fi

echo "OK: unknown runner command failed as expected"


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Negative tests passed"
exit 0