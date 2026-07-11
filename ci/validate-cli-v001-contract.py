#!/usr/bin/env python3
"""Validate the future CLI v001 contract package without executing Runner."""

from __future__ import annotations

import copy
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "contracts" / "cli-v001"


class ContractError(ValueError):
    """Raised when a schema, example, or cross-file invariant fails."""


def load_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractError(f"{path.relative_to(ROOT)}: {exc}") from exc


def json_type_matches(value: Any, expected: str) -> bool:
    checks = {
        "array": lambda item: isinstance(item, list),
        "boolean": lambda item: isinstance(item, bool),
        "integer": lambda item: isinstance(item, int) and not isinstance(item, bool),
        "null": lambda item: item is None,
        "number": lambda item: isinstance(item, (int, float)) and not isinstance(item, bool),
        "object": lambda item: isinstance(item, dict),
        "string": lambda item: isinstance(item, str),
    }
    if expected not in checks:
        raise ContractError(f"unsupported schema type: {expected}")
    return checks[expected](value)


def resolve_ref(schema_path: Path, reference: str) -> tuple[dict[str, Any], Path]:
    file_part, separator, fragment = reference.partition("#")
    target_path = schema_path if not file_part else schema_path.parent / file_part
    target = load_json(target_path)
    if separator and fragment:
        current: Any = target
        for raw_part in fragment.lstrip("/").split("/"):
            part = raw_part.replace("~1", "/").replace("~0", "~")
            current = current[part]
        target = current
    if not isinstance(target, dict):
        raise ContractError(f"{schema_path.name}: $ref does not resolve to an object: {reference}")
    return target, target_path


