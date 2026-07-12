# runner-base release evidence

Status: Release-evidence assets for the local `v0.3.0` compatibility-release candidate. No v0.3.0 release evidence exists until publication is separately authorized.

Every release workflow produces and attaches these public assets to the matching GitHub Release:

- `runner-base-<version>.release-evidence.json`;
- `runner-base-<version>.sbom.spdx.json`.

The JSON record conforms to `release-evidence.schema.json`. It identifies the source commit, tested local candidate image, published digest, pinned parent digest, test sequence, SBOM asset, provenance attestation, release decision, and rollback digest.

The SBOM and release evidence are retained as release assets. Provenance and SBOM attestations are keyless GitHub attestations associated with the published image digest.

This directory defines the evidence contract and does not claim that an unreleased target version is already published.
