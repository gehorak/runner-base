# runner-base

This repository provides a **deterministic container image**
designed for infrastructure, automation and CI workflows.

The image follows a **strict execution model**
focused on explicit behavior, reproducibility
and long-term operational stability.

This repository is the base component of a unified tooling platform.

---

## What is this image

This image is intended to be used as a **tooling runtime**
inside CI pipelines and automation workflows.

It behaves like a **CLI binary**, not like
a general-purpose interactive shell environment.

The image is designed to be:
- predictable
- auditable
- safe to automate
- stable over long periods of time

---

## Execution model

All execution starts from a **single explicit entrypoint** (`runner`).

Commands must be invoked intentionally.
Implicit command forwarding is **not supported**.

This design ensures:
- deterministic behavior
- clear audit trails
- safe usage in CI environments
- minimal surprise for operators

If a command is not explicitly supported,
the execution will fail.

---

## What this image provides

This image provides:
- a minimal and explicit runtime environment
- a strict execution entrypoint
- a non-root execution model

No domain-specific plugins are included.

Additional capabilities are provided
via runner plugins defined by this image variant.

---

## What this image does NOT do

This image does NOT:
- guess user intent
- implicitly execute commands
- provide unrestricted shell access
- manage secrets or credentials
- perform orchestration or deployment

Those responsibilities belong outside the image.

---

## Runner interface (stable contract)

The image exposes a single command-line interface:

```text
<image> <command> [arguments]
````

### Core commands (available in all images)

* help      — show available commands
* about     — show image identity
* info      — display runtime and plugin information
* exec      — execute a command explicitly
* shell     — start an interactive shell (human use only)
* version   — show available tool versions

### Plugin commands

Additional commands may be provided
by image-specific runner plugins.

Available plugins can be listed using:

```bash
docker run --rm <image> info
```

---

## Usage

This image is intended to be used as a base
for other tooling images.

Direct usage is limited to inspection
and debugging purposes.

---

## Security & responsibility

* The image runs as a non-root user
* No secrets are embedded in the image
* The image does not manage credentials
* Correct usage and deployment remain
  the responsibility of the user

---

## Documentation

* `CHANGELOG.md` — version history

---

## License

This project is licensed under the MIT License.

````