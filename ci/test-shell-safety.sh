#!/usr/bin/env bash
# Static safety checks for the shell implementation and its test helpers.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scripts=(
  "${ROOT_DIR}/runner"
  "${ROOT_DIR}/runner-metadata.sh"
  "${ROOT_DIR}/ci"/*.sh
)

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

if grep -nE '(^|[[:space:];])eval([[:space:];]|$)' "${scripts[@]}"; then
  fail "eval is forbidden in runner shell code"
fi

if grep -nE '^[[:space:]]*(source|\.)[[:space:]]' "${ROOT_DIR}/runner-metadata.sh"; then
  fail "metadata parser must not source metadata or another shell file"
fi

for script in "${scripts[@]}"; do
  if grep -qE '(^|[[:space:]=;(])mktemp([[:space:]]|-[[:alnum:]])' "${script}" && ! grep -qE 'trap .*[[:space:]]EXIT' "${script}"; then
    fail "temporary state in ${script} has no EXIT cleanup trap"
  fi
done

echo "==> Shell safety: no dynamic evaluation and deterministic temporary cleanup"
