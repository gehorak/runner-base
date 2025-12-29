# =============================================================================
# Makefile — Unified local workflow for runner-* repositories
#
# PURPOSE
# -------
# This Makefile provides a simple, explicit and repeatable workflow
# for working with runner-based  images.
#
# It mirrors the CI pipeline locally:
#   build  ->  test  ->  (optional) release
#
# DESIGN PRINCIPLES
# -----------------
# - No hidden behavior
# - No environment auto-detection
# - Same commands work everywhere
# - Easy to read and maintain over years
#
# This file is identical across all runner-* repositories.
# =============================================================================


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Image tag used for local builds and tests.
# Can be overridden:

# Image identity (must never change across environments)
IMAGE_NAME ?= runner-base
# Image tag (context: dev, ci, test, release)
IMAGE_TAG  ?= dev
# Fully qualified image reference
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)


# Docker build context (usually repository root)
BUILD_CONTEXT ?= .
# Directory containing test scripts
CI_DIR := ci
IMAGE_MANIFEST := image.manifest
AWK ?= awk

# -----------------------------------------------------------------------------
# Helper: read KEY=value from manifest
# -----------------------------------------------------------------------------
manifest = $(strip $(shell $(AWK) -F= '/^$(1)=/{print $$2}' $(IMAGE_MANIFEST)))

# -----------------------------------------------------------------------------
# Runtime contract (derived from manifest)
# -----------------------------------------------------------------------------
RUNTIME_USER_NAME := $(call manifest,RUNTIME_USER_NAME)
RUNTIME_USER_UID  := $(call manifest,RUNTIME_USER_UID)
RUNTIME_USER_GID  := $(call manifest,RUNTIME_USER_GID)
RUNTIME_USER_HOME := $(call manifest,RUNTIME_USER_HOME)
RUNTIME_SHELL     := $(call manifest,RUNTIME_SHELL)
RUNTIME_WORKDIR   := $(call manifest,RUNTIME_WORKDIR)

# -----------------------------------------------------------------------------
# Helper: require variable to be non-empty
# -----------------------------------------------------------------------------
define require
  $(if $(strip $($(1))),,$(error Missing required value '$(1)' in $(IMAGE_MANIFEST)))
endef


# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------

.PHONY: help build test smoke lint clean check-manifest print-manifest check release


# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  build        	Build the Docker image locally"
	@echo "  test         	Run all local tests (same as CI)"
	@echo "  smoke        	Run basic smoke tests only"
	@echo "  check          Build + test (repository invariant)"
	@echo "  release        Validate local release prerequisites"
	@echo "  lint         	Lint the runner script"
	@echo "  check-manifest	Validate image.manifest"
	@echo "  print-manifest	Print resolved runtime contract"
	@echo "  clean        	Remove local test image"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  IMAGE=$(IMAGE)" Docker image tag (default: runner-base:dev)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make test"
	@echo "  make build IMAGE=myimage:dev"
	@echo ""


# -----------------------------------------------------------------------------
# Manifest validation
# -----------------------------------------------------------------------------
check-manifest:
	@echo "==> Checking $(IMAGE_MANIFEST)"
	@test -f $(IMAGE_MANIFEST) || (echo "ERROR: $(IMAGE_MANIFEST) not found" >&2 && exit 1)
	@$(AWK) -F= '/^MANIFEST_SCHEMA_VERSION=/{print $$2}' $(IMAGE_MANIFEST) | grep -qx '1' \
	  || (echo "ERROR: Unsupported MANIFEST_SCHEMA_VERSION (expected 1)" >&2 && exit 1)

	@$(call require,RUNTIME_USER_NAME)
	@$(call require,RUNTIME_USER_UID)
	@$(call require,RUNTIME_USER_GID)
	@$(call require,RUNTIME_USER_HOME)
	@$(call require,RUNTIME_SHELL)
	@$(call require,RUNTIME_WORKDIR)

	@echo "OK: manifest is valid"

