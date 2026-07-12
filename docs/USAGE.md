# Usage guidance for runner-base

Status: Local v0.3.0 compatibility-release candidate usage. The published v0.2.6 image remains legacy until v0.3.0 is separately released.

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
docker run --rm "$RUNNER_IMAGE" --help
docker run --rm "$RUNNER_IMAGE" info --format json
docker run --rm "$RUNNER_IMAGE" exec -- git --version
```

Use `runner exec -- <program> [arguments...]` for canonical v0.3.0 usage. During the bridge, `runner exec <program> [arguments...]` still works with one deprecation warning and will be removed in v1.0.0.

## Workspace mounts

The declared default workspace is `/workspace`. Keep the mount narrow and writable only when an invoked tool needs to write:

```bash
docker run --rm \
  --user 10001:10001 \
  -v "$PWD:/workspace:rw" \
  -w /workspace \
  "$RUNNER_IMAGE" exec -- sh -c 'id && pwd'
```

`/workspace` and the declared `HOME` are the base writable locations. A derived
image must explicitly document every tool cache, configuration path, temporary
directory, and custom CA requirement that needs a writable mount or runtime
injection. Do not assume cache persistence under `/tmp`; hardened execution may
mount it as an ephemeral tmpfs. The child PATH belongs to the caller or derived
image, while Runner protects its own command lookup separately.

For CI, set the image reference once and pass it only to reviewed jobs. Use the same immutable reference for every job that requires compatible base behavior.

## Interactive shell

`runner shell` is for human debugging with an allocated terminal. It is not a CI or automation interface.

## Derived images

Use `docs/DERIVED-IMAGES.md` before creating a derived image. Domain tooling and its tests belong in the derived repository; the base image remains domain-neutral.
