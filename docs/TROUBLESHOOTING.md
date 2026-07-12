# Troubleshooting runner-base

Status: Operational guidance for the local v0.3.0 compatibility-release candidate; no v0.3.0 image has been published.

## Workspace mount is not writable

The base image runs as UID/GID `10001:10001`. Ensure the mounted directory is writable by that identity or deliberately provide a group-writable workspace. Do not solve a mount-permission issue by running the container as root: root override is a base contract violation and is rejected.

## Network, proxy, or custom CA failure

Network access is an operator concern. Confirm that the container runtime has the required egress policy, proxy variables, and DNS access. For a private CA, mount or bake only the reviewed CA certificate bundle; do not embed proxy credentials or client keys in image metadata, release evidence, or logs.

## Metadata validation failure

`/etc/runner/*.env` metadata are strict literal `KEY=VALUE` files. Remove `export`, quotes, duplicate keys, multiline values, command substitution, redirection, and shell control operators. Treat the reported file and line number as the source to fix; do not bypass validation by sourcing the file.

## Root override rejected

The image deliberately rejects effective UID `0`, including when a container runtime supplies `--user 0`. Run with the manifest-declared user and repair workspace ownership instead.

## Tool is missing

`runner-base` intentionally contains no domain tool. Inspect `runner tool --format json`; then use the documented derived image that declaratively registers the requested tool. Do not expect direct system command forwarding.

## Release reference is unclear

Use the fixed SemVer and digest in the matching public release evidence. If a release is marked yanked, move to the documented fixed version or rollback digest; do not continue using a mutable tag.
