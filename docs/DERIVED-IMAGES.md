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

Use canonical tool names in `RUNNER_TOOL_NAMES`, lexical ordering, explicit executable bindings, and optional lexical bridge aliases. A derived image must copy its complete manifest and run the base-owned `runner_metadata_materialize_manifest` during its build. It owns tests for every provided domain tool, including `runner tool <name>`, declared aliases, expected failure behavior, and the parent base digest.

## Compatibility and upgrades

Record the parent digest adopted by each derived release. A derived image must state which base release and digest it was tested against, then revalidate its domain contract whenever it adopts a new parent digest.

The v001 target is documented separately in `docs/CLI-V001.md`. Do not rely on it in a derived image until the corresponding public base release exists.