def validate(value: Any, schema: dict[str, Any], schema_path: Path, location: str = "$") -> None:
    if "$ref" in schema:
        resolved, resolved_path = resolve_ref(schema_path, schema["$ref"])
        validate(value, resolved, resolved_path, location)
        return

    if "oneOf" in schema:
        matches = 0
        for candidate in schema["oneOf"]:
            try:
                validate(value, candidate, schema_path, location)
                matches += 1
            except ContractError:
                pass
        if matches != 1:
            raise ContractError(f"{location}: expected exactly one matching schema, got {matches}")

    if "const" in schema and value != schema["const"]:
        raise ContractError(f"{location}: expected constant {schema['const']!r}, got {value!r}")
    if "enum" in schema and value not in schema["enum"]:
        raise ContractError(f"{location}: {value!r} is not in {schema['enum']!r}")

    expected_types = schema.get("type")
    if expected_types is not None:
        if isinstance(expected_types, str):
            expected_types = [expected_types]
        if not any(json_type_matches(value, item) for item in expected_types):
            raise ContractError(f"{location}: expected type {expected_types!r}, got {type(value).__name__}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        missing = [key for key in required if key not in value]
        if missing:
            raise ContractError(f"{location}: missing required properties {missing!r}")
        properties = schema.get("properties", {})
        for key, item in value.items():
            if key in properties:
                validate(item, properties[key], schema_path, f"{location}.{key}")
            elif schema.get("additionalProperties") is False:
                raise ContractError(f"{location}: unexpected property {key!r}")

    if isinstance(value, list):
        item_schema = schema.get("items")
        if item_schema is not None:
            for index, item in enumerate(value):
                validate(item, item_schema, schema_path, f"{location}[{index}]")
        if schema.get("uniqueItems"):
            normalized = [json.dumps(item, sort_keys=True) for item in value]
            if len(normalized) != len(set(normalized)):
                raise ContractError(f"{location}: array items are not unique")

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise ContractError(f"{location}: string is shorter than minLength")
        pattern = schema.get("pattern")
        if pattern is not None and re.search(pattern, value) is None:
            raise ContractError(f"{location}: {value!r} does not match {pattern!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            raise ContractError(f"{location}: {value!r} is below minimum {schema['minimum']!r}")


def validate_document(document_path: Path, schema_path: Path) -> Any:
    document = load_json(document_path)
    schema = load_json(schema_path)
    validate(document, schema, schema_path)
    return document


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def check_tool_order(tools: list[dict[str, Any]], location: str) -> None:
    names = [tool["name"] for tool in tools]
    require(names == sorted(names), f"{location}: tools must be sorted by canonical name")
    require(len(names) == len(set(names)), f"{location}: canonical tool names must be unique")
    for tool in tools:
        aliases = tool.get("aliases", [])
        require(aliases == sorted(aliases), f"{location}: aliases for {tool['name']} must be sorted")
        require(tool["name"] not in aliases, f"{location}: canonical name cannot also be an alias")


def check_fixture_reference(reference: str, case_id: str) -> Path:
    target = (CONTRACT / reference).resolve()
    try:
        target.relative_to(CONTRACT.resolve())
    except ValueError as exc:
        raise ContractError(f"{case_id}: fixture escapes contract directory: {reference}") from exc
    require(target.is_file(), f"{case_id}: missing fixture {reference}")
    require(target.stat().st_size > 0, f"{case_id}: empty fixture {reference}")
    return target


def check_behavior(cases_document: dict[str, Any]) -> None:
    cases = cases_document["cases"]
    ids = [case["id"] for case in cases]
    require(len(ids) == len(set(ids)), "behavior-cases.json: case IDs must be unique")

    mandatory = {
        "canonical-help", "canonical-version", "canonical-info-text", "canonical-info-json",
        "canonical-tool-list-default", "canonical-tool-list-text", "canonical-tool-list-json", "canonical-tool-invoke",
        "canonical-exec", "canonical-shell", "error-invalid-format",
        "error-exec-missing-delimiter", "error-exec-missing-program", "error-invalid-metadata",
        "error-unknown-command", "error-unknown-tool", "error-invalid-metadata-json",
        "error-tool-not-executable", "bridge-about", "bridge-version", "bridge-direct-tool", "bridge-tool-name-alias",
        "bridge-exec-without-delimiter", "cutover-about-removed", "cutover-version-removed",
        "cutover-direct-tool-removed", "cutover-tool-name-alias-removed", "cutover-exec-delimiter-required",
    }
    require(mandatory <= set(ids), f"behavior-cases.json: missing mandatory cases {sorted(mandatory - set(ids))}")

    for case in cases:
        case_id = case["id"]
        for channel in ("stdout", "stderr"):
            reference = case[channel]
            if reference is not None:
                check_fixture_reference(reference, case_id)

        if case["child_passthrough"]:
            require(case["exit"] == "child", f"{case_id}: passthrough case must preserve child exit")
            require(case["stdout"] is None, f"{case_id}: Runner must not own child stdout")
        else:
            require(case["exit"] != "child", f"{case_id}: Runner-owned case needs a numeric exit")

        if case["phase"] == "bridge":
            require(case["stderr"] is not None and "deprecation-" in case["stderr"],
                    f"{case_id}: bridge alias needs exactly one deprecation fixture")
        if case["phase"] == "cutover":
            require(isinstance(case["exit"], int) and case["exit"] != 0,
                    f"{case_id}: removed cutover form must fail as Runner-owned behavior")


def negative_self_checks(info_schema: dict[str, Any], info_schema_path: Path,
                         tool_schema: dict[str, Any], tool_schema_path: Path,
                         info: dict[str, Any], tools: dict[str, Any]) -> None:
    invalid_version = copy.deepcopy(info)
    invalid_version["schema_version"] = 2
    invalid_name = copy.deepcopy(tools)
    invalid_name["tools"][0]["name"] = "Terraform"
    for value, schema, path, label in (
        (invalid_version, info_schema, info_schema_path, "schema_version mutation"),
        (invalid_name, tool_schema, tool_schema_path, "canonical-name mutation"),
    ):
        try:
            validate(value, schema, path)
        except ContractError:
            continue
        raise ContractError(f"validator self-check failed to reject {label}")


def main() -> int:
    info_schema_path = CONTRACT / "info.schema.json"
    tool_schema_path = CONTRACT / "tool-list.schema.json"
    error_schema_path = CONTRACT / "error.schema.json"
    behavior_schema_path = CONTRACT / "behavior-cases.schema.json"

    info = validate_document(CONTRACT / "examples" / "info.json", info_schema_path)
    tools = validate_document(CONTRACT / "examples" / "tools.json", tool_schema_path)
    validate_document(CONTRACT / "examples" / "error.json", error_schema_path)
    behavior = validate_document(CONTRACT / "behavior-cases.json", behavior_schema_path)

    check_tool_order(info["tools"], "examples/info.json")
    check_tool_order(tools["tools"], "examples/tools.json")
    require(info["tools"] == tools["tools"], "info and tool-list examples must expose identical tools")

    version_line = (CONTRACT / "examples" / "version.txt").read_text(encoding="utf-8").strip()
    expected_version = f"runner {info['runner']['version']} (contract {info['runner']['contract_version']})"
    require(version_line == expected_version, "version.txt does not match examples/info.json")

    check_behavior(behavior)
    negative_self_checks(load_json(info_schema_path), info_schema_path,
                         load_json(tool_schema_path), tool_schema_path, info, tools)

    print("OK: CLI v001 contract schemas, examples, and behavior fixtures are valid")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ContractError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
