#!/usr/bin/env bash
# =============================================================================
# Runner declarative tool-registry tests — base image
#
# Purpose:
# - Verify the base-owned declarative tool registry
# - Verify that the base image contains NO domain-specific tools
#
# These tests protect the minimalism of runner-base.
# They MUST pass in the base image.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Runner tool-registry tests for image: ${IMAGE}"
echo

# -----------------------------------------------------------------------------
# Test 1: Registry is materialized as metadata
#
# Verifies:
# - no executable directory discovery is required
# - the base registry is explicitly declared as empty
# -----------------------------------------------------------------------------

echo "==> Tools: declarative registry is empty in the base image"
docker run --rm "${IMAGE}" tool --format json | grep -Fx '{"schema_version":1,"tools":[]}' >/dev/null

# -----------------------------------------------------------------------------
# Test 2: No runtime discovery directory is exposed
#
# Verifies:
# - base image is free of domain-specific tools
# - `/usr/local/lib/runner.d` is not a public extension mechanism
# -----------------------------------------------------------------------------

echo "==> Tools: no runtime discovery directory"
docker run --rm "${IMAGE}" exec -- sh -c 'test ! -e /usr/local/lib/runner.d'

# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Runner tool-registry tests passed"
