# Changelog
#
# All notable changes to this project are documented in this file.
#
# This project follows:
# - Keep a Changelog
# - Semantic Versioning (SemVer)
#
# The changelog focuses on externally observable behavior and contract changes.
# Internal refactors that do not affect the execution model may be omitted.
#

---

## [0.1.0] – 2025-12

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
- This release establishes the initial runner execution contract.
- CI workflows are not part of the runtime contract
---

## Versioning Policy

- **MAJOR** – breaking changes to execution model or CLI contract
- **MINOR** – new commands or capabilities
- **PATCH** – bug fixes, documentation, internal improvements
