#!/usr/bin/env python3
"""Keep the reusable derived-conformance distribution contract complete."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "derived-conformance.yml").read_text(encoding="utf-8")

for value in ("workflow_call:", "base_reference:", "expected_contract_version:", "conformance_ref:", "tools_lock_path:", "domain_test_path:"):
    assert value in workflow
assert "repository: gehorak/runner-base" in workflow
assert "conformance_ref must be a full immutable commit SHA" in workflow
assert "ref: ${{ inputs.conformance_ref }}" not in workflow
assert workflow.count("persist-credentials: false") == 2
assert 'git -C runner-base-contract fetch --depth=1 origin "${CONFORMANCE_REF}"' in workflow
assert 'git -C runner-base-contract checkout --detach "${CONFORMANCE_REF}"' in workflow
assert 'docker build --build-arg "BASE_IMAGE=${BASE_REFERENCE}" --file "${DOCKERFILE}" --tag "${IMAGE}" "${BUILD_CONTEXT}"' in workflow
assert "runner-base-contract/ci/derived-conformance.sh" in workflow

print("==> Derived conformance workflow tests passed")
