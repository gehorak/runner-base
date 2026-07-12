#!/usr/bin/env bash

# =============================================================================
# runner-metadata — strict literal metadata parser and v0.3 materializer
#
# PURPOSE
# -------
# Validate Runner metadata as KEY=VALUE data and materialize a derived image's
# image, runtime, and declarative tool registry contracts under /etc/runner.
#
# SECURITY BOUNDARY
# -----------------
# This file is trusted platform code. It may be sourced by Runner and Docker
# build steps; the metadata files it parses are never sourced or evaluated.
# =============================================================================
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

# =============================================================================
# v0.3 runtime contract validation
#
# These helpers retain parsed values in associative maps so validation can check
# cross-field registry invariants without evaluating metadata as shell code.
# =============================================================================

runner_metadata_contract_error() {
  echo "ERROR: metadata contract violation: $1" >&2
  return 1
}

runner_metadata_collect_pair() {
  local key="$1"
  local value="$2"
  local -n target="$RUNNER_METADATA_TARGET_MAP_NAME"

  target["$key"]="$value"
}

runner_metadata_load_map() {
  local file="$1"
  local target_name="$2"
  # target is an associative-map nameref supplied by the caller.
  # shellcheck disable=SC2178
  local -n target="$target_name"

  # shellcheck disable=SC2034
  # The callback writes parsed pairs through the dynamic nameref target.
  target=()
  RUNNER_METADATA_TARGET_MAP_NAME="$target_name"
  runner_metadata_parse_file "$file" runner_metadata_collect_pair || return 1
  unset RUNNER_METADATA_TARGET_MAP_NAME
}

runner_metadata_is_reserved_tool_name() {
  case "$1" in
    help | info | tool | exec | shell | version | about | runner)
      return 0
      ;;
  esac
  return 1
}

# Tool and alias lists are comma-separated, lexical, unique, and use the same
# canonical name grammar as the public CLI contract.
runner_metadata_validate_name_list() {
  local list="$1"
  local label="$2"
  local item=""
  local previous=""
  local -A seen=()
  local IFS=','

  [[ -n "$list" ]] || return 0
  for item in $list; do
    [[ "$item" =~ ^[a-z][a-z0-9-]*$ ]] || {
      runner_metadata_contract_error "${label} contains invalid name '${item}'"
      return 1
    }
    [[ -z "${seen[$item]:-}" ]] || {
      runner_metadata_contract_error "${label} contains duplicate name '${item}'"
      return 1
    }
    [[ -z "$previous" || "$previous" < "$item" ]] || {
      runner_metadata_contract_error "${label} must use lexical ordering"
      return 1
    }
    seen["$item"]=1
    previous="$item"
  done
}

# Convert a canonical dashed tool name into its validated metadata key suffix.
runner_metadata_tool_key() {
  local name="$1"
  name="${name^^}"
  printf '%s' "${name//-/_}"
}

