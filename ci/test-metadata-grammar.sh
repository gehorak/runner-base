#!/usr/bin/env bash
# =============================================================================
# Metadata grammar tests — runner metadata parser
#
# Purpose:
# - Validate strict KEY=VALUE metadata parsing
# - Reject shell syntax before it can be evaluated
# - Protect build-time and runtime metadata safety invariants
# =============================================================================

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-}"
PYTHON="${PYTHON:-python3}"

# shellcheck disable=SC1091
source "${ROOT_DIR}/runner-metadata.sh"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local needle="$2"

  grep -F -- "$needle" "$file" >/dev/null || fail "expected '${needle}' in ${file}"
}

expect_invalid() {
  local file="$1"
  local expected_line="$2"
  local expected_message="$3"
  local stderr_file="$4"

  if runner_metadata_validate_file "$file" 2>"$stderr_file"; then
    fail "expected metadata validation to fail for ${file}"
  fi

  assert_contains "$stderr_file" "${file}:${expected_line}: ${expected_message}"
}

echo "==> Metadata grammar tests"
echo

tmpdir="$(mktemp -d)"
runtime_container_id=""

cleanup() {
  if [[ -n "$runtime_container_id" ]]; then
    docker rm -f "$runtime_container_id" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

valid_file="${tmpdir}/valid.env"
printf '%s\n' \
  '# comment' \
  '' \
  'RUNNER_IMAGE=runner-base' \
  'RUNNER_DESCRIPTION=Deterministic runner base image' \
  'RUNNER_EMPTY=' \
  'RUNNER_NOTE=value=with=equals' \
  >"$valid_file"
printf 'RUNNER_SPACED=  padded value  \n' >>"$valid_file"

unset RUNNER_IMAGE RUNNER_DESCRIPTION RUNNER_EMPTY RUNNER_NOTE RUNNER_SPACED || true
runner_metadata_export_file "$valid_file"

[[ "${RUNNER_IMAGE}" == "runner-base" ]] || fail "RUNNER_IMAGE did not load"
[[ "${RUNNER_DESCRIPTION}" == "Deterministic runner base image" ]] || fail "RUNNER_DESCRIPTION did not load"
[[ "${RUNNER_EMPTY}" == "" ]] || fail "RUNNER_EMPTY did not preserve empty value"
[[ "${RUNNER_NOTE}" == "value=with=equals" ]] || fail "RUNNER_NOTE did not preserve '=' in value"
[[ "${RUNNER_SPACED}" == "  padded value  " ]] || fail "RUNNER_SPACED did not preserve surrounding spaces"

echo "==> Parser accepts valid metadata"

duplicate_file="${tmpdir}/duplicate.env"
duplicate_err="${tmpdir}/duplicate.err"
printf '%s\n' \
  'RUNNER_IMAGE=runner-base' \
  'RUNNER_IMAGE=runner-duplicate' \
  >"$duplicate_file"
expect_invalid "$duplicate_file" 2 "duplicate key 'RUNNER_IMAGE'" "$duplicate_err"

export_file="${tmpdir}/export.env"
export_err="${tmpdir}/export.err"
printf '%s\n' 'export RUNNER_IMAGE=runner-base' >"$export_file"
expect_invalid "$export_file" 1 "export prefix is not supported" "$export_err"

quote_file="${tmpdir}/quote.env"
quote_err="${tmpdir}/quote.err"
printf '%s\n' 'RUNNER_DESCRIPTION="quoted value"' >"$quote_file"
expect_invalid "$quote_file" 1 "quotes are not supported" "$quote_err"

key_space_file="${tmpdir}/key-space.env"
key_space_err="${tmpdir}/key-space.err"
printf '%s\n' 'RUNNER_IMAGE =runner-base' >"$key_space_file"
expect_invalid "$key_space_file" 1 "invalid key 'RUNNER_IMAGE '" "$key_space_err"

no_equals_file="${tmpdir}/no-equals.env"
no_equals_err="${tmpdir}/no-equals.err"
printf '%s\n' 'RUNNER_IMAGE' >"$no_equals_file"
expect_invalid "$no_equals_file" 1 "expected KEY=VALUE" "$no_equals_err"

marker_file="${tmpdir}/metadata-executed"
command_sub_file="${tmpdir}/command-substitution.env"
command_sub_err="${tmpdir}/command-substitution.err"
# shellcheck disable=SC2016
# The metadata fixture must contain a literal command substitution marker.
printf 'TOOL_BAD=$(touch %s)\n' "$marker_file" >"$command_sub_file"
expect_invalid "$command_sub_file" 1 "command substitution '\$()' is not supported" "$command_sub_err"
[[ ! -e "$marker_file" ]] || fail "command substitution was executed unexpectedly"

echo "==> Parser rejects invalid metadata without executing shell syntax"

operator_file="${tmpdir}/operator.env"
operator_err="${tmpdir}/operator.err"
printf '%s\n' 'TOOL_BAD=value && echo nope' >"$operator_file"
expect_invalid "$operator_file" 1 "control operator '&&' is not supported" "$operator_err"

pipe_file="${tmpdir}/pipe.env"
pipe_err="${tmpdir}/pipe.err"
printf '%s\n' 'TOOL_BAD=value | cat' >"$pipe_file"
expect_invalid "$pipe_file" 1 "control operator '|' is not supported" "$pipe_err"

image_contract="${tmpdir}/image-contract.env"
runtime_contract="${tmpdir}/runtime-contract.env"
tools_contract="${tmpdir}/tools-contract.env"
printf '%s\n' \
  'RUNNER_IMAGE=runner-base' \
  'RUNNER_DOMAIN=base' \
  'RUNNER_ROLE=base' \
  'RUNNER_VERSION=0.3.0' \
  'RUNNER_CONTRACT_VERSION=v001' \
  'RUNNER_IMAGE_VERSION=0.3.0' \
  'RUNNER_IMAGE_REVISION=local' \
  'RUNNER_SUPPORTED_PLATFORM=linux/amd64' \
  >"${image_contract}"
printf '%s\n' \
  'RUNTIME_USER_NAME=runner' \
  'RUNTIME_USER_UID=10001' \
  'RUNTIME_USER_GID=10001' \
  'RUNTIME_USER_HOME=/home/runner' \
  'RUNTIME_SHELL=/bin/bash' \
  'RUNTIME_WORKDIR=/workspace' \
  >"${runtime_contract}"
printf 'RUNNER_TOOL_NAMES=\n' >"${tools_contract}"
runner_metadata_validate_runtime_contract "${image_contract}" "${runtime_contract}" "${tools_contract}"

sed 's/RUNNER_IMAGE_REVISION=local/RUNNER_IMAGE_REVISION=fixture/' "${image_contract}" >"${tmpdir}/invalid-revision.env"
if runner_metadata_validate_runtime_contract "${tmpdir}/invalid-revision.env" "${runtime_contract}" "${tools_contract}" >/dev/null 2>&1; then
  fail "expected invalid image revision to fail the runtime contract"
fi
sed 's/RUNTIME_USER_UID=10001/RUNTIME_USER_UID=0/' "${runtime_contract}" >"${tmpdir}/invalid-uid.env"
if runner_metadata_validate_runtime_contract "${image_contract}" "${tmpdir}/invalid-uid.env" "${tools_contract}" >/dev/null 2>&1; then
  fail "expected root UID to fail the runtime contract"
fi
sed 's#RUNTIME_USER_HOME=/home/runner#RUNTIME_USER_HOME=home/runner#' "${runtime_contract}" >"${tmpdir}/invalid-home.env"
if runner_metadata_validate_runtime_contract "${image_contract}" "${tmpdir}/invalid-home.env" "${tools_contract}" >/dev/null 2>&1; then
  fail "expected relative runtime home to fail the runtime contract"
fi

derived_manifest="${tmpdir}/derived.manifest"
printf '%s\n' \
  'RUNNER_IMAGE=runner-derived' \
  'RUNNER_DOMAIN=fixture' \
  'RUNNER_ROLE=fixture' \
  'RUNNER_IMAGE_VERSION=0.3.0' \
  'RUNNER_IMAGE_REVISION=local' \
  'RUNNER_TOOL_NAMES=' \
  >"${derived_manifest}"
runner_metadata_validate_derived_manifest "${derived_manifest}"
printf 'RUNNER_VERSION=9.9.9\n' >>"${derived_manifest}"
if runner_metadata_validate_derived_manifest "${derived_manifest}" >/dev/null 2>&1; then
  fail "expected derived manifest platform override to fail"
fi

echo "==> Runtime and derived metadata contracts reject incomplete or overridden values"

if [[ -n "$IMAGE" ]]; then
  echo "==> Runtime integration rejects invalid tools metadata"

  runtime_ctx="${tmpdir}/runtime-image"
  runtime_tag="runner-metadata-runtime-test:$$"
  mkdir -p "$runtime_ctx"

  cat >"${runtime_ctx}/Dockerfile" <<EOF
FROM ${IMAGE}
USER root
RUN printf 'TOOL_BAD=\$(touch /tmp/metadata-executed)\n' > /etc/runner/tools.env \\
 && chmod 0444 /etc/runner/tools.env
USER runner
EOF

  docker build -t "$runtime_tag" "$runtime_ctx" >/dev/null

  runtime_container_id="$(docker create "$runtime_tag" info)"
  runtime_out="${tmpdir}/runtime.out"
  runtime_err="${tmpdir}/runtime.err"

  if docker start -a "$runtime_container_id" >"$runtime_out" 2>"$runtime_err"; then
    fail "expected runtime metadata validation to fail"
  fi

  assert_contains "$runtime_err" "RUNNER_E_CONTRACT: Required Runner metadata is missing or invalid."

  runtime_json_container_id="$(docker create "$runtime_tag" info --format json)"
  runtime_json_out="${tmpdir}/runtime-json.out"
  runtime_json_err="${tmpdir}/runtime-json.err"
  if docker start -a "$runtime_json_container_id" >"$runtime_json_out" 2>"$runtime_json_err"; then
    fail "expected JSON runtime metadata validation to fail"
  fi
  "${PYTHON}" - "$runtime_json_err" <<'PY'
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["schema_version"] == 1
assert value["error"]["id"] == "RUNNER_E_CONTRACT"
PY
  docker rm -f "$runtime_json_container_id" >/dev/null

  if docker cp "$runtime_container_id:/tmp/metadata-executed" "${tmpdir}/runtime-marker" >/dev/null 2>&1; then
    fail "runtime metadata executed shell syntax unexpectedly"
  fi

  echo "==> Runtime integration rejects invalid metadata before execution"
else
  echo "==> Runtime integration skipped (IMAGE is not set)"
fi

echo
echo "==> Metadata grammar tests passed"
