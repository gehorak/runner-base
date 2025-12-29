#!/usr/bin/env bash
# =============================================================================
# Smoke tests — runner images
#
# Purpose:
# - Verify that the image starts correctly
# - Verify the runner entrypoint is functional
# - Verify non-root execution
# - Provide a fast sanity check for local development and CI
#
# These tests are intentionally shallow but high-signal.
# They MUST pass in ALL runner images.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Smoke tests for image: ${IMAGE}"
echo


# -----------------------------------------------------------------------------
# Test 1: Image starts and runner responds
#
# Verifies:
# - ENTRYPOINT is correctly set to 'runner'
# - 'info' command executes successfully
# -----------------------------------------------------------------------------

echo "==> Smoke: runner info responds"
docker run --rm "${IMAGE}" info >/dev/null


# -----------------------------------------------------------------------------
# Test 2: Non-root execution
#
# Verifies:
# - container does NOT run as root
# - runtime user is correctly configured
#
# NOTE:
# - The exact username is part of the base image contract
# -----------------------------------------------------------------------------

echo "==> Smoke: non-root execution (whoami)"
docker run --rm "${IMAGE}" exec whoami | grep -qx 'runner'


# -----------------------------------------------------------------------------
# Test 3: Explicit system command execution
#
# Verifies:
# - 'exec' escape hatch works
# - shell-based commands can be executed explicitly
# -----------------------------------------------------------------------------

echo "==> Smoke: explicit exec works"
docker run --rm "${IMAGE}" exec bash -c 'echo exec-ok' | grep -qx 'exec-ok'


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Smoke tests passed"
