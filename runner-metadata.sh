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
  local -n target="$target_name"

  target=()
  RUNNER_METADATA_TARGET_MAP_NAME="$target_name"
  runner_metadata_parse_file "$file" runner_metadata_collect_pair || return 1
  unset RUNNER_METADATA_TARGET_MAP_NAME
}

runner_metadata_is_reserved_tool_name() {
  case "$1" in
    help|info|tool|exec|shell|version|about|runner)
      return 0
      ;;
  esac
  return 1
}

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

runner_metadata_tool_key() {
  local name="$1"
  name="${name^^}"
  printf '%s' "${name//-/_}"
}

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

runner_metadata_validate_runtime_contract() {
  local image_file="$1"
  local runtime_file="$2"
  local tools_file="$3"
  local key=""
  local -A image=()
  local -A runtime=()

  runner_metadata_load_map "$image_file" image || return 1
  runner_metadata_load_map "$runtime_file" runtime || return 1
  for key in RUNNER_IMAGE RUNNER_DOMAIN RUNNER_ROLE RUNNER_VERSION RUNNER_CONTRACT_VERSION RUNNER_IMAGE_VERSION RUNNER_SUPPORTED_PLATFORM; do
    [[ -n "${image[$key]:-}" ]] || {
      runner_metadata_contract_error "missing ${key}"
      return 1
    }
  done
  [[ "${image[RUNNER_VERSION]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || runner_metadata_contract_error "invalid RUNNER_VERSION" || return 1
  [[ "${image[RUNNER_CONTRACT_VERSION]}" == "v001" ]] || runner_metadata_contract_error "unsupported RUNNER_CONTRACT_VERSION" || return 1
  [[ "${image[RUNNER_SUPPORTED_PLATFORM]}" == "linux/amd64" ]] || runner_metadata_contract_error "unsupported RUNNER_SUPPORTED_PLATFORM" || return 1
  for key in RUNTIME_USER_NAME RUNTIME_USER_UID RUNTIME_USER_GID RUNTIME_USER_HOME RUNTIME_SHELL RUNTIME_WORKDIR; do
    [[ -n "${runtime[$key]:-}" ]] || {
      runner_metadata_contract_error "missing ${key}"
      return 1
    }
  done
  runner_metadata_validate_tool_registry "$tools_file"
}

runner_metadata_materialize_manifest() {
  local manifest="$1"

  runner_metadata_validate_file "$manifest" || return 1
  grep -qx 'MANIFEST_SCHEMA_VERSION=1' "$manifest" || {
    runner_metadata_contract_error "unsupported MANIFEST_SCHEMA_VERSION"
    return 1
  }
  mkdir -p /etc/runner
  grep '^RUNNER_' "$manifest" | grep -v '^RUNNER_TOOL_' > /etc/runner/image.env
  grep '^RUNTIME_' "$manifest" > /etc/runner/runtime.env
  { grep '^RUNNER_TOOL_' "$manifest" > /etc/runner/tools.env || [[ $? -eq 1 ]]; }
  runner_metadata_validate_runtime_contract /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env || return 1
  chmod 0444 /etc/runner/image.env /etc/runner/runtime.env /etc/runner/tools.env
}
