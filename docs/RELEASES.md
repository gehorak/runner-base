# Release, rollback, and supply-chain policy

Status: Policy for the unreleased `v0.2.6` stabilization target.

## Supported platform

`runner-base` publicly supports only `linux/amd64`. CI and release builds explicitly build and test that platform. No multi-architecture claim is made.

## Reproducibility boundary

The Debian parent image is pinned by digest. APT package versions are not individually pinned, so builds are reproducible to the parent image and build instructions, not bit-for-bit reproducible across time. Monthly parent-digest and action-pin review, release rebuilds, image scanning/SBOM generation, and published evidence compensate for that remaining package-resolution drift.

## Release procedure

1. A reviewed SemVer tag on `main` triggers the release workflow.
2. The workflow builds one `linux/amd64` candidate image and runs the complete base-owned test sequence.
3. It generates an SPDX JSON SBOM for that tested candidate.
4. It publishes the same tested local image under fixed SemVer, minor-line, and convenience `latest` tags.
5. It resolves the published digest, records the previous rollback digest, generates keyless provenance and SBOM attestations, and publishes the evidence and SBOM as GitHub Release assets.

The GitHub Release and its public evidence assets are created only after the rollback digest, SBOM, provenance, and machine-readable evidence are available. A registry publication has to precede digest-bound attestation; if a later evidence or attestation step fails, maintainers must investigate and, when the image cannot be completed, mark the published version as yanked rather than silently retrying or replacing its tag.

## Immutable references

Automation must use a fixed SemVer or, preferably, a SemVer plus published digest:

```text
ghcr.io/gehorak/runner-base:<released-version>@sha256:<published-digest>
```

`latest` is a convenience tag only. It is never a rollback, CI, deployment, compatibility, or audit reference.

## Rollback

Every release evidence record names the immediately previous published image reference and digest. Roll back by using that immutable digest explicitly. Do not overwrite a released tag, delete the affected evidence, or rebuild a different image under the same version.

## Yanking and security releases

If a published image is defective or unsafe:

1. keep its release, tag, digest, SBOM, provenance, and evidence auditable;
2. mark the GitHub Release title and body as `YANKED`, including reason, impact, and replacement or rollback digest;
3. remove it from supported usage guidance without silently replacing its bits;
4. publish a new fixed SemVer for a security correction and document upgrade/rollback guidance.

## Signing posture

The minimum posture is keyless GitHub attestation backed by short-lived Sigstore identity. No long-lived signing key is introduced unless a consumer verification requirement justifies it. Verify the published image attestation with GitHub tooling against the repository and published digest.

## Release evidence

See `release/README.md` for the evidence assets and `release/release-evidence.schema.json` for the machine-readable contract.
