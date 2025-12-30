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
