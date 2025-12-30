#!/usr/bin/env bash
# =============================================================================
# Domain tests — runner image
#
# Purpose:
# - Verify domain-specific tooling provided by this image
# - Protect the declared domain contract (terraform, ansible, kubectl, …)
#
# This file is a TEMPLATE.
# Each domain image MUST define its own explicit tests here.
#
# The base image intentionally provides NO domain tests.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Domain tests for image: ${IMAGE}"
echo


# -----------------------------------------------------------------------------
# Domain-specific tests
#
# Add explicit tests for tools provided by this image.
#
# Examples (uncomment and adapt):
#
#   docker run --rm "${IMAGE}" exec terraform version
#   docker run --rm "${IMAGE}" exec ansible --version
#   docker run --rm "${IMAGE}" exec kubectl version --client
#
# Rules:
# - Tests MUST be explicit
# - Tests MUST NOT rely on implicit execution
# - Tests MUST validate behavior, not just existence
# -----------------------------------------------------------------------------

echo "==> Domain tests: no domain-specific tests defined"
echo "==> This is expected for images without domain tooling"


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Domain tests passed (no domain assertions)"
