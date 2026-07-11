# MAINTENANCE policy for runner-base

## Purpose

This document defines the minimal maintenance policy
for the `runner-base` supply chain and rebuild cadence.

It exists to keep the base image:

* reviewable
* patchable
* reproducible enough for incident response

---

## Base dependency pinning

`runner-base` pins its operating-system parent image by digest.

Rules:

* the human-readable tag MAY remain in the Dockerfile for context
* the effective base dependency MUST be the pinned digest
* digest changes MUST happen through a reviewable pull request or local candidate diff

---

## Patch cadence

Minimum cadence:

* review Docker base digest updates at least monthly
* review GitHub Actions commit pin updates at least monthly
* process critical security updates out of band when needed

The repository uses Dependabot configuration
to keep these updates visible and reviewable.

GitHub Actions in workflow files MUST be pinned
to explicit commit SHAs rather than mutable major tags.

---

## Rebuild policy

Patch and rebuild expectations:

* every release candidate rebuilds from the currently pinned base digest
* every release candidate MUST pass the focused contract test suite before publication
* the release workflow MUST publish the same built image artifact that passed validation

## Supported platform

The only supported and publicly tested platform is `linux/amd64`. A multi-architecture claim requires explicit build and test evidence before it is documented.

## Reproducibility level

The parent image digest and GitHub Action references are pinned. APT package versions are intentionally not individually pinned, so the image is not bit-for-bit reproducible across time. Release rebuilds, monthly dependency review, SBOM generation, provenance attestation, and public release evidence provide the operational traceability required for this maturity level.

## Base dependency inventory

Every installed package has a base-owned reason. Domain-specific tools belong in derived images.

| Dependency | Base-owned reason |
| --- | --- |
| `ca-certificates` | TLS trust for reviewed HTTPS clients. |
| `bash`, `coreutils`, `grep`, `sed`, `mawk` | Runner execution, contract inspection, and portable shell automation. |
| `curl` | Common explicit HTTPS retrieval utility. |
| `git`, `openssh-client` | Explicit source-control and reviewed SSH transport use. |
| `gnupg` | Explicit signature verification for operator workflows. |
| `tar`, `gzip`, `zip`, `unzip` | Common archive handling in automation. |

`wget` is removed as a duplicate HTTP client. `jq` is not a base dependency and is not required by the CLI contract.

---

## Release tag discipline

Public release tags SHOULD point to a dedicated release-preparation commit
on `main`.

That tag target commit SHOULD stay narrow and contain only:

* changelog alignment
* documentation alignment
* small release-gate fixes required for truthful validation

Workflow dependency pin refreshes needed for a release SHOULD land
before the final tag target commit.

---

## Scope boundary

This policy applies only to `runner-base`.

Derived images own their own release cadence,
parent-digest adoption, and domain-specific rebuild policy.

---

**End of document**

---
