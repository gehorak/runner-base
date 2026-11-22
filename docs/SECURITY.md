# Security model for runner-base

Status: Normative operating guidance for the public v0.3.0 compatibility
bridge. `v0.2.6` is a historical legacy stabilization release.

## Published release advisory

The published `v0.3.1` image had 23 HIGH and 12 CRITICAL fixable dependency
findings in its 2026-10-08 scan. Later published-image scans reported fixable
HIGH and CRITICAL findings for `v0.3.2`, including Debian Bookworm APT, Brotli,
OpenSSL, and Expat packages.

The published `v0.3.3` image refreshes the digest-pinned Bookworm parent and
upgrades installed packages during the build. The release workflow scanned the
exact tested candidate with Trivy 0.71.0 and `--ignore-unfixed`, reporting zero
fixable HIGH or CRITICAL findings. The published reference is
`ghcr.io/gehorak/runner-base:0.3.3@sha256:5fdcd758ef973fbab502858a91d3b362fa7a7cb621d911a7fc972625e546a3c2`.
Its matching [GitHub Release](https://github.com/gehorak/runner-base/releases/tag/v0.3.3)
contains the SBOM and machine-readable release evidence, with provenance
attestations associated with the image digest.

Previous digests remain in release evidence for traceability; do not use a
known-affected digest as a security rollback. Preserve all previous tags,
digests, and evidence. Marking an existing release `YANKED` is a separate
maintainer decision under `docs/RELEASES.md`.

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
- The dispatcher uses privileged Bash mode, a fixed internal system `PATH`, and absolute system utilities for pre-dispatch guards. `BASH_ENV` and imported Bash functions are not accepted before Runner-owned checks, and a caller-supplied `PATH` cannot select Runner-owned commands.
- The fixed internal `PATH` is not imposed on explicit child commands. Registered tools and `runner exec --` receive the caller or derived-image PATH, while Runner-owned lookup remains independent from it.
- `/workspace` is the image default workdir and a materialized runtime contract path; callers may select a writable subdirectory with Docker `--workdir`.
- Do not place credentials, private endpoints, or raw environment dumps in release evidence, CLI fixtures, logs, or image metadata.

## Vulnerability scanning policy

CI scans the image built from the submitted source with digest-pinned Trivy `0.71.0` for
fixable `HIGH` and `CRITICAL` vulnerabilities. A finding blocks the change
unless its documented exception records the scanner, advisory, affected digest,
expiry date, and a tracked remediation version. Exceptions are reviewed at
least monthly and are never carried into a release without an explicit renewal.

The weekly/manual published-image scan uploads a SARIF report to GitHub
Security > Code scanning under `trivy-published-image`, including when findings
fail the job. Its job summary records the exact scanned release reference and
digest. Results describe that published image, not a fresh build of the source
commit to which GitHub associates the report. Only fixable HIGH/CRITICAL findings
are included; an empty report is not a claim that every severity is absent.

## Security response

For a critical defect, publish a new fixed SemVer release, mark the affected release as yanked with a reason, and document the rollback or upgrade digest. Never silently replace a published tag or digest.

See `docs/RELEASES.md` for yanking and rollback policy, and `docs/TROUBLESHOOTING.md` for mount, proxy, and metadata diagnostics.
