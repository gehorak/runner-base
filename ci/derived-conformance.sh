#!/usr/bin/env bash
# Run the versioned base contract against one derived image.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
IMAGE=""
BASE_REFERENCE=""
CONTRACT_VERSION=""
TOOLS_LOCK=""
DOMAIN_TEST=""

usage() {
  cat >&2 <<'EOF'
usage: derived-conformance.sh --image <image> --base-reference <immutable-reference> \
  --contract-version v001 --tools-lock <tools.lock.json> --domain-test <shell-script>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE="${2:-}"
      shift 2
      ;;
    --base-reference)
      BASE_REFERENCE="${2:-}"
      shift 2
      ;;
    --contract-version)
      CONTRACT_VERSION="${2:-}"
      shift 2
      ;;
    --tools-lock)
      TOOLS_LOCK="${2:-}"
      shift 2
      ;;
    --domain-test)
      DOMAIN_TEST="${2:-}"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n "${IMAGE}" && -n "${BASE_REFERENCE}" && -n "${CONTRACT_VERSION}" && -n "${TOOLS_LOCK}" && -n "${DOMAIN_TEST}" ]] || {
  usage
  exit 2
}
[[ "${CONTRACT_VERSION}" == "v001" ]] || {
  echo "ERROR: unsupported derived conformance contract '${CONTRACT_VERSION}'" >&2
  exit 1
}
[[ "${BASE_REFERENCE}" =~ ^ghcr\.io/gehorak/runner-base:[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$ ]] || {
  echo "ERROR: base reference must be an immutable runner-base SemVer digest reference" >&2
  exit 1
}
[[ -f "${TOOLS_LOCK}" ]] || {
  echo "ERROR: tools lock does not exist: ${TOOLS_LOCK}" >&2
  exit 1
}
[[ -f "${DOMAIN_TEST}" ]] || {
  echo "ERROR: domain test does not exist: ${DOMAIN_TEST}" >&2
  exit 1
}

"${PYTHON}" "${ROOT_DIR}/ci/validate-tools-lock.py" "${TOOLS_LOCK}"

info_json="$(docker run --rm "${IMAGE}" info --format json)"
INFO_JSON="${info_json}" "${PYTHON}" - "${TOOLS_LOCK}" "${CONTRACT_VERSION}" <<'PY'
import json
import os
import sys
from pathlib import Path

info = json.loads(os.environ["INFO_JSON"])
lock = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected_contract = sys.argv[2]
if info.get("runner", {}).get("contract_version") != expected_contract:
    raise SystemExit("ERROR: derived image reports an unexpected Runner contract version")
image_tools = [tool.get("name") for tool in info.get("tools", [])]
lock_tools = [tool.get("name") for tool in lock.get("tools", [])]
if image_tools != lock_tools:
    raise SystemExit("ERROR: tools.lock names do not exactly match declared Runner tools")
PY

docker run --rm --user 0 --entrypoint /bin/sh "${IMAGE}" -c '
  set -eu
  for file in /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env /usr/local/bin/runner /usr/local/lib/runner/metadata.sh; do
    set -- $(stat -c "%u %g %a" "$file")
    test "$1" = 0
    test "$2" = 0
    group_digit=$(( ($3 / 10) % 10 ))
    other_digit=$(( $3 % 10 ))
    test $(( group_digit & 2 )) -eq 0
    test $(( other_digit & 2 )) -eq 0
  done
'

IMAGE="${IMAGE}" BASE_REFERENCE="${BASE_REFERENCE}" RUNNER_CONFORMANCE_VERSION="${CONTRACT_VERSION}" bash "${DOMAIN_TEST}"
echo "==> Derived conformance ${CONTRACT_VERSION} passed for ${IMAGE}"
