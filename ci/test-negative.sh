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
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "==> Negative tests for image: ${IMAGE}"
echo

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

expect_runner_failure() {
  local description="$1"
  local expected_message="$2"
  shift 2
  local output=""

  if output="$(docker run --rm "${IMAGE}" "$@" 2>&1)"; then
    fail "${description} succeeded unexpectedly"
  fi

  printf '%s\n' "$output" | grep -F -- "$expected_message" >/dev/null \
    || fail "${description} did not report '${expected_message}'"

  echo "OK: ${description} failed as expected"
}


# -----------------------------------------------------------------------------
# Test 1: Implicit system command execution must fail
#
# Verifies:
# - system commands are NOT executed implicitly
# - 'exec' is the only allowed escape hatch
# -----------------------------------------------------------------------------

echo "==> Negative: implicit system command must fail"
expect_runner_failure \
  "implicit system command execution" \
  "unknown command: ls" \
  ls


# -----------------------------------------------------------------------------
# Test 2: Unknown runner command must fail
#
# Verifies:
# - unknown runner commands are rejected
# - runner does not guess or forward commands
# -----------------------------------------------------------------------------

echo "==> Negative: unknown runner command must fail"
expect_runner_failure \
  "unknown runner command" \
  "unknown command: unknown" \
  unknown


# -----------------------------------------------------------------------------
# Test 3: Invalid plugin command names must fail before lookup
#
# Verifies:
# - path traversal is rejected
# - invalid command tokens are rejected deterministically
# - plugin dispatch does not consult the filesystem for unsafe names
# -----------------------------------------------------------------------------

echo "==> Negative: invalid plugin command names must fail"

expect_runner_failure \
  "path traversal command '../../../../bin/bash'" \
  "invalid command name: ../../../../bin/bash" \
  "../../../../bin/bash"

expect_runner_failure \
  "parent traversal command '../runner'" \
  "invalid command name: ../runner" \
  "../runner"

expect_runner_failure \
  "whitespace command 'bad command'" \
  "invalid command name: bad command" \
  "bad command"

expect_runner_failure \
  "operator command 'bad;cmd'" \
  "invalid command name: bad;cmd" \
  "bad;cmd"

expect_runner_failure \
  "hidden command '.hidden'" \
  "invalid command name: .hidden" \
  ".hidden"


# -----------------------------------------------------------------------------
# Test 3: Root override must fail
#
# Verifies:
# - the runtime contract rejects uid 0 even if the container runtime overrides
#   the configured image user
# -----------------------------------------------------------------------------

echo "==> Negative: root override must fail"

root_err="${TMP_DIR}/root.err"
if docker run --rm --user 0 "${IMAGE}" info >/dev/null 2>"${root_err}"; then
  echo "ERROR: root override succeeded"
  exit 1
fi

grep -F "ERROR: runner must not run as root (uid 0)" "${root_err}" >/dev/null \
  || (echo "ERROR: root override did not return deterministic diagnostic" && exit 1)

echo "OK: root override failed as expected"


# -----------------------------------------------------------------------------
# Test completion
# -----------------------------------------------------------------------------

echo
echo "==> Negative tests passed"
exit 0
