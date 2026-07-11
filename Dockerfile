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

FROM debian:bookworm-slim@sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df

LABEL org.opencontainers.image.base.name="debian:bookworm-slim" \
      org.opencontainers.image.base.digest="sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df"


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
COPY runner-metadata.sh /usr/local/lib/runner/metadata.sh


# =============================================================================
# Manifest validation
#
# Fail early if the manifest schema is unsupported.
# =============================================================================

# Source only the trusted parser library. Metadata files stay data-only.
RUN chmod 0444 /usr/local/lib/runner/metadata.sh \
 && . /usr/local/lib/runner/metadata.sh \
 && runner_metadata_validate_file /tmp/image.manifest

RUN grep -q '^MANIFEST_SCHEMA_VERSION=1$' /tmp/image.manifest \
 || (echo "ERROR: unsupported manifest schema version" >&2 && exit 1)


# =============================================================================
# Materialize runtime contract
#
# Runtime code MUST read only files under /etc/runner.
# The manifest itself MUST NOT be accessed at runtime.
# =============================================================================

RUN . /usr/local/lib/runner/metadata.sh \
 && mkdir -p /etc/runner \
 && grep '^RUNNER_'  /tmp/image.manifest > /etc/runner/image.env \
 && grep '^RUNTIME_' /tmp/image.manifest > /etc/runner/runtime.env \
 && { grep '^TOOL_' /tmp/image.manifest > /etc/runner/tools.env || [[ $? -eq 1 ]]; } \
 && runner_metadata_validate_file /etc/runner/image.env \
 && runner_metadata_validate_file /etc/runner/runtime.env \
 && runner_metadata_validate_file /etc/runner/tools.env \
 && chmod 0444 /etc/runner/*.env


# =============================================================================
# Runtime user creation
#
# The image MUST NOT run as root.
# User identity is defined exclusively by the manifest.
# =============================================================================

RUN . /usr/local/lib/runner/metadata.sh \
 && runner_metadata_export_file /etc/runner/runtime.env \
 && install -d \
      --owner root \
      --group root \
      --mode 0755 \
      /usr/local/lib/runner.d \
 && groupadd --gid "${RUNTIME_USER_GID}" "${RUNTIME_USER_NAME}" \
 && useradd \
      --uid "${RUNTIME_USER_UID}" \
      --gid "${RUNTIME_USER_GID}" \
      --home-dir "${RUNTIME_USER_HOME}" \
      --create-home \
      --shell "${RUNTIME_SHELL}" \
      "${RUNTIME_USER_NAME}" \
 && install -d \
      --owner "${RUNTIME_USER_UID}" \
      --group "${RUNTIME_USER_GID}" \
      --mode 0755 \
      "${RUNTIME_WORKDIR}"


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
ARG RUNTIME_USER_HOME=/home/runner
ARG RUNTIME_WORKDIR=/workspace

ENV RUNTIME_USER_NAME=${RUNTIME_USER_NAME}
ENV RUNTIME_USER_HOME=${RUNTIME_USER_HOME}
ENV RUNTIME_WORKDIR=${RUNTIME_WORKDIR}
ENV HOME=${RUNTIME_USER_HOME}

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
