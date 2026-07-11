#!/usr/bin/env bash
# Syntax and formatting checks for the distributed shell surface.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scripts=(
  "${ROOT_DIR}/runner"
  "${ROOT_DIR}/runner-metadata.sh"
  "${ROOT_DIR}/ci"/*.sh
)

for script in "${scripts[@]}"; do
  bash -n "${script}"
done

command -v shfmt >/dev/null 2>&1 || {
  echo "ERROR: shfmt is required for shell formatting checks" >&2
  exit 1
}

shfmt -d -i 2 -ci "${scripts[@]}"

echo "OK: Bash syntax and shfmt checks passed"
