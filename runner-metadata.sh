#!/usr/bin/env bash
# Shared strict parser for runner metadata files.

runner_metadata_error() {
  local file="$1"
  local line_no="$2"
  local message="$3"

  echo "ERROR: invalid metadata in ${file}:${line_no}: ${message}" >&2
  return 1
}

runner_metadata_validate_value() {
  local file="$1"
  local line_no="$2"
  local value="$3"

  # shellcheck disable=SC2016
  # Literal shell markers are deliberately matched without expansion.
  case "$value" in
    *\"* | *"'"*)
      runner_metadata_error "$file" "$line_no" "quotes are not supported"
      return 1
      ;;
    *'$('*)
      runner_metadata_error "$file" "$line_no" "command substitution '\$()' is not supported"
      return 1
      ;;
    *'`'*)
      runner_metadata_error "$file" "$line_no" "backticks are not supported"
      return 1
      ;;
    *'&&'*)
      runner_metadata_error "$file" "$line_no" "control operator '&&' is not supported"
      return 1
      ;;
    *'||'*)
      runner_metadata_error "$file" "$line_no" "control operator '||' is not supported"
      return 1
      ;;
    *';'*)
      runner_metadata_error "$file" "$line_no" "control operator ';' is not supported"
      return 1
      ;;
    *'|'*)
      runner_metadata_error "$file" "$line_no" "control operator '|' is not supported"
      return 1
      ;;
    *'<'*)
      runner_metadata_error "$file" "$line_no" "redirection operator '<' is not supported"
      return 1
      ;;
    *'>'*)
      runner_metadata_error "$file" "$line_no" "redirection operator '>' is not supported"
      return 1
      ;;
  esac
}

# shellcheck disable=SC2094
# The parser only reads file; diagnostics merely include its path.
runner_metadata_parse_file() {
  local file="$1"
  local callback="${2:-}"
  local line=""
  local key=""
  local value=""
  local line_no=0
  local -A seen_keys=()

  [[ -r "$file" ]] || {
    echo "ERROR: metadata file is not readable (${file})" >&2
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    line="${line%$'\r'}"

    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue

    if [[ "$line" =~ ^export[[:space:]] ]]; then
      runner_metadata_error "$file" "$line_no" "export prefix is not supported"
      return 1
    fi

    if [[ "$line" != *=* ]]; then
      runner_metadata_error "$file" "$line_no" "expected KEY=VALUE"
      return 1
    fi

    key="${line%%=*}"
    value="${line#*=}"

    if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
      runner_metadata_error "$file" "$line_no" "invalid key '${key}'"
      return 1
    fi

    if [[ -n "${seen_keys[$key]:-}" ]]; then
      runner_metadata_error "$file" "$line_no" "duplicate key '${key}'"
      return 1
    fi

    runner_metadata_validate_value "$file" "$line_no" "$value" || return 1
    seen_keys["$key"]=1

    if [[ -n "$callback" ]]; then
      "$callback" "$key" "$value" || return 1
    fi
  done <"$file"
}

runner_metadata_validate_file() {
  runner_metadata_parse_file "$1"
}

runner_metadata_export_pair() {
  local key="$1"
  local value="$2"

  printf -v "$key" '%s' "$value"
  # shellcheck disable=SC2163
  # printf -v created the validated dynamic variable named by $key.
  export "$key"
}

runner_metadata_export_file() {
  runner_metadata_parse_file "$1" runner_metadata_export_pair
}
