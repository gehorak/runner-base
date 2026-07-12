# Release, rollback, and supply-chain policy

Status: Policy for the local `v0.3.0` compatibility-release candidate. No v0.3.0 tag or publication has been created.

## Supported platform

`runner-base` publicly supports only `linux/amd64`. CI and release builds explicitly build and test that platform. No multi-architecture claim is made.

## Reproducibility boundary

The Debian parent image is pinned by digest. APT package versions are not individually pinned, so builds are reproducible to the parent image and build instructions, not bit-for-bit reproducible across time. Monthly parent-digest and action-pin review, release rebuilds, image scanning/SBOM generation, and published evidence compensate for that remaining package-resolution drift.

## Release procedure

1. A reviewed SemVer tag on `main` triggers the release workflow.
2. The workflow writes an isolated build-context manifest whose `RUNNER_VERSION` and `RUNNER_IMAGE_VERSION` equal the tag and whose `RUNNER_IMAGE_REVISION` equals the tagged commit.
3. The workflow builds one `linux/amd64` candidate image and runs the complete base-owned test sequence.
4. It generates an SPDX JSON SBOM for that tested candidate.
5. It publishes only the fixed SemVer tag, then resolves its immutable digest and records the immediately preceding lower strict-SemVer rollback digest.
6. It generates keyless provenance and SBOM attestations and publishes the evidence and SBOM as GitHub Release assets.
7. Only after the immutable evidence succeeds, it updates the minor-line and convenience `latest` aliases to the recorded digest.

The GitHub Release and its public evidence assets are created only after the rollback digest, SBOM, provenance, and machine-readable evidence are available. A registry publication has to precede digest-bound attestation. If a later step fails, a re-run may resume only when the existing immutable SemVer image's registry configuration digest exactly matches the newly tested candidate configuration digest. A mismatch fails closed: do not replace the tag; investigate and, if the release cannot be completed, mark it as yanked.

## Partial publication and recovery

The immutable SemVer tag is the recovery checkpoint. A maintainer may re-run the
same tag workflow after a registry, attestation, evidence, or GitHub Release
outage only when the workflow's candidate digest matches the already published
immutable image. The recovery run repeats required tests, scan, SBOM, and
evidence validation before completing unfinished attestation or release steps.

If the immutable image resolves to a different candidate digest, stop. Never
overwrite a release tag, force a minor alias as a workaround, or create evidence
for unverified bits. Mark the release as yanked if it cannot be completed, then
publish a new SemVer tag after the defect or incident is understood. Aliases are
updated only after evidence succeeds; an alias-only failure may be safely retried
against the already evidenced immutable digest.

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
