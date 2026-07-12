# Security model for runner-base

Status: Normative operating guidance for the local v0.3.0 compatibility-release candidate; the published v0.2.6 image remains the legacy public baseline.

## Boundary

`runner-base` provides a non-root execution baseline and explicit command dispatch. It does not manage secrets, credentials, policy decisions, or deployment approval. Operators and derived-image authors own those controls.

## Runtime controls

- Do not mount `/var/run/docker.sock` into a Runner container. It gives workloads effective control over the host Docker daemon.
- Do not forward an SSH agent unless the invoked tool requires it, and prefer a narrowly scoped deploy key or short-lived credential.
- Mount only the required workspace paths. Avoid broad host mounts such as the user home directory or the repository parent directory.
- Match the mounted workspace owner to the declared runtime UID/GID (`10001:10001` in the base manifest), or provide a writable group path deliberately.
- Prefer a read-only root filesystem. Add writable mounts or tmpfs locations only where the invoked tool requires them.
- Drop Linux capabilities and set `no-new-privileges`; the image does not require elevated capabilities for its base contract.

Example hardening envelope for a reviewed immutable image reference:

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --user 10001:10001 \
  -v "$PWD:/workspace:rw" \
  ghcr.io/gehorak/runner-base:<released-version>@sha256:<published-digest> \
  info
```

Replace placeholders only with a fixed SemVer and digest recorded by public release evidence. Do not use `latest` in automation.

## Metadata and output

- Build-time and materialized metadata are literal `KEY=VALUE` data, not shell code.
- `eval` is forbidden. The only trusted sourced file is the Runner metadata parser library.
- Do not place credentials, private endpoints, or raw environment dumps in release evidence, CLI fixtures, logs, or image metadata.

## Security response

For a critical defect, publish a new fixed SemVer release, mark the affected release as yanked with a reason, and document the rollback or upgrade digest. Never silently replace a published tag or digest.

See `docs/RELEASES.md` for yanking and rollback policy, and `docs/TROUBLESHOOTING.md` for mount, proxy, and metadata diagnostics.
