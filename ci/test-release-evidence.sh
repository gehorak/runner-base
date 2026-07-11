#!/usr/bin/env bash
# Exercise the deterministic release-evidence writer and validator without publishing.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

EVIDENCE="${TMP_DIR}/release-evidence.json"
export RUNNER_RELEASE_EVIDENCE_OUTPUT="${EVIDENCE}"
export RUNNER_RELEASE_SOURCE_COMMIT="0123456789abcdef0123456789abcdef01234567"
export RUNNER_RELEASE_TAG="v0.2.6"
export RUNNER_RELEASE_CANDIDATE_IMAGE_ID="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export RUNNER_RELEASE_PUBLISHED_REFERENCE="ghcr.io/gehorak/runner-base:0.2.6"
export RUNNER_RELEASE_PUBLISHED_DIGEST="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
export RUNNER_RELEASE_PARENT_REFERENCE="debian:bookworm-slim@sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df"
export RUNNER_RELEASE_PARENT_DIGEST="sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df"
export RUNNER_RELEASE_SBOM_REFERENCE="runner-base-0.2.6.sbom.spdx.json"
export RUNNER_RELEASE_PROVENANCE_REFERENCE="https://github.com/gehorak/runner-base/attestations/1"
export RUNNER_RELEASE_PREVIOUS_REFERENCE="ghcr.io/gehorak/runner-base:0.2.4"
export RUNNER_RELEASE_PREVIOUS_DIGEST="sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
export RUNNER_RELEASE_TESTS="cli-v001-contract,test-release-evidence"

"${PYTHON}" "${ROOT_DIR}/ci/write-release-evidence.py"
"${PYTHON}" "${ROOT_DIR}/ci/validate-release-evidence.py" "${EVIDENCE}"

sed -i 's#ghcr.io/gehorak/runner-base:0.2.6#ghcr.io/gehorak/runner-base:latest#' "${EVIDENCE}"
if "${PYTHON}" "${ROOT_DIR}/ci/validate-release-evidence.py" "${EVIDENCE}" >/dev/null 2>&1; then
  echo "ERROR: release evidence validator accepted a mutable published reference" >&2
  exit 1
fi

"${PYTHON}" "${ROOT_DIR}/ci/write-release-evidence.py"
sed -i 's#ghcr.io/gehorak/runner-base:0.2.6#ghcr.io/gehorak/runner-base:0.2.7#' "${EVIDENCE}"
if "${PYTHON}" "${ROOT_DIR}/ci/validate-release-evidence.py" "${EVIDENCE}" >/dev/null 2>&1; then
  echo "ERROR: release evidence validator accepted a published reference that mismatches source.tag" >&2
  exit 1
fi

echo "==> Release evidence writer and validator tests passed"
