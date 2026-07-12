# runner-base

`runner-base` provides a **deterministic container image**
designed for infrastructure, automation, and CI workflows.

The image follows a **strict execution model** focused on:

* explicit behavior
* reproducibility
* auditability
* long-term operational stability  

This repository is the **base component of the runner tooling platform**.
All domain-specific runner images are built on top of this image.

Current published release: `v0.2.6`. This source tree is a local `v0.3.0` compatibility-release candidate: the canonical CLI v001 surface is implemented, while the frozen legacy forms remain deprecated bridge aliases. It is not published or released by this source state.

---

## What this image is

This image is intended to be used as a **tooling runtime**
inside CI pipelines and automation workflows.

It behaves like a **CLI binary**, not like
a general-purpose interactive shell environment.

The image is designed to be:

* predictable
* auditable
* safe to automate
* stable over long periods of time

---

## Execution model

All execution starts from a **single explicit entrypoint**: `runner`.

Commands must be invoked intentionally.
Implicit command forwarding is **not supported**.

If a command is not explicitly supported,
execution will fail with a non-zero exit code.  

This execution model ensures:

* deterministic behavior
* clear audit trails
* safe usage in CI environments
* minimal surprise for operators

---

## What this image provides

This image provides:

* a minimal and explicit runtime environment
* a strict, single execution entrypoint
* a **non-root execution model**
* an explicit `HOME` and writable default `/workspace`

The base image includes **no domain-specific plugins**.

Additional capabilities may be provided
by runner plugins in derived images.

---

## What this image does NOT do

This image explicitly does NOT:

* guess user intent
* implicitly execute system commands
* provide unrestricted shell access
* manage secrets or credentials
* perform orchestration or deployment

These responsibilities belong outside the image
and must be handled by higher-level systems.

---

## Runner interface (stable contract)

The image exposes a **single command-line interface**:

```text
<image> <command> [arguments]
```

### Core commands (available in all runner images)

* `runner --help` and `runner --version`
* `runner info --format text|json`
* `runner tool [--format text|json]` and `runner tool <name> [arguments...]`
* `runner exec -- <program> [arguments...]`
* `runner shell` for interactive human debugging

These commands form the **stable runner contract**
and are guaranteed across all runner images.

---

### Derived tools

Derived images register declarative tool metadata; direct tool commands are deprecated bridge aliases only. The canonical registry is exposed through `runner tool`, not through the image identity command.

Available tools can be listed using:

```bash
docker run --rm <image> tool --format json
docker run --rm runner-base tool
```

The base image ships with **no declared tools** by design.

---

## Usage

This image is intended to be used as a **base image**
for other runner-based tooling images.

Direct usage is intentionally limited to:

* inspection
* debugging
* local experimentation

Local `make` targets in this repository assume
Docker and a **bash-capable environment**.

Example:

```bash
docker run --rm runner-base --help
docker run --rm runner-base info --format json
docker run --rm runner-base exec -- id
```

---

## Security & responsibility

* The image runs as a **non-root user**
* No secrets are embedded in the image
* The image does not manage credentials
* Correct usage and deployment remain
  the responsibility of the user

---

## Documentation

* `CHANGELOG.md` — version history
* `docs/ARCHITECTURE.md` — platform architecture
* `docs/CONTRACT.md` — execution and CLI contract
* `docs/CLI-V001.md` — future CLI target for v0.3.0; not current v0.2.x behavior
* `docs/USAGE.md` — immutable-reference and workspace usage guidance
* `docs/SECURITY.md` — operator security model and container hardening guidance
* `SECURITY.md` — repository security reporting entrypoint
* `docs/DERIVED-IMAGES.md` — normative derived-image authoring contract
* `docs/TROUBLESHOOTING.md` — mount, network, metadata, and root-override diagnostics
* `docs/RELEASES.md` — platform scope, evidence, rollback, yanking, and signing policy
* `docs/MAINTENANCE.md` — base digest, patch cadence, and rebuild policy
* `docs/TESTING.md` — test strategy and guarantees
* `release/README.md` — machine-readable release evidence assets

---

## License

This project is licensed under the **MIT License**.


---

## AI Disclosure

This project uses AI-assisted generation as part of its development process.

AI is used strictly as a **productivity and consistency tool**, not as an
autonomous author or decision-maker.

All architectural decisions, execution contracts, validation logic,
and final approvals are **designed, reviewed, and owned by humans**.

AI-generated outputs are:
- constrained by explicit specifications
- reviewed before publication

AI is **never granted credentials, secrets, or deployment access**.

Responsibility for the project remains **fully human-owned**.


---

### Final note

`runner-base` intentionally prioritizes **clarity over convenience**.

If a behavior is not explicit,
it is considered unsupported.
