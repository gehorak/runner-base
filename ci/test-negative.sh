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

# The entrypoint must never resolve its interpreter or root guard through a
# caller-supplied PATH. A fake bash and id must not alter the root rejection.
set +e
docker run --rm --user 0 --entrypoint /bin/bash "${IMAGE}" -c '
  mkdir -p /tmp/runner-path-hijack
  printf "#!/bin/sh\\nexit 99\\n" > /tmp/runner-path-hijack/bash
  printf "#!/bin/sh\\nexit 99\\n" > /tmp/runner-path-hijack/id
  chmod 0755 /tmp/runner-path-hijack/bash /tmp/runner-path-hijack/id
  PATH=/tmp/runner-path-hijack:$PATH /usr/local/bin/runner info
' >/dev/null 2>"${TMP_DIR}/path-hijack.err"
path_hijack_exit=$?
set -e
[[ "$path_hijack_exit" -eq 2 ]]
grep -F RUNNER_E_ROOT "${TMP_DIR}/path-hijack.err" >/dev/null

echo "==> Negative tests passed"