# Validate explicit registry identity, aliases, version, and executable binding.
# Executability itself is deliberately checked at runtime so a declared but
# unavailable executable receives the required Runner exit code 126.
runner_metadata_validate_tool_registry() {
  local file="$1"
  local name=""
  local alias=""
  local key=""
  local version=""
  local executable=""
  local aliases=""
  local -A values=()
  local -A names=()
  local -A aliases_seen=()
  local IFS=','

  runner_metadata_load_map "$file" values || return 1
  [[ -v 'values[RUNNER_TOOL_NAMES]' ]] || {
    runner_metadata_contract_error "missing RUNNER_TOOL_NAMES"
    return 1
  }
  runner_metadata_validate_name_list "${values[RUNNER_TOOL_NAMES]}" "RUNNER_TOOL_NAMES" || return 1

  for name in ${values[RUNNER_TOOL_NAMES]}; do
    runner_metadata_is_reserved_tool_name "$name" && {
      runner_metadata_contract_error "tool name '${name}' is reserved"
      return 1
    }
    names["$name"]=1
    key="$(runner_metadata_tool_key "$name")"
    version="${values[RUNNER_TOOL_${key}_VERSION]:-}"
    executable="${values[RUNNER_TOOL_${key}_EXECUTABLE]:-}"
    aliases="${values[RUNNER_TOOL_${key}_ALIASES]:-}"
    [[ -n "$version" ]] || {
      runner_metadata_contract_error "tool '${name}' is missing version"
      return 1
    }
    [[ "$executable" == /* && "$executable" != *[[:space:]]* ]] || {
      runner_metadata_contract_error "tool '${name}' has invalid executable binding"
      return 1
    }
    runner_metadata_validate_name_list "$aliases" "aliases for tool '${name}'" || return 1
    for alias in $aliases; do
      runner_metadata_is_reserved_tool_name "$alias" && {
        runner_metadata_contract_error "tool alias '${alias}' is reserved"
        return 1
      }
      [[ "$alias" != "$name" && -z "${names[$alias]:-}" && -z "${aliases_seen[$alias]:-}" ]] || {
        runner_metadata_contract_error "tool alias '${alias}' collides with an identity or alias"
        return 1
      }
      aliases_seen["$alias"]="$name"
    done
  done

  for alias in "${!aliases_seen[@]}"; do
    [[ -z "${names[$alias]:-}" ]] || {
      runner_metadata_contract_error "tool alias '${alias}' collides with an identity"
      return 1
    }
  done
}

# Validate image/runtime identity plus the registry both at build time and at
# runtime. This defensive second validation catches altered materialized files.
runner_metadata_validate_runtime_contract() {
  local image_file="$1"
  local runtime_file="$2"
  local tools_file="$3"
  local key=""
  local -A image=()
  local -A runtime=()

  runner_metadata_load_map "$image_file" image || return 1
  runner_metadata_load_map "$runtime_file" runtime || return 1
  for key in RUNNER_IMAGE RUNNER_DOMAIN RUNNER_ROLE RUNNER_VERSION RUNNER_CONTRACT_VERSION RUNNER_IMAGE_VERSION RUNNER_IMAGE_REVISION RUNNER_SUPPORTED_PLATFORM; do
    [[ -n "${image[$key]:-}" ]] || {
      runner_metadata_contract_error "missing ${key}"
      return 1
    }
  done
  [[ "${image[RUNNER_VERSION]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || runner_metadata_contract_error "invalid RUNNER_VERSION" || return 1
  [[ "${image[RUNNER_IMAGE_VERSION]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || runner_metadata_contract_error "invalid RUNNER_IMAGE_VERSION" || return 1
  [[ "${image[RUNNER_IMAGE_REVISION]}" == "local" || "${image[RUNNER_IMAGE_REVISION]}" =~ ^[0-9a-f]{40}$ ]] || runner_metadata_contract_error "invalid RUNNER_IMAGE_REVISION" || return 1
  [[ "${image[RUNNER_CONTRACT_VERSION]}" == "v001" ]] || runner_metadata_contract_error "unsupported RUNNER_CONTRACT_VERSION" || return 1
  [[ "${image[RUNNER_SUPPORTED_PLATFORM]}" == "linux/amd64" ]] || runner_metadata_contract_error "unsupported RUNNER_SUPPORTED_PLATFORM" || return 1
  for key in RUNTIME_USER_NAME RUNTIME_USER_UID RUNTIME_USER_GID RUNTIME_USER_HOME RUNTIME_SHELL RUNTIME_WORKDIR; do
    [[ -n "${runtime[$key]:-}" ]] || {
      runner_metadata_contract_error "missing ${key}"
      return 1
    }
  done
  [[ "${runtime[RUNTIME_USER_NAME]}" =~ ^[a-z_][a-z0-9_-]*$ ]] || runner_metadata_contract_error "invalid RUNTIME_USER_NAME" || return 1
  [[ "${runtime[RUNTIME_USER_UID]}" =~ ^[1-9][0-9]*$ ]] || runner_metadata_contract_error "invalid RUNTIME_USER_UID" || return 1
  [[ "${runtime[RUNTIME_USER_GID]}" =~ ^[1-9][0-9]*$ ]] || runner_metadata_contract_error "invalid RUNTIME_USER_GID" || return 1
  for key in RUNTIME_USER_HOME RUNTIME_SHELL RUNTIME_WORKDIR; do
    [[ "${runtime[$key]}" == /* && "${runtime[$key]}" != *[[:space:]]* ]] || {
      runner_metadata_contract_error "invalid ${key}"
      return 1
    }
  done
  runner_metadata_validate_tool_registry "$tools_file"
}

# Materialize only read-only runtime files. Derived images may invoke this base
# function after supplying a complete declarative manifest, but may not replace
# the parser or dispatcher contract.
runner_metadata_materialize_manifest() {
  local manifest="$1"

  runner_metadata_validate_file "$manifest" || return 1
  grep -qx 'MANIFEST_SCHEMA_VERSION=1' "$manifest" || {
    runner_metadata_contract_error "unsupported MANIFEST_SCHEMA_VERSION"
    return 1
  }
  mkdir -p /etc/runner
  grep '^RUNNER_' "$manifest" | grep -v '^RUNNER_TOOL_' >/etc/runner/image.env
  grep '^RUNTIME_' "$manifest" >/etc/runner/runtime.env
  { grep '^RUNNER_TOOL_' "$manifest" >/etc/runner/tools.env || [[ $? -eq 1 ]]; }
  runner_metadata_validate_runtime_contract /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env || return 1
  chmod 0444 /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env
}

# A derived image supplies only its image identity and tool declarations. The
# base keeps Runner version, contract version, platform, and runtime-user
# metadata authoritative so a derived manifest cannot drift from its parent.
runner_metadata_validate_derived_manifest() {
  local manifest="$1"
  local key=""
  local -A overlay=()

  runner_metadata_load_map "$manifest" overlay || return 1
  for key in "${!overlay[@]}"; do
    case "$key" in
      RUNNER_IMAGE | RUNNER_DOMAIN | RUNNER_ROLE | RUNNER_IMAGE_VERSION | RUNNER_IMAGE_REVISION | RUNNER_DESCRIPTION | RUNNER_VENDOR | RUNNER_LICENSE | RUNNER_REPOSITORY | RUNNER_TOOL_*) ;;
      *)
        runner_metadata_contract_error "derived manifest cannot override ${key}"
        return 1
        ;;
    esac
  done
  for key in RUNNER_IMAGE RUNNER_DOMAIN RUNNER_ROLE RUNNER_IMAGE_VERSION RUNNER_IMAGE_REVISION RUNNER_TOOL_NAMES; do
    if [[ "$key" == "RUNNER_TOOL_NAMES" ]]; then
      [[ -v "overlay[$key]" ]] || {
        runner_metadata_contract_error "derived manifest is missing ${key}"
        return 1
      }
      continue
    fi
    [[ -n "${overlay[$key]:-}" ]] || {
      runner_metadata_contract_error "derived manifest is missing ${key}"
      return 1
    }
  done
}

runner_metadata_materialize_derived_manifest() {
  local manifest="$1"
  local image_tmp="/tmp/runner-derived-image.env"
  local tools_tmp="/tmp/runner-derived-tools.env"

  runner_metadata_validate_derived_manifest "$manifest" || return 1
  grep -v -E '^RUNNER_(IMAGE|DOMAIN|ROLE|IMAGE_VERSION|IMAGE_REVISION|DESCRIPTION|VENDOR|LICENSE|REPOSITORY|TOOL_)' /etc/runner/image.env >"${image_tmp}"
  grep '^RUNNER_' "$manifest" | grep -v '^RUNNER_TOOL_' >>"${image_tmp}"
  grep '^RUNNER_TOOL_' "$manifest" >"${tools_tmp}"
  runner_metadata_validate_runtime_contract "${image_tmp}" /etc/runner/runtime.env "${tools_tmp}" || return 1
  mv "${image_tmp}" /etc/runner/image.env
  mv "${tools_tmp}" /etc/runner/tools.env
  chmod 0444 /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env
}
