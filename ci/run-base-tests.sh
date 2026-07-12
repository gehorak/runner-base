#!/usr/bin/env bash
# Run the complete base-owned test sequence shared by Make, CI, and releases.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
TEST_SCRIPTS=(
  ci/validate-cli-v001-contract.py
  ci/test-release-evidence.sh
  ci/test-release-identity.sh
  ci/test-release-candidate-identity.py
  ci/test-parent-reference.py
  ci/test-dockerfile-structure.py
  ci/test-shell-safety.sh
  ci/test-metadata-grammar.sh
  ci/test-base-dependencies.sh
  ci/test-smoke.sh
  ci/test-image-identity.sh
  ci/test-runner-core.sh
  ci/test-negative.sh
  ci/test-hardened-runtime.sh
  ci/test-runner-plugin.sh
  ci/test-runner-v030.sh
)

if [[ "${1:-}" == "--list" && $# -eq 1 ]]; then
  printf '%s\n' "${TEST_SCRIPTS[@]}"
  exit 0
fi

[[ $# -eq 0 ]] || {
  echo "usage: run-base-tests.sh [--list]" >&2
  exit 2
}

IMAGE="${IMAGE:?IMAGE must name the image under test}"

export IMAGE

for test_script in "${TEST_SCRIPTS[@]}"; do
  case "${test_script}" in
    *.py) "${PYTHON}" "${ROOT_DIR}/${test_script}" ;;
    *) bash "${ROOT_DIR}/${test_script}" ;;
  esac
done

echo "==> Base-owned test suite passed"
