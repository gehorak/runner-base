#!/usr/bin/env bash

set -Eeuo pipefail

IMAGE="${IMAGE:?IMAGE must name the derived image}"
docker run --rm "${IMAGE}" tool sample-tool conformance | grep -Fx 'sample stdout: conformance' >/dev/null
echo "==> Synthetic derived domain test passed"
