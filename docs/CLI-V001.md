# Runner CLI v001 target contract

Status: Implemented locally for the `runner-base v0.3.0` compatibility-release candidate; not yet published or released.

## Release sequence

- `v0.2.4` is the observed released legacy baseline.
- `v0.2.6` is the final legacy stabilization release and preserves the v0.2.x command surface.
- `v0.3.0` is the first implementation of the compatibility bridge defined here.
- `v1.0.0` is the hard cutover to the canonical v001 surface.

The published `v0.2.6` release remains the legacy runtime baseline. This local candidate activates the v001 bridge only when built from this source revision; a public support claim requires its separate release evidence.

## Purpose

This document defines the implemented local compatibility bridge. The released v0.2.x CLI remains authoritative until a public `v0.3.0` release provides implementation evidence, tests, migration notes, and release assets.

## Canonical surface

```text
runner --help
runner --version
runner info --format text|json
runner tool [--format text|json]
runner tool <name> [arguments...]
runner exec -- <program> [arguments...]
runner shell
```

No other command is part of the canonical v001 surface.

## Version output

`runner --version` writes one stable line to stdout and exits with `0`:

```text
runner <version> (contract <contract_version>)
```

The derived image version is reported by `runner info`, not by `runner --version`.

## Structured output

- `text` and `json` are the only metadata formats.
- JSON uses `schema_version: 1` and English keys.
- The `info` object has fixed `runner`, `image`, `runtime`, and `tools` sections.
- Optional fields may be added compatibly; required fields may not be removed or redefined inside schema version `1`.
- Tools use canonical full names such as `terraform` and are sorted by canonical name.
- Human-readable text is not a machine API.
- Human-readable reference files are review snapshots. Consumers must not parse them, but an unapproved change to a snapshot blocks release review.

Schemas and examples live under `contracts/cli-v001/`.

## Output channels

- Successful Runner-owned metadata is written to stdout.
- Runner-native diagnostics and deprecation messages are written to stderr.
- Canonical `tool` invocation and `exec` add no Runner-owned stdout.
- Child stdout, stderr, signals, and exit status pass through unchanged.
- Canonical output is uncolored; integrations must never depend on terminal color.

## Runner-native errors

Runner-native errors use a stable `RUNNER_E_*` identifier, state the cause, and provide a concise actionable hint.

Text diagnostics use two lines on stderr:

```text
RUNNER_E_<ID>: <cause>
Hint: <action>
```

When a metadata command has selected `--format json`, its Runner-native diagnostic uses `error.schema.json` on stderr. Errors that occur before a format is selected use text diagnostics. Secrets and raw environment values must not be included in either form.

| Exit | Family | Meaning |
| ---: | --- | --- |
| `0` | success | Runner-owned operation completed successfully. |
| `2` | `RUNNER_E_USAGE` or `RUNNER_E_FORMAT` | Invalid Runner syntax, delimiter use, or format. |
| `3` | `RUNNER_E_CONTRACT` | Required Runner metadata is missing or invalid. |
| `4` | `RUNNER_E_NOT_FOUND` | Unknown Runner command or tool. |
| `126` | `RUNNER_E_NOT_EXECUTABLE` | A known tool cannot be executed. |

These codes apply only to Runner-owned failures. A started child process retains its own exit status, including values that overlap this table.

## Tool identity and invocation

- Tool registry entries use canonical full names.
- A compatibility alias such as `tf` is not a canonical tool identity.
- In `v0.3.0`, a declared tool-name alias such as `runner tool tf` emits one deprecation message to stderr and resolves to its canonical name; tool-name aliases are removed in `v1.0.0`.
- `runner tool <name> [arguments...]` performs transparent argument and process passthrough.
- Derived images may declare tools through the base-owned metadata contract but may not create a new canonical direct `runner <name>` command.

## Exec delimiter

The canonical form requires the delimiter:

```text
runner exec -- <program> [arguments...]
```

The first token after `--` is the program. All following tokens are passed unchanged. Missing `--` or a missing program is a Runner usage error in the canonical contract.

## Compatibility bridge

`runner-base v0.3.0` is the compatibility bridge:

| Legacy form | Canonical form | Bridge behavior |
| --- | --- | --- |
| `runner about` | `runner info --format text` | Run canonical behavior and emit one deprecation message to stderr. |
| `runner version` | `runner --version` | Run canonical behavior and emit one deprecation message to stderr. |
| `runner <plugin> ...` | `runner tool <name> ...` | Invoke the mapped canonical tool and emit one deprecation message to stderr. |
| `runner exec <program> ...` | `runner exec -- <program> ...` | Preserve arguments and child status; emit one deprecation message to stderr. |

The deprecation message must not change successful data output or the child exit status. No new direct plugin command may be introduced during the bridge.

## Hard cutover

In `runner-base v1.0.0`, `about`, direct `version`, direct plugin commands, and delimiter-free `exec` are removed from the public contract. Only the canonical v001 surface remains supported.

## Explicit non-goals

- workflow commands such as `check`, `plan`, or `apply`;
- `--dry-run`, global config precedence, or deployment approvals;
- YAML metadata output or JSONL execution logging;
- `runner doctor`;
- colored canonical output;
- implicit credential, backend, environment, or orchestration policy.

## Implementation gate

Dispatcher implementation may begin only after:

1. schemas and deterministic examples validate;
2. version, help, output-channel, error, and exit-code fixtures are reviewed;
3. canonical `exec --`, all bridge aliases, and hard-cutover removals are represented in behavior fixtures;
4. current v0.2.x runtime behavior remains unchanged by the contract-first package.

The public gate command is:

```text
python ci/validate-cli-v001-contract.py
```
