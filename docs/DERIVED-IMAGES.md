# Derived-image authoring contract

Status: Normative for images derived from the current legacy v0.2.x base contract.

## What a derived image may add

- declarative identity fields in its build-time `image.manifest`;
- declarative `TOOL_*` metadata for tools it owns;
- domain-specific executables and plugins under `/usr/local/lib/runner.d/`;
- domain documentation, domain tests, and release evidence;
- a pinned `FROM ghcr.io/gehorak/runner-base:<released-version>@sha256:<published-digest>` reference.

## What a derived image must preserve

- the `/usr/local/bin/runner` entrypoint and its explicit dispatch model;
- the base-owned metadata validator and materialization model;
- the declared non-root runtime user, `HOME`, and writable workspace contract;
- the `/etc/runner/*.env` runtime contract files as immutable data;
- base core command semantics and the empty-by-default base plugin namespace before domain plugins are added.

Derived images must not replace the entrypoint, parser, runtime user model, or current legacy core commands. They must not source metadata as shell code or introduce implicit command forwarding.

## Tool declaration and tests

Use canonical tool names in documentation and metadata. A derived image owns tests for every provided domain tool, including an explicit command invocation and expected failure behavior. Base CI protects only base-owned invariants; domain tests are not a base release invariant.

## Compatibility and upgrades

Record the parent digest adopted by each derived release. A derived image must state which base release and digest it was tested against, then revalidate its domain contract whenever it adopts a new parent digest.

The v001 target is documented separately in `docs/CLI-V001.md`. Do not rely on it in a derived image until the corresponding public base release exists.
