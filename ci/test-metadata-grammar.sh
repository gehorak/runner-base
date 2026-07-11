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

  assert_contains "$runtime_err" "/etc/runner/tools.env:1: command substitution '\$()' is not supported"

  if docker cp "$runtime_container_id:/tmp/metadata-executed" "${tmpdir}/runtime-marker" >/dev/null 2>&1; then
    fail "runtime metadata executed shell syntax unexpectedly"
  fi

  echo "==> Runtime integration rejects invalid metadata before execution"
else
  echo "==> Runtime integration skipped (IMAGE is not set)"
fi

echo
echo "==> Metadata grammar tests passed"
