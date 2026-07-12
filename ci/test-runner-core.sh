#!/usr/bin/env bash
# Core canonical runner interface checks shared by base and derived images.

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE variable must be set}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "==> Runner core contract tests for image: ${IMAGE}"

docker run --rm "${IMAGE}" --help >"${TMP_DIR}/help.out"
grep -Fx '  runner tool <name> [arguments...]' "${TMP_DIR}/help.out" >/dev/null
docker run --rm "${IMAGE}" --version | grep -Ex '^runner [0-9]+\.[0-9]+\.[0-9]+ \(contract v001\)$' >/dev/null

docker run --rm "${IMAGE}" info --format text >"${TMP_DIR}/info-text.out"
grep -q '^Runner: runner ' "${TMP_DIR}/info-text.out"
docker run --rm "${IMAGE}" info --format json >"${TMP_DIR}/info.json"
grep -q '"schema_version":1' "${TMP_DIR}/info.json"

docker run --rm "${IMAGE}" tool --format json >"${TMP_DIR}/tools.json"
grep -q '"schema_version":1' "${TMP_DIR}/tools.json"
docker run --rm "${IMAGE}" exec -- true

echo "==> Runner core contract tests passed"
