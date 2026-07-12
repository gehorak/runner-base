#!/usr/bin/env bash
# Runtime and compatibility checks for the v0.3.0 canonical dispatcher.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:?IMAGE must name the image under test}"
PYTHON="${PYTHON:-python3}"
EXPECTED_RUNNER_VERSION="${EXPECTED_RUNNER_VERSION:-0.3.0}"
EXPECTED_IMAGE_VERSION="${EXPECTED_IMAGE_VERSION:-${EXPECTED_RUNNER_VERSION}}"
FIXTURE_DIR="${ROOT_DIR}/ci/fixtures/v030-derived"
FIXTURE_IMAGE="${IMAGE}-v030-fixture"
INVALID_RUNTIME_IMAGE="${IMAGE}-v030-invalid-runtime"
WORKDIR_FIXTURE_IMAGE="${IMAGE}-workdir-fixture"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
  docker image rm -f "${FIXTURE_IMAGE}" "${INVALID_RUNTIME_IMAGE}" "${WORKDIR_FIXTURE_IMAGE}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

expect_exit() {
  local expected="$1"
  shift
  set +e
  "$@"
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || {
    echo "ERROR: expected exit ${expected}, got ${actual}: $*" >&2
    exit 1
  }
}

echo "==> v0.3 canonical dispatcher tests for image: ${IMAGE}"

docker run --rm "${IMAGE}" --help >"${TMP_DIR}/help.out"
grep -Fx '  runner exec -- <program> [arguments...]' "${TMP_DIR}/help.out" >/dev/null
docker run --rm "${IMAGE}" --version | grep -Fx "runner ${EXPECTED_RUNNER_VERSION} (contract v001)" >/dev/null
docker run --rm "${IMAGE}" info --format json >"${TMP_DIR}/base-info.json"
"${PYTHON}" - "${TMP_DIR}/base-info.json" "${EXPECTED_RUNNER_VERSION}" "${EXPECTED_IMAGE_VERSION}" <<'PY'
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["schema_version"] == 1
assert set(value) == {"schema_version", "runner", "image", "runtime", "tools"}
assert value["runner"] == {"name": "runner", "version": sys.argv[2], "contract_version": "v001"}
assert value["image"]["version"] == sys.argv[3]
assert value["runtime"]["platform"] == "linux"
assert value["runtime"]["architecture"] == "amd64"
assert value["tools"] == []
PY

docker build --build-arg "BASE_IMAGE=${IMAGE}" -t "${FIXTURE_IMAGE}" "${FIXTURE_DIR}"
docker run --rm "${FIXTURE_IMAGE}" exec -- sample-helper helper-path >"${TMP_DIR}/helper.out"
grep -Fx 'sample stdout: helper-path' "${TMP_DIR}/helper.out" >/dev/null
docker run --rm "${FIXTURE_IMAGE}" tool --format json >"${TMP_DIR}/tools.json"
"${PYTHON}" - "${TMP_DIR}/tools.json" <<'PY'
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value == {"schema_version": 1, "tools": [
    {"name": "sample-tool", "version": "1.0.0", "aliases": ["sample"]},
    {"name": "unavailable-tool", "version": "1.0.0", "aliases": []},
]}
PY

docker run --rm "${FIXTURE_IMAGE}" tool sample-tool hello >"${TMP_DIR}/canonical.out" 2>"${TMP_DIR}/canonical.err"
grep -Fx 'sample stdout: hello' "${TMP_DIR}/canonical.out" >/dev/null
test ! -s "${TMP_DIR}/canonical.err"

expect_exit 37 docker run --rm "${FIXTURE_IMAGE}" tool sample-tool --fail >"${TMP_DIR}/child.out" 2>"${TMP_DIR}/child.err"
grep -Fx 'sample stderr' "${TMP_DIR}/child.err" >/dev/null
expect_exit 126 docker run --rm "${FIXTURE_IMAGE}" tool unavailable-tool >"${TMP_DIR}/unavailable.out" 2>"${TMP_DIR}/unavailable.err"
grep -F 'RUNNER_E_NOT_EXECUTABLE' "${TMP_DIR}/unavailable.err" >/dev/null

docker run --rm "${FIXTURE_IMAGE}" sample-tool legacy >"${TMP_DIR}/legacy-tool.out" 2>"${TMP_DIR}/legacy-tool.err"
grep -Fx 'sample stdout: legacy' "${TMP_DIR}/legacy-tool.out" >/dev/null
test "$(grep -c '^DEPRECATED:' "${TMP_DIR}/legacy-tool.err")" -eq 1
docker run --rm "${FIXTURE_IMAGE}" tool sample alias >"${TMP_DIR}/alias.out" 2>"${TMP_DIR}/alias.err"
grep -Fx 'sample stdout: alias' "${TMP_DIR}/alias.out" >/dev/null
test "$(grep -c '^DEPRECATED:' "${TMP_DIR}/alias.err")" -eq 1