# -----------------------------------------------------------------------------
# print-manifest (debug / audit)
# -----------------------------------------------------------------------------
print-manifest: check-manifest
	@echo "Resolved runtime contract:"
	@echo "  RUNTIME_USER_NAME = $(RUNTIME_USER_NAME)"
	@echo "  RUNTIME_USER_UID  = $(RUNTIME_USER_UID)"
	@echo "  RUNTIME_USER_GID  = $(RUNTIME_USER_GID)"
	@echo "  RUNTIME_USER_HOME = $(RUNTIME_USER_HOME)"
	@echo "  RUNTIME_SHELL     = $(RUNTIME_SHELL)"
	@echo "  RUNTIME_WORKDIR   = $(RUNTIME_WORKDIR)"


# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------
# Builds the Docker image exactly like CI does.
# No cache control or optimizations here — keep it explicit.
# -----------------------------------------------------------------------------

build: check-manifest
	@echo "==> Building image: $(IMAGE)"
	docker build \
	  --build-arg RUNTIME_USER_NAME=$(RUNTIME_USER_NAME) \
	  --build-arg RUNTIME_USER_UID=$(RUNTIME_USER_UID) \
	  --build-arg RUNTIME_USER_GID=$(RUNTIME_USER_GID) \
	  --build-arg RUNTIME_USER_HOME=$(RUNTIME_USER_HOME) \
	  --build-arg RUNTIME_SHELL=$(RUNTIME_SHELL) \
	  --build-arg RUNTIME_WORKDIR=$(RUNTIME_WORKDIR) \
	  -t $(IMAGE) \
	  $(BUILD_CONTEXT)

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Run full test suite
# -----------------------------------------------------------------------------
# Runs all test scripts in the same order as CI.
# If this target passes locally, CI SHOULD pass as well.
# -----------------------------------------------------------------------------

test:
	@echo "==> Running full test suite on image: $(IMAGE)"
	@chmod +x $(CI_DIR)/*.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-smoke.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-image-identity.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-runner-core.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-negative.sh	
	#@IMAGE=$(IMAGE) $(CI_DIR)/test-runner-plugin.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-domain.sh
	@echo "==> All tests passed"


# -----------------------------------------------------------------------------
# Smoke tests only
# -----------------------------------------------------------------------------
# Fast sanity check used during development.
# Does NOT replace full test suite.
# -----------------------------------------------------------------------------

smoke:
	@echo "==> Running smoke tests on image: $(IMAGE)"
	@chmod +x $(CI_DIR)/*.sh
	@IMAGE=$(IMAGE) $(CI_DIR)/test-smoke.sh
	@echo "==> Smoke tests passed"


# -----------------------------------------------------------------------------
# Aggregate invariant
# -----------------------------------------------------------------------------
check: build test
	@echo "==> Repository invariant check passed"


# -----------------------------------------------------------------------------
# Release guards (local safety)
# -----------------------------------------------------------------------------
release:
	@echo "==> Validating release prerequisites"
	@git diff --quiet || (echo "ERROR: working tree is dirty" && exit 1)
	@git describe --tags --exact-match >/dev/null 2>&1 || \
	  (echo "ERROR: HEAD is not exactly at a tag" && exit 1)
	@echo "OK: release prerequisites satisfied"


# -----------------------------------------------------------------------------
# Linting
# -----------------------------------------------------------------------------

lint:
	@echo "==> Linting runner script"
	bash -n runner
	shellcheck runner


# -----------------------------------------------------------------------------
# Clean local artifacts
# -----------------------------------------------------------------------------
# Removes the locally built image.
# Does NOT touch remote images or cache.
# -----------------------------------------------------------------------------

clean:
	@echo "==> Removing local image: $(IMAGE)"
	@docker rmi -f $(IMAGE) || true


# -----------------------------------------------------------------------------
# Notes for maintainers
# -----------------------------------------------------------------------------
#
# - This Makefile intentionally avoids advanced GNU Make features.
# - Targets are explicit and linear.
# - CI is the source of truth; this file mirrors it locally.
#
# If you need to add logic here, reconsider first:
# CI is usually the better place.
#
# =============================================================================
