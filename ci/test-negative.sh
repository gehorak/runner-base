#!/usr/bin/env bash
# Negative contract checks for the canonical dispatcher.

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

expect_failure() {
  local expected_exit="$1"
  local expected_identifier="$2"
  shift 2
  set +e
  docker run --rm "${IMAGE}" "$@" >"${TMP_DIR}/out" 2>"${TMP_DIR}/err"
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected_exit" ]] || {
    echo "ERROR: expected exit ${expected_exit}, got ${actual}: $*" >&2
    exit 1
  }
  grep -F "$expected_identifier" "${TMP_DIR}/err" >/dev/null
}

echo "==> Negative tests for image: ${IMAGE}"

expect_failure 4 RUNNER_E_NOT_FOUND ls
expect_failure 4 RUNNER_E_NOT_FOUND unknown
expect_failure 4 RUNNER_E_NOT_FOUND ../../../../bin/bash
expect_failure 2 RUNNER_E_FORMAT tool --format
expect_failure 2 RUNNER_E_USAGE shell -c true
expect_failure 2 RUNNER_E_USAGE exec --

set +e
docker run --rm --user 0 "${IMAGE}" info >/dev/null 2>"${TMP_DIR}/root.err"
root_exit=$?
set -e
[[ "$root_exit" -eq 2 ]]
grep -F RUNNER_E_ROOT "${TMP_DIR}/root.err" >/dev/null

echo "==> Negative tests passed"
