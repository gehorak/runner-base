#!/usr/bin/env bash
# Confirm the base dispatcher works with the documented hardened envelope.

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE must name the image under test}"
PYTHON="${PYTHON:-python3}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --user 10001:10001 \
  "${IMAGE}" info --format json >"${TMP_DIR}/info.json"

"${PYTHON}" - "${TMP_DIR}/info.json" <<'PY'
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["schema_version"] == 1
assert value["runtime"]["user"] == "runner"
PY

echo "==> Hardened runtime tests passed"
