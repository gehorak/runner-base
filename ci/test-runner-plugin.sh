#!/usr/bin/env bash
# =============================================================================
# Runner plugin tests — base image
#
# Purpose:
# - Verify that the plugin mechanism exists
# - Verify that the base image contains NO domain-specific plugins
#
# These tests protect the minimalism of runner-base.
# They MUST pass in the base image.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Runner plugin tests for image: ${IMAGE}"
echo


# -----------------------------------------------------------------------------
# Test 1: Plugin directory exists
#
# Verifies:
# - plugin mechanism is present
# - expected directory structure exists
# -----------------------------------------------------------------------------

echo "==> Plugins: plugin directory exists"
docker run --rm "${IMAGE}" exec test -d /usr/local/lib/runner.d


# -----------------------------------------------------------------------------
# Test 2: No plugins present in base image
#
# Verifies:
# - base image is free of domain-specific plugins
# - plugin directory is empty
# -----------------------------------------------------------------------------

echo "==> Plugins: no plugins present in base image"
docker run --rm "${IMAGE}" exec sh -c '[ -z "$(ls -A /usr/local/lib/runner.d)" ]'


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Runner plugin tests passed"
