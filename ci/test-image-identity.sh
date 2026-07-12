#!/usr/bin/env bash
# =============================================================================
# Image identity tests — runner images
#
# Purpose:
# - Verify that image identity is present and accessible
# - Verify that identity is exposed via stable runner commands
# - Protect the image identity contract
#
# These tests MUST pass in ALL runner images.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Image identity tests for image: ${IMAGE}"
echo

# -----------------------------------------------------------------------------
# Test 1: image.env exists and is non-empty
#
# Verifies:
# - runtime identity has been materialized
# - identity files are present at runtime
# -----------------------------------------------------------------------------

echo "==> Identity: /etc/runner/image.env exists and is non-empty"
docker run --rm "${IMAGE}" exec -- sh -c 'test -s /etc/runner/image.env'

# -----------------------------------------------------------------------------
# Test 2: image.env contains required keys
#
# Verifies:
# - basic identity fields are present
# - image identity follows the expected contract
# -----------------------------------------------------------------------------

echo "==> Identity: required keys present in image.env"
docker run --rm "${IMAGE}" exec -- sh -c "grep -q '^RUNNER_IMAGE=' /etc/runner/image.env"
docker run --rm "${IMAGE}" exec -- sh -c "grep -q '^RUNNER_DOMAIN=' /etc/runner/image.env"
docker run --rm "${IMAGE}" exec -- sh -c "grep -q '^RUNNER_ROLE=' /etc/runner/image.env"

# -----------------------------------------------------------------------------
# Test 3: identity is exposed via canonical info
#
# Verifies:
# - runner 'about' command exposes image identity
# - human-facing identity is available
#
# NOTE:
# - Output is captured first to avoid SIGPIPE issues
# - Tests MUST be compatible with `set -o pipefail`
# -----------------------------------------------------------------------------

echo "==> Identity: runner info exposes identity"

about_output="$(docker run --rm "${IMAGE}" info --format text)"

# Stable contract markers
echo "${about_output}" | grep -q '^Image:'
echo "${about_output}" | grep -q '^Domain:'
echo "${about_output}" | grep -q '^Role:'

# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Image identity tests passed"
