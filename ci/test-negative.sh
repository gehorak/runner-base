#!/usr/bin/env bash
# Negative contract checks for the canonical dispatcher.

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"
TMP_DIR="$(mktemp -d)"
STARTUP_IMAGE="${IMAGE}-startup-attack"
trap 'rm -rf "${TMP_DIR}"; docker image rm -f "${STARTUP_IMAGE}" >/dev/null 2>&1 || true' EXIT

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

startup_context="${TMP_DIR}/startup-context"
mkdir -p "${startup_context}"
printf '%s\n' \
  "FROM ${IMAGE}" \
  'USER root' \
  "RUN printf 'touch /tmp/runner-bash-env-marker\\nexit 99\\n' > /tmp/runner-bash-env" \
  'ENV BASH_ENV=/tmp/runner-bash-env' \
  'USER runner' \
  >"${startup_context}/Dockerfile"
docker build -t "${STARTUP_IMAGE}" "${startup_context}" >/dev/null

startup_container_id="$(docker create "${STARTUP_IMAGE}" info)"
docker start -a "${startup_container_id}" >/dev/null
if docker cp "${startup_container_id}:/tmp/runner-bash-env-marker" "${TMP_DIR}/bash-env-marker" >/dev/null 2>&1; then
  echo 'ERROR: BASH_ENV payload executed before Runner guards' >&2
  exit 1
fi
docker rm -f "${startup_container_id}" >/dev/null

set +e
function_container_id="$(docker create --user 0 --env 'BASH_FUNC_runner_error%%=() { touch /tmp/runner-imported-function; exit 99; }' "${IMAGE}" info)"
docker start -a "${function_container_id}" >/dev/null 2>"${TMP_DIR}/function-import.err"
function_import_exit=$?
set -e
[[ "${function_import_exit}" -eq 2 ]]
grep -F RUNNER_E_ROOT "${TMP_DIR}/function-import.err" >/dev/null
if docker cp "${function_container_id}:/tmp/runner-imported-function" "${TMP_DIR}/function-marker" >/dev/null 2>&1; then
  echo 'ERROR: imported Bash function executed before Runner guards' >&2
  exit 1
fi
docker rm -f "${function_container_id}" >/dev/null

echo "==> Negative tests passed"
