# Changelog
#
# All notable changes to this project are documented in this file.
#
# This project follows:
# - Keep a Changelog
# - Semantic Versioning (SemVer)
#
# The changelog focuses on externally observable behavior
# and execution contract changes.
#
# Internal refactors that do not affect the execution model
# may be omitted.
#

---

## [Unreleased] - v0.3.0 compatibility bridge

### Added
- Canonical `runner --help`, `runner --version`, `runner info`, `runner tool`, `runner exec --`, and `runner shell` dispatcher surface
- Declarative base-owned tool metadata materialization and a synthetic derived compatibility fixture
- Runtime JSON metadata, stable Runner-native error identifiers, and v0.3 compatibility tests

### Changed
- Release-evidence contract now records CLI v001 compatibility-bridge validation
- Runner startup uses privileged Bash mode, runtime metadata permits workdir overrides, and child processes retain their derived-image PATH.
- Derived tools use the declarative registry and explicit executable bindings; runtime plugin-directory discovery is not part of the public model.

### Fixed
- JSON contract errors are selected for both `info --format json` and `tool --format json` before metadata validation.
- Release candidates validate actual runtime image identity, serialize release runs, pin the vulnerability scanner, and record the canonical test list.

### Notes
- This is a local release candidate and has not been pushed, tagged, published, or released.
- `about`, direct `version`, direct declared-tool commands, declared tool-name aliases, and delimiter-free `exec` remain deprecated bridge forms until v1.0.0.

---

## [0.2.1] - Local candidate

### Added
- Strict metadata grammar validation for build-time and runtime contract files

### Changed
- Local manifest validation now treats runner metadata as literal `KEY=VALUE` data
- Runtime metadata contract docs now describe the strict literal metadata grammar
- Plugin-backed `runner version` output remains a legacy compatibility path in v0.2.x

### Fixed
- Removed unsafe `source`-based metadata loading from build-time and runtime metadata paths
- Rejected invalid plugin command names before filesystem lookup

### Notes
- This entry tracks the local stabilization candidate on `ai/runner-base-v0.2.1-metadata-hardening`
- Runtime env files are no longer sourced directly; sourcing the trusted metadata parser library remains intentional
- Runtime root rejection, explicit `HOME` / `/workspace`, and release-chain hardening remain follow-up work

## [0.2.2] - Local candidate

### Added
- Explicit runtime `HOME` and writable default `/workspace` guarantees

### Changed
- Runtime contract and test coverage now describe writable home/workspace expectations explicitly

### Fixed
- Rejected runtime root overrides that would bypass the non-root contract

### Notes
- This entry tracks the local stabilization candidate on `ai/runner-base-v0.2.2-runtime-contract`
- This candidate builds on `v0.2.1` metadata hardening and keeps release-chain maintenance separate

## [0.2.3] – 2026-07-08

### Added
- Documented maintenance policy for base digest updates and monthly dependency review

### Changed
- Pinned the Debian base image by digest and exposed the base digest in OCI metadata
- Pinned GitHub Actions workflow dependencies by commit SHA
- Refreshed the pinned GitHub Actions workflow dependencies before the public `v0.2.3` tag target
- CI and release contract validation now include metadata grammar coverage
- CI, release, and local `make test` now enforce the base-image plugin directory invariant

### Fixed
- Release publication now pushes the same locally tested image artifact instead of rebuilding during publish
- Local `make release` now rejects both staged and unstaged dirty state
- Image identity tests no longer false-fail on Windows Git Bash path conversion
- The image now creates the guaranteed empty `/usr/local/lib/runner.d` plugin directory
- Image identity tests now verify the required `RUNNER_ROLE` field
- Testing docs now reference the correct plugin test filename

### Notes
- This release consolidates the local `v0.2.1` and `v0.2.2` stabilization candidates into a public remediation release
- The `v0.2.1` and `v0.2.2` entries below were local-only candidates and were not published as release tags
- The public `v0.2.3` tag is intended for the dedicated release-preparation chore commit that follows the `v0.2.x` hardening series
- `v3` / `cli contract v001` work remains explicitly out of scope

---

## [0.2.0] – 2025-12-30

### Added
- Formalized runner platform execution contract
- Dedicated test suite covering:
  - smoke behavior
  - core runner interface
  - negative (forbidden) execution paths
  - image identity
  - plugin minimalism
- Documented testing strategy (`docs/TESTING.md`)
- Clear separation between base image and domain images

### Documentation
- Finalized architecture, contract, and testing documentation
- Clarified build-time vs runtime boundaries
- Aligned documentation with enforced test suite

### Changed
- Clarified and hardened runner dispatch behavior
- Refined execution model to eliminate implicit behavior
- Improved and stabilized non-root execution guarantees
- Simplified base image responsibilities
- Improved documentation clarity and consistency

### Fixed
- Eliminated ambiguous or implicit command execution paths
- Removed fragile assumptions around runtime configuration
- Reduced test brittleness by avoiding output-format coupling

### Notes
- This release focuses on **architectural polish and hardening**
- No breaking changes were introduced
- The existing runner CLI contract remains intact

---

## [0.1.0] – 2025-12-25

### Added
- Initial public release of `runner-base`
- Deterministic, bash-based runner entrypoint
- Explicit CLI execution model
- Stable set of core commands:
  - `help`
  - `about`
  - `info`
  - `version`
  - `exec`
  - `shell`
- Non-root runtime user by default
- Plugin-based extension mechanism (`runner.d`)
- Immutable image identity defined via `/etc/runner/image.env`

### Changed
- N/A

### Fixed
- N/A

### Notes
- This release establishes the initial runner execution contract
- CI workflows are not part of the runtime contract

---

## Versioning Policy

- **MAJOR** – breaking changes to the execution model or CLI contract
- **MINOR** – new capabilities or observable behavior extensions
- **PATCH** – bug fixes, documentation, and internal improvements
