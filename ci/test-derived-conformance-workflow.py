#!/usr/bin/env python3
"""Keep the reusable derived-conformance workflow safe and complete."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github" / "workflows" / "derived-conformance.yml").read_text(encoding="utf-8")

for value in ("workflow_call:", "base_reference:", "expected_contract_version:", "conformance_ref:", "tools_lock_path:", "domain_test_path:"):
    assert value in workflow
assert "repository: gehorak/runner-base" in workflow
assert "conformance_ref must be a full immutable commit SHA" in workflow
assert "runner-base-contract/ci/derived-conformance.sh" in workflow

# Workflow inputs must reach shell commands through environment variables.
run_blocks: list[str] = []
lines = workflow.splitlines()
for index, line in enumerate(lines):
    if line == "        run: |":
        block: list[str] = []
        for run_line in lines[index + 1 :]:
            if run_line.startswith("      - "):
                break
            if run_line.strip() and not run_line.startswith("          "):
                break
            block.append(run_line)
        run_blocks.append("\n".join(block))
    elif line.startswith("        run: "):
        run_blocks.append(line.removeprefix("        run: "))
assert run_blocks, "workflow shell steps are required"
assert all("${{ inputs." not in block for block in run_blocks)
for name in (
    "image",
    "build_context",
    "dockerfile",
    "base_reference",
    "expected_contract_version",
    "conformance_ref",
    "tools_lock_path",
    "domain_test_path",
):
    assert f"INPUT_{name.upper()}: ${{{{ inputs.{name} }}}}" in workflow

assert workflow.index("Validate conformance ref") < workflow.index("Checkout derived source")
assert workflow.count("persist-credentials: false") == 2
assert "${INPUT_CONFORMANCE_REF}" in workflow
assert '[[ "$(git -C runner-base-contract rev-parse HEAD)" == "${INPUT_CONFORMANCE_REF}" ]]' in workflow

print("==> Derived conformance workflow tests passed")
