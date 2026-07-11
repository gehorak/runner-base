#!/usr/bin/env bash
# Run the complete base-owned test sequence shared by Make, CI, and releases.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:?IMAGE must name the image under test}"
PYTHON="${PYTHON:-python3}"

export IMAGE

"${PYTHON}" "${ROOT_DIR}/ci/validate-cli-v001-contract.py"

for test_script in \
  ci/test-release-evidence.sh \
  ci/test-shell-safety.sh \
  ci/test-metadata-grammar.sh \
  ci/test-base-dependencies.sh \
  ci/test-smoke.sh \
  ci/test-image-identity.sh \
  ci/test-runner-core.sh \
  ci/test-negative.sh \
  ci/test-runner-plugin.sh; do
  bash "${ROOT_DIR}/${test_script}"
done

echo "==> Base-owned test suite passed"
