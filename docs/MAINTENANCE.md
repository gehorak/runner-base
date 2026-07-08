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

---

## Scope boundary

This policy applies only to `runner-base`.

Derived images own their own release cadence,
parent-digest adoption, and domain-specific rebuild policy.

---

**End of document**

---
