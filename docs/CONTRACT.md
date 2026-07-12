# Runner Platform CONTRACT (v0.3.0 compatibility bridge)

## Purpose

This document defines the **execution and interface contract**
of the local v0.3.0 compatibility-release candidate. The published v0.2.6
release remains the legacy public baseline until v0.3.0 is separately released.

It specifies:

* which behavior is guaranteed
* which behavior is explicitly forbidden
* which interfaces are stable
* which changes require a major version bump

This document is **normative**.

If the observable behavior of an image contradicts this document,
the behavior is considered a **bug**, not an alternative interpretation.

---

## Scope

This contract applies to:

* `runner-base`
* all derived runner images
* the `runner` entrypoint
* all CI and automation usage of runner images

Any behavior not explicitly defined in this document is
**out of scope and unsupported**.

---

## Execution model

### Single entrypoint

All runner images expose a **single execution entrypoint**:

```
runner
```

All container execution is routed exclusively through this entrypoint.

No alternative entrypoints or fallback execution paths are permitted.

---

### Explicit invocation

All commands MUST be invoked explicitly.

```
<image> <command> [arguments]
```

Implicit command execution is **forbidden**.

Examples:

```bash
# VALID
docker run --rm <image> --help
docker run --rm <image> exec -- terraform version

# INVALID (MUST fail)
docker run --rm <image> ls
```

This rule guarantees:

* deterministic behavior
* safe CI execution
* clear audit trails

---

### Failure behavior

If a command is not explicitly supported:

* execution MUST fail
* a non-zero exit code MUST be returned
* no guessing, forwarding, or fallback behavior is allowed

Silent fallbacks are explicitly forbidden.

---

## Canonical command interface

The following commands form the **stable runner core interface**
and are guaranteed in **all runner images**:

| Command | Purpose |
| --- | --- |
| `runner --help` | Display canonical commands and bridge migration context. |
| `runner --version` | Display Runner and contract versions. |
| `runner info --format text\|json` | Display image, runtime, and tool metadata. |
| `runner tool [--format text\|json]` | List declaratively registered tools. |
| `runner tool <name> [arguments...]` | Transparently execute a registered tool. |
| `runner exec -- <program> [arguments...]` | Transparently execute an explicit program. |
| `runner shell` | Start an interactive shell only. |

### Stability guarantees

* `about`, direct `version`, direct declared-tool commands, declared aliases, and delimiter-free `exec` are deprecated bridge aliases and are removed only in `v1.0.0`.
* Runner-native failures use exit codes `2`, `3`, `4`, or `126`; started child processes retain their exit status.
* JSON is the machine interface; human text output is not a data protocol.

---

## System command execution

System commands MUST NOT be executed implicitly.

The **only permitted escape hatch** for executing system commands is:

```
runner exec -- <command> [arguments]
```

This requirement applies uniformly to:

* local usage
* CI pipelines
* automation scripts

---

## Declarative tool registry

### Tool declaration

Derived images declare a lexical `RUNNER_TOOL_NAMES` list plus per-tool version,
explicit executable binding, and optional aliases. The base validator materializes
that data into `/etc/runner/tools.env` at build time and validates it defensively
again at runtime.

---

### Tool invocation

* tools are invoked only through `runner tool <name>` or a documented bridge alias;
* directory contents never define the public command surface;
* tool identities and aliases match `^[a-z][a-z0-9-]*$` and cannot use reserved Runner names;
* every tool has an explicit executable or transparent adapter binding;
* unknown direct commands are never forwarded to the system.

---

### Base image guarantees

The base image (`runner-base`) guarantees:

* the plugin directory exists
* the plugin directory is expected to be empty
* no domain-specific tooling is present

---

## Image identity contract

### Identity materialization

Each image MUST materialize its identity at runtime in:

```
/etc/runner/image.env
```

This file MUST:

* exist at runtime
* be non-empty
* be readable
* contain immutable, human-readable metadata

Materialized contract metadata use a strict literal `KEY=VALUE` format.
They are parsed as data, not as shell code.
Comments and blank lines MAY appear, but `export` prefixes, quotes,
duplicate keys, multiline values, and shell control syntax are unsupported.

---

### Required identity fields

The following keys MUST be present:

* `RUNNER_IMAGE`
* `RUNNER_DOMAIN`
* `RUNNER_ROLE`

Additional keys MAY be present.

---

### Identity exposure

Image identity MUST be exposed via:

```
runner info --format text
```

The exact output formatting is not part of the contract,
but the identity information MUST be human-readable.

---

## Runtime user contract

### Non-root execution

All runner images MUST:

* run as a non-root user
* avoid implicit privilege escalation
* require explicit intent for shell access
* reject effective UID `0` at runtime, even if the container runtime overrides the configured image user

Running the container as root is considered
a **contract violation**.

---

### Home and workspace

All runner images MUST:

* set `HOME` to the declared runtime home
* expose the declared runtime workdir as the default working directory
* ensure the declared runtime workdir exists and is writable for the runtime user

---

### Shell access

Interactive shell access:

* is available exclusively via `runner shell`
* is intended for human debugging only
* MUST NOT be relied upon for automation or CI workflows

---

## Domain images

Derived (domain) images MAY:

* add plugins
* add domain-specific tooling
* extend `runner info` output

Derived images MUST NOT:

* change the execution model
* remove or alter core commands
* introduce implicit behavior
* weaken non-root guarantees

See `docs/DERIVED-IMAGES.md` for the normative authoring boundary and `docs/CLI-V001.md` for the future, not-yet-implemented CLI target.

---

## Testing and enforcement

This contract is enforced by:

* the automated test suite
* CI pipelines
* release gating
* release gating that validates and publishes the same built image artifact

If a behavior is not covered by tests,
it is **not guaranteed**.

See `docs/TESTING.md` for details.

---

## Versioning and change policy

The runner platform follows **Semantic Versioning**.

| Change type               | Version impact |
| ------------------------- | -------------- |
| Execution model change    | MAJOR          |
| Core interface change     | MAJOR          |
| Additive behavior         | MINOR          |
| Bug fixes / documentation | PATCH          |

Any change affecting this contract MUST be reflected in:

* this document
* the changelog
* the test suite

---

## Summary

The runner platform contract is intentionally strict.

* explicit behavior is mandatory
* convenience is secondary
* safety and predictability are prioritized

If a behavior is not explicitly defined here,
it is considered unsupported.

---

**End of document**

---
