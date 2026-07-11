# Usage guidance for runner-base

Status: Current legacy v0.2.x usage. The v001 target in `docs/CLI-V001.md` is not current runtime behavior.

## Image references

For automation, use an immutable digest or a fixed released SemVer:

```bash
# Fixed SemVer: review the matching release evidence before use.
RUNNER_IMAGE=ghcr.io/gehorak/runner-base:<released-version>

# Preferred for reproducible automation: copy this exact pair from release evidence.
RUNNER_IMAGE=ghcr.io/gehorak/runner-base:<released-version>@sha256:<published-digest>
```

`latest` is convenience-only for local exploration and is not a CI, production, rollback, or compatibility reference.

## Inspection and explicit execution

```bash
docker run --rm "$RUNNER_IMAGE" help
docker run --rm "$RUNNER_IMAGE" about
docker run --rm "$RUNNER_IMAGE" info
docker run --rm "$RUNNER_IMAGE" exec git --version
```

The current legacy interface requires `runner exec <program> [arguments...]`. Do not use the future `runner exec --` syntax until a public v0.3.0 release documents it as supported.

## Workspace mounts

The declared default workspace is `/workspace`. Keep the mount narrow and writable only when an invoked tool needs to write:

```bash
docker run --rm \
  --user 10001:10001 \
  -v "$PWD:/workspace:rw" \
  -w /workspace \
  "$RUNNER_IMAGE" exec sh -c 'id && pwd'
```

For CI, set the image reference once and pass it only to reviewed jobs. Use the same immutable reference for every job that requires compatible base behavior.

## Interactive shell

`runner shell` is for human debugging with an allocated terminal. It is not a CI or automation interface.

## Derived images

Use `docs/DERIVED-IMAGES.md` before creating a derived image. Domain tooling and its tests belong in the derived repository; the base image remains domain-neutral.
