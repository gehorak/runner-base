# Derived-image authoring contract

Status: Normative for images derived from the local v0.3.0 compatibility-release candidate; public derived adoption remains deferred until base release.

## What a derived image may add

- declarative identity fields in its build-time `image.manifest`;
- declarative `RUNNER_TOOL_*` metadata for tools it owns;
- domain-specific executables bound explicitly by `RUNNER_TOOL_<NAME>_EXECUTABLE`;
- domain documentation, domain tests, and release evidence;
- a pinned `FROM ghcr.io/gehorak/runner-base:<released-version>@sha256:<published-digest>` reference.

## What a derived image must preserve

- the `/usr/local/bin/runner` entrypoint and its explicit dispatch model;
- the base-owned metadata validator and materialization model;
- the declared non-root runtime user, `HOME`, and writable workspace contract;
- the `/etc/runner/*.env` runtime contract files as immutable data;
- base core command semantics and the empty-by-default base tool registry before domain tools are added.

Derived images must not replace the entrypoint, parser, runtime user model, metadata materializer, or canonical commands. They must not source metadata as shell code or introduce implicit command forwarding.

## Tool declaration and tests

Use canonical tool names in `RUNNER_TOOL_NAMES`, lexical ordering, explicit executable bindings, and optional lexical bridge aliases. A derived image supplies an overlay manifest containing only its identity and `RUNNER_TOOL_*` declarations, then runs the base-owned `runner_metadata_materialize_derived_manifest` during its build. Runner version, contract version, supported platform, and runtime-user fields remain materialized from the parent and cannot be overridden. It owns tests for every provided domain tool, including `runner tool <name>`, declared aliases, expected failure behavior, and the parent base digest.

## Tool integrity evidence

The runtime registry deliberately validates only the canonical name, version,
explicit executable binding, and aliases. A derived image records artifact
source, resolved version, and checksum in its release-owned
`contracts/tools-lock/v001/tools.lock.json`. The file must conform to
`runner-base/contracts/tools-lock/v001/schema.json`, use lexical tool ordering,
and contain exactly one HTTPS source and SHA256 for every declared Runner tool.
The derived build or release process must verify every download against that
lock before installation. Runner base does not fetch or validate remote
artifacts at runtime.

Copy the structure in `contracts/tools-lock/v001/template.json`; do not restore
legacy `TOOL_<NAME>_SHA256` fields in `image.manifest`. The lock is release
evidence, while `RUNNER_TOOL_*` metadata remains the runtime registry.

## Pinned derived conformance

Every stable derived release must run the versioned base conformance interface
and record both its immutable parent and the immutable conformance commit. The
low-maintenance distribution mechanism is the reusable workflow:

```yaml
jobs:
  runner-base:
    uses: gehorak/runner-base/.github/workflows/derived-conformance.yml@<40-character-runner-base-commit>
    with:
      image: runner-terraform:conformance
      build_context: .
      dockerfile: Dockerfile
      base_reference: ghcr.io/gehorak/runner-base:0.3.0@sha256:<published-digest>
      expected_contract_version: v001
      conformance_ref: <the-same-40-character-runner-base-commit>
      tools_lock_path: contracts/tools-lock/v001/tools.lock.json
      domain_test_path: ci/test-domain.sh
```

The conformance bundle builds the declared image, validates the exact tool-lock
names against `runner info --format json`, checks root ownership and runtime-user
non-writability of all parent-owned metadata, dispatcher, and parser files, and
then runs the derived repository's explicit domain test. The caller must pin
both references to full commit or digest identities; branch and convenience tags
are not valid compatibility evidence.

## Compatibility and upgrades

Record the parent SemVer, digest, contract version, conformance commit, and
tools-lock digest adopted by each derived release. A derived image must state
which base release and digest it was tested against, then revalidate its domain
contract whenever it adopts a new parent digest.

The v001 target is documented separately in `docs/CLI-V001.md`. Do not rely on it in a derived image until the corresponding public base release exists.
