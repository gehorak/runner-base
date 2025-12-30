# TESTING strategy for runner platform (v0.2.0)

## Purpose

This document defines the **testing philosophy, structure, and guarantees**
of the runner platform and all derived runner images.

The purpose of the test suite is **contract protection**, not exhaustive validation.

Tests are designed to:

* protect long-term platform stability
* prevent accidental regressions
* enforce explicit execution behavior
* remain readable and auditable over time

This document is normative.

---

## Scope

This testing strategy applies to:

* `runner-base`
* all derived runner images (e.g. terraform, ansible, kubectl)
* CI pipelines
* local developer workflows

If a behavior is **not covered by tests defined here**,
it is **not guaranteed by the platform**.

---

## Core Principles

### 1. Contract over implementation

Tests validate **observable behavior**, not internal implementation details.

* Tests assert *what the image does*, not *how it is implemented*
* Internal refactors MUST NOT break tests if external behavior is unchanged

This principle ensures long-term freedom to refactor internals
without breaking consumers or automation.

---

### 2. Explicit behavior only

All tests reflect the core platform rule:

> **Explicit behavior is always preferred over convenience.**

Implications:

* implicit command execution is forbidden
* no guessing or fallback behavior is allowed
* all system commands MUST be executed via `runner exec`

Any deviation is considered a **contract violation**.

---

### 3. High signal, low noise

Tests are intentionally:

* small
* fast
* focused

A test MUST fail **only when a real contract violation occurs**.

False positives, flaky behavior, or environment-sensitive tests
are unacceptable.

---

### 4. Stability over cleverness

Tests favor:

* simple shell constructs
* exit codes over output parsing
* filesystem state over formatted text
* explicit assertions over clever logic

Durability and predictability are prioritized
over sophistication.

---

## Test Categories

The test suite is divided into **clear, non-overlapping categories**.

Each category has exactly one responsibility
and a well-defined scope.

---

### Smoke Tests (`test-smoke.sh`)

**Purpose**

* Verify that the image starts correctly
* Verify the runner entrypoint is functional
* Verify non-root execution

**Characteristics**

* fast
* shallow
* high-signal

**Guarantees**

* the image can be executed
* the runner responds to basic commands
* the runtime user is non-root

---

### Core Contract Tests (`test-runner-core.sh`)

**Purpose**

* Protect the stable runner CORE interface
* Ensure backward compatibility across releases

**Covered commands**

* `help`
* `about`
* `info`
* `exec`
* `version`

**Guarantees**

* all core commands exist
* commands execute successfully
* basic command semantics are preserved

Exact output formatting is intentionally not tested.

---

### Negative Tests (`test-negative.sh`)

**Purpose**

* Ensure forbidden behavior remains forbidden
* Protect the explicit execution model

**Guarantees**

* implicit system command execution fails
* unknown runner commands fail explicitly
* no command guessing or forwarding occurs

Negative tests are **first-class contract guards**
and are as important as positive tests.

---

### Image Identity Tests (`test-image-identity.sh`)

**Purpose**

* Verify image identity is present and consistent
* Protect the image identity contract

**Guarantees**

* `/etc/runner/image.env` exists and is non-empty
* required identity keys are present
* identity is exposed via `runner about`

Exact formatting is intentionally not validated.

---

### Plugin Tests (`test-runner-plugins.sh`)

**Purpose**

* Verify plugin mechanism integrity
* Ensure base image minimalism

**Guarantees (base image)**

* plugin directory exists
* no domain-specific plugins are present

Derived images MAY extend this test
to validate their own plugin behavior.

---

### Domain Tests (`test-domain.sh`)

**Purpose**

* Verify domain-specific tooling in derived images

**Base image**

* contains no domain tests
* provides a template only

**Derived images**

* MUST add explicit tests for provided tools
* MUST validate behavior, not just binary presence

Example:

```bash
docker run --rm "${IMAGE}" exec terraform version
```

---

## What Tests Do NOT Cover

The test suite intentionally does NOT cover:

* performance characteristics
* internal shell functions
* implementation details of the runner
* exact wording or formatting of output
* CI system behavior itself

These concerns are explicitly out of scope.

---

## Local vs CI Usage

### Local development

Tests are designed to be:

* runnable via `make test`
* readable in terminal output
* fast enough for frequent execution

### CI pipelines

In CI, tests act as:

* contract gates
* regression protection
* release blockers

A failing test indicates a **platform-level issue**
and MUST be treated as such.

---

## Adding New Tests

When adding a test:

1. Choose the correct category
2. Validate **behavior**, not implementation
3. Avoid testing formatting or text layout
4. Prefer exit codes and filesystem state
5. Keep tests explicit and readable

If a test does not clearly protect a contract,
it likely does not belong in this suite.

---

## Summary

The runner test suite is intentionally conservative.

Its value lies not in coverage percentage, but in:

* predictability
* clarity
* long-term stability

If a behavior is not explicit and not tested,
it is considered unsupported.

---

**End of document**

---