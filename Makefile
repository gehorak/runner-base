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


# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------

.PHONY: help build test smoke lint clean


# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Helper target: print available commands
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  build        Build the Docker image locally"
	@echo "  test         Run all local tests (same as CI)"
	@echo "  smoke        Run basic smoke tests only"
	@echo "  lint         Lint the runner script"
	@echo "  clean        Remove local test image"
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
# Build
# -----------------------------------------------------------------------------
# Builds the Docker image exactly like CI does.
# No cache control or optimizations here — keep it explicit.
# -----------------------------------------------------------------------------

build:
	@echo "==> Building image: $(IMAGE)"
	docker build -t $(IMAGE) $(BUILD_CONTEXT)


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
	#@IMAGE=$(IMAGE) $(CI_DIR)/test-runner-plugins.sh
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
