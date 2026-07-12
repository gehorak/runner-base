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
  ci/test-release-identity.sh \
  ci/test-dockerfile-structure.py \
  ci/test-shell-safety.sh \
  ci/test-metadata-grammar.sh \
  ci/test-base-dependencies.sh \
  ci/test-smoke.sh \
  ci/test-image-identity.sh \
  ci/test-runner-core.sh \
  ci/test-negative.sh \
  ci/test-hardened-runtime.sh \
  ci/test-runner-plugin.sh \
  ci/test-runner-v030.sh; do
  case "${test_script}" in
    *.py) "${PYTHON}" "${ROOT_DIR}/${test_script}" ;;
    *) bash "${ROOT_DIR}/${test_script}" ;;
  esac
done

echo "==> Base-owned test suite passed"
