# Changelog

All notable changes to this project are documented in this file.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/). The changelog focuses on
externally observable behavior and execution-contract changes; internal
refactors without execution-model impact may be omitted.

## [0.3.0] - Release preparation

This release preparation establishes the first public v0.3 platform line. It
keeps the compatibility bridge explicit, adds the derived-image safeguards
required before public adoption, and does not claim that a complex real-world
derived image has already been validated.

### Summary

`v0.3.0` prepares the stable CLI v001 compatibility bridge, non-root runtime,
strict metadata boundary, derived-image integrity model, reusable conformance
interface, and release evidence path. It is intended to become a supported base
for direct use and experimental or validation derived images after a separately
authorized tag and publication.

### Highlights

- Canonical CLI v001 compatibility bridge
  - `runner --help`, `runner --version`, `runner info`, `runner tool`, `runner exec --`, and `runner shell` are the stable canonical surface
  - legacy bridge forms remain deprecated until v1.0.0
- Runtime and metadata hardening
  - startup uses privileged Bash protections before Runner-owned guards
  - runtime metadata is strict literal data and contract errors select JSON before validation when JSON was requested
  - parent-owned metadata, dispatcher, and parser files are root-owned and non-writable by the runtime user
- Derived-image contract
  - runtime tool declarations use explicit executable bindings
  - v001 `tools.lock` records HTTPS artifact source, version, and SHA-256 evidence
  - a commit-pinned conformance workflow validates immutable parent references, tools-lock alignment, parent-file integrity, and explicit domain tests
- Release and supply-chain hardening
  - release candidates validate actual runtime identity, the canonical suite, pinned Trivy scanning, SPDX SBOM generation, and evidence on one candidate
  - immutable release recovery fails closed unless the registry configuration digest matches the tested candidate
  - minor-line and `latest` aliases move only after immutable evidence succeeds
  - a scheduled workflow scans the latest published strict-SemVer release by immutable digest

### Compatibility

- The fixed non-root runtime user, `linux/amd64` platform, default `/workspace`, and empty base tool registry remain unchanged.
- `about`, direct `version`, direct declared-tool commands, declared aliases, and delimiter-free `exec` remain bridge forms until v1.0.0.
- Derived images must use `ghcr.io/gehorak/runner-base:0.3.0@sha256:<published-digest>` after publication; `0.3` and `latest` are not dependency references.
- No complex real-world derived image has yet been validated. `runner-terraform` remains the planned reference-derived follow-up and requires separate authorization and evidence.

### Release status

- The release-preparation changes are on `main`.
- No `v0.3.0` tag, published image, SBOM, provenance, release evidence, or GitHub Release is claimed by this entry.
- A release run must produce the exact public artifact evidence before this status can be changed to published.

### Upgrade guidance

- Use canonical CLI commands in new automation and keep legacy bridge forms only during the v0.3 compatibility window.
- Keep derived metadata literal and additive; do not use `source`, quotes, command substitution, or shell control syntax in metadata inputs.
- Pin derived parents to the published SemVer and digest, record v001 tools-lock evidence, and run the matching conformance bundle plus domain tests.
- Do not rely on root overrides, mutable aliases, or runtime plugin-directory discovery.

## [0.2.6] - 2026-07-11

### Changed

- Published the v0.2.6 remediation release evidence, SPDX SBOM, and provenance for the exact released image.
- Documented the frozen CLI v001 target and the v0.2.4 to v0.3.x to v1.0.0 migration boundary.

### Fixed

- Replaced the failing shell-formatting setup action with a pinned upstream `shfmt` release asset verified by SHA-256 before CI linting.

### Notes

- This is the latest public v0.2 release. The v0.3.0 compatibility bridge was not part of this release.

## [0.2.4] - 2026-07-10

### Added

- Documented maintenance policy for base digest updates and monthly dependency review.

### Changed

- Pinned the Debian base image by digest and exposed the base digest in OCI metadata.
- Pinned GitHub Actions workflow dependencies by commit SHA.
- CI and release contract validation include metadata grammar coverage and the base-image plugin-directory invariant.

### Fixed

- Release publication pushes the same locally tested image artifact instead of rebuilding during publication.
- The release workflow restores required executable bits before the full contract suite.
- Local `make release` rejects both staged and unstaged dirty state.
- Image identity tests no longer false-fail on Windows Git Bash path conversion.
- The image creates the guaranteed empty `/usr/local/lib/runner.d` plugin directory and verifies the required `RUNNER_ROLE` field.

### Notes

- This public remediation release consolidates the earlier v0.2.1 and v0.2.2 local candidates.
- v0.3 / CLI v001 implementation remains out of scope for this release.

## [0.2.3] - Tagged local candidate

### Notes

- This tagged candidate captured the v0.2.x hardening series before its public remediation release was issued as v0.2.4.
- It is retained in the chronological history for auditability; it is not a GitHub Release.

## [0.2.2] - Local candidate

### Added

- Explicit runtime `HOME` and writable default `/workspace` guarantees.

### Changed

- Runtime contract and test coverage describe writable home and workspace expectations explicitly.

### Fixed

- Rejected runtime root overrides that would bypass the non-root contract.

### Notes

- This candidate builds on v0.2.1 metadata hardening and keeps release-chain maintenance separate.

## [0.2.1] - Local candidate

### Added

- Strict metadata grammar validation for build-time and runtime contract files.

### Changed

- Local manifest validation treats runner metadata as literal `KEY=VALUE` data.
- Runtime metadata documentation describes the strict literal metadata grammar.
- Plugin-backed `runner version` output remains a legacy compatibility path in v0.2.x.

### Fixed

- Removed unsafe `source`-based metadata loading from build-time and runtime metadata paths.
- Rejected invalid plugin command names before filesystem lookup.

### Notes

- Runtime environment files are never sourced; sourcing the trusted metadata parser library remains intentional.

## [0.2.0] - 2025-12-30

### Added

- Formalized runner platform execution contract and a dedicated smoke, core, negative, identity, and plugin-minimalism test suite.
- Clear separation between base and domain images.

### Changed

- Clarified and hardened runner dispatch behavior, non-root execution guarantees, and build-time versus runtime boundaries.

### Fixed

- Eliminated ambiguous or implicit command execution and reduced test brittleness by avoiding output-format coupling.

### Notes

- This release focuses on architectural polish and hardening without a breaking CLI change.

## [0.1.0] - 2025-12-25

### Added

- Initial public `runner-base` release with a deterministic Bash entrypoint, explicit execution model, non-root runtime, plugin-based extension mechanism, and immutable image identity.

### Notes

- CI workflows are not part of the runtime contract.

## Versioning Policy

- **MAJOR** — breaking changes to the execution model or CLI contract.
- **MINOR** — new compatible capabilities or observable behavior extensions.
- **PATCH** — compatible fixes, documentation, and internal improvements.