docker run --rm "${IMAGE}" exec -- printf '%s' exec-ok >"${TMP_DIR}/exec.out"
grep -Fx 'exec-ok' "${TMP_DIR}/exec.out" >/dev/null
docker run --rm "${IMAGE}" exec printf '%s' legacy-exec >"${TMP_DIR}/legacy-exec.out" 2>"${TMP_DIR}/legacy-exec.err"
grep -Fx 'legacy-exec' "${TMP_DIR}/legacy-exec.out" >/dev/null
test "$(grep -c '^DEPRECATED:' "${TMP_DIR}/legacy-exec.err")" -eq 1

workdir_context="${TMP_DIR}/workdir-image"
mkdir -p "${workdir_context}"
printf '%s\n' "FROM ${IMAGE}" 'USER root' 'RUN mkdir /workspace/subdir && chown 10001:10001 /workspace/subdir' 'USER runner' >"${workdir_context}/Dockerfile"
docker build -t "${WORKDIR_FIXTURE_IMAGE}" "${workdir_context}" >/dev/null
docker run --rm --workdir /workspace/subdir "${WORKDIR_FIXTURE_IMAGE}" exec -- pwd | grep -Fx '/workspace/subdir' >/dev/null
mkdir -p "${TMP_DIR}/mounted-subdir"
chmod 0777 "${TMP_DIR}/mounted-subdir"
docker run --rm --workdir /workspace/subdir -v "${TMP_DIR}/mounted-subdir:/workspace/subdir" "${IMAGE}" exec -- sh -c 'test -w . && pwd' | grep -Fx '/workspace/subdir' >/dev/null
docker image rm -f "${WORKDIR_FIXTURE_IMAGE}" >/dev/null 2>&1 || true

expect_exit 2 docker run --rm "${IMAGE}" info --format yaml >"${TMP_DIR}/format.out" 2>"${TMP_DIR}/format.err"
grep -F 'RUNNER_E_FORMAT' "${TMP_DIR}/format.err" >/dev/null
expect_exit 2 docker run --rm "${IMAGE}" exec -- >"${TMP_DIR}/usage.out" 2>"${TMP_DIR}/usage.err"
grep -F 'RUNNER_E_USAGE' "${TMP_DIR}/usage.err" >/dev/null
expect_exit 4 docker run --rm "${IMAGE}" unknown >"${TMP_DIR}/unknown.out" 2>"${TMP_DIR}/unknown.err"
grep -F 'RUNNER_E_NOT_FOUND' "${TMP_DIR}/unknown.err" >/dev/null
expect_exit 2 docker run --rm "${IMAGE}" --unknown >"${TMP_DIR}/option.out" 2>"${TMP_DIR}/option.err"
grep -F 'RUNNER_E_USAGE' "${TMP_DIR}/option.err" >/dev/null

expect_exit 1 docker build --build-arg "BASE_IMAGE=${IMAGE}" -f "${FIXTURE_DIR}/Dockerfile.invalid-build" "${FIXTURE_DIR}"
docker build --build-arg "BASE_IMAGE=${IMAGE}" -f "${FIXTURE_DIR}/Dockerfile.invalid-runtime" -t "${INVALID_RUNTIME_IMAGE}" "${FIXTURE_DIR}"
expect_exit 3 docker run --rm "${INVALID_RUNTIME_IMAGE}" info >"${TMP_DIR}/invalid.out" 2>"${TMP_DIR}/invalid.err"
grep -F 'RUNNER_E_CONTRACT' "${TMP_DIR}/invalid.err" >/dev/null
expect_exit 3 docker run --rm "${INVALID_RUNTIME_IMAGE}" info --format json >"${TMP_DIR}/invalid-json.out" 2>"${TMP_DIR}/invalid-json.err"
"${PYTHON}" - "${TMP_DIR}/invalid-json.err" <<'PY'
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value == {
    "schema_version": 1,
    "error": {
        "id": "RUNNER_E_CONTRACT",
        "message": "Required Runner metadata is missing or invalid.",
        "hint": "Rebuild the image from valid declarative Runner metadata.",
    },
}
PY

echo "==> v0.3 canonical dispatcher tests passed"
