# =============================================================================
# Dockerfile — runner-base
#
# Purpose:
#   Provide a minimal, deterministic runtime for runner-based tooling images.
#
# This image defines:
# - execution model
# - security baseline
# - runner platform contract
#
# All domain-specific runner images MUST extend this image.
#
# Design goals:
# - explicit behavior over convenience
# - minimal and auditable surface area
# - long-term stability
# =============================================================================


# =============================================================================
# Base operating system
#
# NOTE:
# - Base OS is an implementation detail
# - NOT part of the runner contract
# =============================================================================

FROM debian:bookworm-slim


# =============================================================================
# Deterministic build environment
# =============================================================================

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=Etc/UTC

SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]


# =============================================================================
# Minimal OS dependencies
#
# Required for:
# - HTTPS communication
# - shell execution
# - runner operation
#
# NOT part of the public image contract.
# =============================================================================

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      bash \
      coreutils \
      curl \
      wget \
      git \
      openssh-client \
      gnupg \
      tar \
      gzip \
      zip \
      unzip \
      grep \
      sed \
      mawk \
 && rm -rf /var/lib/apt/lists/*


# =============================================================================
# Image manifest (single source of truth)
#
# The manifest defines:
# - image identity
# - runtime execution context
# - declared tooling (for derived images)
# =============================================================================

COPY image.manifest /tmp/image.manifest


# =============================================================================
# Manifest validation
#
# Fail early if the manifest schema is unsupported.
# =============================================================================

RUN grep -q '^MANIFEST_SCHEMA_VERSION=1$' /tmp/image.manifest \
 || (echo "ERROR: unsupported manifest schema version" >&2 && exit 1)


# =============================================================================
# Materialize runtime contract
#
# Runtime code MUST read only files under /etc/runner.
# The manifest itself MUST NOT be accessed at runtime.
# =============================================================================

RUN mkdir -p /etc/runner \
 && grep '^RUNNER_'  /tmp/image.manifest > /etc/runner/image.env \
 && grep '^RUNTIME_' /tmp/image.manifest > /etc/runner/runtime.env \
 && grep '^TOOL_'    /tmp/image.manifest > /etc/runner/tools.env || true \
 && chmod 0444 /etc/runner/*.env


# =============================================================================
# Runtime user creation
#
# The image MUST NOT run as root.
# User identity is defined exclusively by the manifest.
# =============================================================================

RUN source /etc/runner/runtime.env \
 && groupadd --gid "${RUNTIME_USER_GID}" "${RUNTIME_USER_NAME}" \
 && useradd \
      --uid "${RUNTIME_USER_UID}" \
      --gid "${RUNTIME_USER_GID}" \
      --home-dir "${RUNTIME_USER_HOME}" \
      --create-home \
      --shell "${RUNTIME_SHELL}" \
      "${RUNTIME_USER_NAME}"


# =============================================================================
# Runner installation
#
# The runner is the single entrypoint for all execution.
# =============================================================================

COPY runner /usr/local/bin/runner
RUN chmod 0755 /usr/local/bin/runner


# =============================================================================
# Runtime defaults (apply runtime contract)
#
# Defaults are defined here.
# Optional build-time overrides may replace them.
# =============================================================================

ARG RUNTIME_USER_NAME=runner
ARG RUNTIME_WORKDIR=/workspace

ENV RUNTIME_USER_NAME=${RUNTIME_USER_NAME}
ENV RUNTIME_WORKDIR=${RUNTIME_WORKDIR}

WORKDIR ${RUNTIME_WORKDIR}
USER ${RUNTIME_USER_NAME}



# =============================================================================
# Entrypoint (platform contract)
#
# MUST NOT be overridden by derived images.
# =============================================================================

ENTRYPOINT ["/usr/local/bin/runner"]
CMD ["help"]


# =============================================================================
# End of Dockerfile
#
# Status: CANONICAL
#
# This file defines platform behavior only.
# Domain-specific concerns belong in derived images.
# =============================================================================
