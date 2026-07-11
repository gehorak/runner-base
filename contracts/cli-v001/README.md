# CLI v001 contract fixtures

Status: Target contract for `runner-base v0.3.0`; not implemented by the current v0.2.x runtime.

This directory is the machine-reviewable companion to [`docs/CLI-V001.md`](../../docs/CLI-V001.md).

## Contents

- `*.schema.json` define JSON output and behavior-case structure.
- `examples/` contains deterministic, synthetic reference output.
- `behavior-cases.json` freezes canonical, compatibility-bridge, and hard-cutover behavior.

In behavior cases, `stdout` and `stderr` reference Runner-owned output only. When `child_passthrough` is `true`, null `stdout` means Runner adds no stdout, while a deprecation fixture on `stderr` is the single Runner-owned line written in addition to untouched child streams.

Human-readable fixtures are review snapshots, not machine APIs. An unapproved snapshot change blocks a release even though consumers must use JSON for automation.

## Validation

Run from the repository root:

```text
python ci/validate-cli-v001-contract.py
```

The validator uses only the Python standard library. It validates the JSON documents against the schema subset used here, checks fixture references and deterministic ordering, and runs negative self-checks. It does not execute or modify the `runner` runtime.
