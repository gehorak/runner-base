#!/usr/bin/env bash
# Verify the distributable derived conformance interface with synthetic images.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:?IMAGE must name the image under test}"
TMP_DIR="$(mktemp -d)"
DERIVED_IMAGE="${IMAGE}-derived-conformance"
WEAK_IMAGE="${IMAGE}-derived-weak-parent"
BASE_REFERENCE="ghcr.io/gehorak/runner-base:0.3.0@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
trap 'rm -rf "${TMP_DIR}"; docker image rm -f "${DERIVED_IMAGE}" "${WEAK_IMAGE}" >/dev/null 2>&1 || true' EXIT

fixture="${ROOT_DIR}/ci/fixtures/v030-derived"
docker build --build-arg "BASE_IMAGE=${IMAGE}" -t "${DERIVED_IMAGE}" "${fixture}" >/dev/null
bash "${ROOT_DIR}/ci/derived-conformance.sh" \
  --image "${DERIVED_IMAGE}" \
  --base-reference "${BASE_REFERENCE}" \
  --contract-version v001 \
  --tools-lock "${fixture}/tools.lock.json" \
  --domain-test "${fixture}/domain-test.sh"

weak_context="${TMP_DIR}/weak-parent"
mkdir -p "${weak_context}"
printf '%s\n' "FROM ${DERIVED_IMAGE}" 'USER root' 'RUN chown runner:runner /etc/runner/image.env' 'USER runner' >"${weak_context}/Dockerfile"
docker build -t "${WEAK_IMAGE}" "${weak_context}" >/dev/null
if bash "${ROOT_DIR}/ci/derived-conformance.sh" \
  --image "${WEAK_IMAGE}" \
  --base-reference "${BASE_REFERENCE}" \
  --contract-version v001 \
  --tools-lock "${fixture}/tools.lock.json" \
  --domain-test "${fixture}/domain-test.sh" >/dev/null 2>&1; then
  echo 'ERROR: derived conformance accepted a runtime-user-owned parent file' >&2
  exit 1
fi

echo "==> Derived conformance interface tests passed"
