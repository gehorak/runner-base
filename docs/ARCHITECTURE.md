# ARCHITECTURE of Runner Platform (v0.2.0)

## Purpose

This document describes the **architectural principles, structure,
and invariants** of the runner platform as of version **v0.2.0**.

It explains:

* how the platform is structured
* how responsibilities are separated
* which design decisions are intentional and stable
* which concerns are explicitly out of scope

This document is **normative at the architectural level**.

If the system violates the principles defined here,
it is considered an architectural defect.

Behavioral guarantees are defined separately
in `docs/CONTRACT.md`.

---

## Platform overview

The runner platform provides a **deterministic execution environment**
for tooling images used in infrastructure automation and CI workflows.

The platform consists of:

* a **base image** (`runner-base`)
* a **single execution entrypoint** (`runner`)
* an **explicit plugin mechanism**
* a **strict execution model**

All domain-specific images (terraform, ansible, kubectl, …)
extend the base image without modifying the platform architecture.

---

## Design goals

The platform is designed around the following long-term goals:

* explicit behavior over convenience
* predictability and reproducibility
* minimal and auditable surface area
* clear separation of responsibilities
* long-term operational stability

Short-term convenience and implicit behavior
are intentionally deprioritized.

---

## Layered architecture

The runner platform is intentionally layered.

Each layer has **a single, clearly defined responsibility**.

```
+---------------------------------------------------+
| Domain Image (terraform, ansible, kubectl, …)     |
| - domain tooling                                  |
| - domain-specific plugins                         |
+---------------------------------------------------+
| runner-base                                       |
| - execution model                                 |
| - security baseline                               |
| - plugin mechanism                                |
+---------------------------------------------------+
| runner (entrypoint)                               |
| - command dispatch                                |
| - contract enforcement                            |
+---------------------------------------------------+
```

No layer is allowed to assume responsibilities
belonging to another layer.

---

## runner-base responsibilities

The base image defines the **platform foundation**.

It is responsible for:

* establishing the execution model
* enforcing non-root execution
* providing a minimal runtime environment
* exposing a stable plugin mechanism
* materializing image identity at runtime

The base image intentionally provides **no domain-specific tooling**.

---

## Execution model (architectural view)

All execution is routed through a **single entrypoint**: `runner`.

From an architectural perspective, this ensures:

* a single control point for execution
* uniform behavior across all images
* enforceable invariants

The **exact behavioral rules** of command execution
are defined in `docs/CONTRACT.md`.

---

## Command dispatch architecture

The runner follows a strictly ordered dispatch model:

1. core commands
2. plugin commands
3. explicit failure

There is no guessing, fallback, or implicit forwarding.

This dispatch order is an **architectural invariant**.
Behavioral details are defined in the contract.

---

## Plugin architecture

Plugins provide domain-specific extensions.

Architectural properties:

* plugins are executable files
* located in `/usr/local/lib/runner.d/`
* discovered explicitly at runtime
* invoked only by name

The base image guarantees the presence of the plugin mechanism
but ships with **no plugins**.

---

## Image identity architecture

Each image materializes its identity at runtime via:

```
/etc/runner/image.env
```

Architecturally:

* identity is produced at build time
* identity is immutable at runtime
* identity is human-readable
* identity is part of the platform boundary

The exact identity fields and exposure rules
are defined in `docs/CONTRACT.md`.

Image identity is derived from the build-time image manifest
and materialized explicitly for runtime consumption.

---

## Image manifest and contract materialization

The runner platform distinguishes **build-time configuration**
from **runtime-visible contract artifacts**.

### Image manifest (build-time source of truth)

Each runner image is defined at build time by a manifest file:

```text
image.manifest
```

Architecturally, the manifest:

* is the **single source of truth** for image identity and runtime intent
* exists **only at build time**
* is not part of the runtime interface
* MUST NOT be accessed by runtime code

The manifest defines, among others:

* image identity metadata
* runtime user parameters
* declared tooling metadata
* platform classification (image / domain / role)

The manifest is an **internal build artifact**,
not a public or runtime-facing interface.

---

### Contract materialization

During image build, selected manifest values are **materialized**
into explicit runtime contract files under:

```
/etc/runner/
```

This materialization step creates:

* `/etc/runner/image.env`   — image identity (public, stable)
* `/etc/runner/runtime.env` — runtime execution context
* `/etc/runner/tools.env`   — declared tooling metadata (if any)

Architectural guarantees:

* runtime code MUST read only materialized files
* the original manifest MUST NOT be consulted at runtime
* materialized files are immutable at runtime
* materialization is additive and explicit

This separation ensures:

* clean boundary between build-time and runtime concerns
* stable runtime behavior independent of build tooling
* auditable and predictable runtime state

---

### Relationship to the contract

From an architectural perspective:

* **`image.manifest`** defines *intent*
* **`/etc/runner/*.env`** define *runtime contract*

Behavioral guarantees and required fields
are defined in `docs/CONTRACT.md`.

The architecture guarantees **how** the contract is produced,
not **what** exact behavior it enforces.

---

## Runtime user model (architectural intent)

The platform enforces **non-root execution** as a first-class invariant.

Architectural intent:

* reduce accidental privilege escalation
* enforce explicit intent for system access
* ensure consistent CI behavior

Specific enforcement rules are defined in the contract.

---

## Out-of-scope concerns

The runner platform explicitly does NOT address:

* secret management
* credential injection
* orchestration or scheduling
* environment provisioning
* performance optimization

These concerns belong to higher-level systems.

---

## Testing as architectural enforcement

The test suite is part of the architecture.

Tests exist to enforce:

* architectural invariants
* absence of forbidden behavior
* stability of platform boundaries

If an architectural rule is not tested,
it is not considered enforced.

See `docs/TESTING.md` for details.

---

## Versioning and change discipline

The platform follows **Semantic Versioning**.

Architectural changes MUST be reflected in:

* this document
* `docs/CONTRACT.md`
* the changelog
* the test suite

Undocumented architectural changes are considered defects.

---

## Architectural invariants (v0.2.0)

The following invariants define the runner platform in v0.2.0:

* single explicit entrypoint
* layered responsibility separation
* no implicit command execution
* non-root execution model
* explicit plugin mechanism
* immutable image identity

Any violation of these invariants is a bug.

---

## Summary

The runner platform prioritizes **clarity, safety, and stability**
over flexibility or convenience.

If a behavior is not explicit,
it is intentionally unsupported.

---

**End of document**

---

