#!/usr/bin/env bash
# Verify that release builds use runtime metadata bound to the release tag.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
TMP_DIR="$(mktemp -d)"
REVISION="0123456789abcdef0123456789abcdef01234567"
trap 'rm -rf "${TMP_DIR}"' EXIT

"${PYTHON}" "${ROOT_DIR}/ci/prepare-release-manifest.py" \
  --input "${ROOT_DIR}/image.manifest" \
  --output "${TMP_DIR}/image.manifest" \
  --tag v0.3.1 \
  --revision "${REVISION}"

grep -Fx 'RUNNER_VERSION=0.3.1' "${TMP_DIR}/image.manifest" >/dev/null
grep -Fx 'RUNNER_IMAGE_VERSION=0.3.1' "${TMP_DIR}/image.manifest" >/dev/null
grep -Fx "RUNNER_IMAGE_REVISION=${REVISION}" "${TMP_DIR}/image.manifest" >/dev/null

if "${PYTHON}" "${ROOT_DIR}/ci/prepare-release-manifest.py" \
  --input "${ROOT_DIR}/image.manifest" \
  --output "${TMP_DIR}/invalid.manifest" \
  --tag v0.3 \
  --revision "${REVISION}" >/dev/null 2>&1; then
  echo "ERROR: release manifest writer accepted an invalid tag" >&2
  exit 1
fi

if "${PYTHON}" "${ROOT_DIR}/ci/prepare-release-manifest.py" \
  --input "${ROOT_DIR}/image.manifest" \
  --output "${TMP_DIR}/invalid.manifest" \
  --tag v0.3.1 \
  --revision local >/dev/null 2>&1; then
  echo "ERROR: release manifest writer accepted a non-commit revision" >&2
  exit 1
fi

echo "==> Release manifest identity tests passed"
