#!/usr/bin/env bash
# Verify the documented base-owned dependency inventory.

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE must name the image under test}"

required_commands=(
  bash
  curl
  git
  ssh
  gpg
  tar
  gzip
  zip
  unzip
  grep
  sed
  awk
  id
)

for command in "${required_commands[@]}"; do
  docker run --rm "${IMAGE}" exec -- sh -c "command -v '${command}' >/dev/null"
done

docker run --rm "${IMAGE}" exec -- sh -c 'test -r /etc/ssl/certs/ca-certificates.crt'

for command in wget jq; do
  if docker run --rm "${IMAGE}" exec -- sh -c "command -v '${command}' >/dev/null 2>&1"; then
    echo "ERROR: ${command} is not an approved base dependency" >&2
    exit 1
  fi
done

echo "==> Base dependency inventory tests passed"
