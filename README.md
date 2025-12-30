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

* `help`
  Show available commands

* `about`
  Show image identity

* `info`
  Display runtime and plugin information

* `exec`
  Execute a system command explicitly

* `shell`
  Start an interactive shell (human use only)

* `version`
  Show available tool versions

These commands form the **stable runner contract**
and are guaranteed across all runner images.

---

### Plugin commands

Additional commands may be provided
by image-specific runner plugins.

Available plugins can be listed using:

```bash
docker run --rm <image> info
docker run --rm runner-base info
```

The base image ships with **no plugins** by design.

---

## Usage

This image is intended to be used as a **base image**
for other runner-based tooling images.

Direct usage is intentionally limited to:

* inspection
* debugging
* local experimentation

Example:

```bash
docker run --rm runner-base help
docker run --rm runner-base about
docker run --rm runner-base info
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
* `docs/TESTING.md` — test strategy and guarantees

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

