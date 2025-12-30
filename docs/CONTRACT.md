# Runner Platform CONTRACT (v0.2.0)

## Purpose

This document defines the **execution and interface contract**
of the runner platform as of version **v0.2.0**.

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
docker run --rm <image> help
docker run --rm <image> exec terraform version

# INVALID (MUST fail)
docker run --rm <image> terraform version
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

## Core command interface (stable)

The following commands form the **stable runner core interface**
and are guaranteed in **all runner images**:

| Command   | Purpose                                     |
| --------- | ------------------------------------------- |
| `help`    | Display available commands                  |
| `about`   | Display image identity                      |
| `info`    | Display runtime and plugin information      |
| `exec`    | Execute a system command explicitly         |
| `shell`   | Start an interactive shell (human use only) |
| `version` | Display available tool versions             |

### Stability guarantees

* Removing a core command requires a **MAJOR** version bump
* Changing command semantics requires a **MAJOR** version bump
* Adding a new core command requires a **MINOR** version bump

---

## System command execution

System commands MUST NOT be executed implicitly.

The **only permitted escape hatch** for executing system commands is:

```
runner exec <command> [arguments]
```

This requirement applies uniformly to:

* local usage
* CI pipelines
* automation scripts

---

## Plugin mechanism

### Plugin discovery

Plugins are executable files located in:

```
/usr/local/lib/runner.d/
```

The runner discovers plugins explicitly from this directory.

---

### Plugin invocation

* plugins are invoked only by explicit name
* plugins are never auto-executed
* plugins MUST NOT override core commands

If a plugin name conflicts with a core command,
the core command MUST take precedence.

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
runner about
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

Running the container as root is considered
a **contract violation**.

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

---

## Testing and enforcement

This contract is enforced by:

* the automated test suite
* CI pipelines
* release gating

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