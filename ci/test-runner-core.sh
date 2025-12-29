#!/usr/bin/env bash
# =============================================================================
# Runner core contract tests
#
# Purpose:
# - Verify the stable runner CORE interface
# - Protect backward compatibility across all runner images
#
# These tests assert the existence and basic behavior
# of all core runner commands.
#
# These tests MUST pass in ALL runner images.
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Test configuration
# -----------------------------------------------------------------------------

IMAGE="${IMAGE:?IMAGE variable must be set}"

echo "==> Runner core contract tests for image: ${IMAGE}"
echo


# -----------------------------------------------------------------------------
# Core command: help
#
# Verifies:
# - command exists
# - command executes successfully
# -----------------------------------------------------------------------------

echo "==> Core: help"
docker run --rm "${IMAGE}" help >/dev/null


# -----------------------------------------------------------------------------
# Core command: about
#
# Verifies:
# - command exists
# - output follows the stable image identity contract
#
# NOTE:
# - Output is captured first to avoid SIGPIPE with pipefail
# -----------------------------------------------------------------------------

echo "==> Core: about"
about_output="$(docker run --rm "${IMAGE}" about)"

# Stable contract markers
echo "${about_output}" | grep -q '^Image identity:'
echo "${about_output}" | grep -q '^[[:space:]]*Name:'
echo "${about_output}" | grep -q '^[[:space:]]*Domain:'


# -----------------------------------------------------------------------------
# Core command: info
#
# Verifies:
# - command exists
# - runtime sections are present
#
# NOTE:
# - Output is captured first to avoid SIGPIPE with pipefail
# -----------------------------------------------------------------------------

echo "==> Core: info"
info_output="$(docker run --rm "${IMAGE}" info)"

# Stable contract markers
echo "${info_output}" | grep -q '^Runtime contract:'
echo "${info_output}" | grep -q '^Runtime state:'


# -----------------------------------------------------------------------------
# Core command: exec
#
# Verifies:
# - explicit system command execution works
# -----------------------------------------------------------------------------

echo "==> Core: exec"
docker run --rm "${IMAGE}" exec true


# -----------------------------------------------------------------------------
# Core command: version
#
# Verifies:
# - command exists
# - tool version section header is present
#
# NOTE:
# - Exact tool list is intentionally NOT validated
# -----------------------------------------------------------------------------

echo "==> Core: version"
version_output="$(docker run --rm "${IMAGE}" version)"

# Stable contract marker
echo "${version_output}" | grep -q '^Tool versions:'


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Runner core contract tests passed"
