# =============================================================================
# Dockerfile — runner-base
#
# PURPOSE
# -------
# Provide a minimal, deterministic runtime for tooling images.
#
# This image defines:
# - execution model
# - security baseline
# - runner contract
#
# All domain-specific images MUST extend this image.
#
# DESIGN PRINCIPLES
# -----------------
# - explicit behavior over convenience
# - minimal surface area
# - human-readable and auditable
# - stable over long periods of time
#
# =============================================================================


# -----------------------------------------------------------------------------
# Base system
# -----------------------------------------------------------------------------
# Debian slim provides:
# - predictable package management
# - long-term stability
# - wide compatibility with tooling binaries
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim


# -----------------------------------------------------------------------------
# Metadata (OCI labels)
# -----------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-base" 
LABEL org.opencontainers.image.description="Deterministic runner base image"
LABEL org.opencontainers.image.vendor="gehorak"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/gehorak/runner-base"


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
# Avoid interactive prompts and ensure consistent behavior.
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8


# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
# Only essential utilities required by the runner and common tooling.
#
# Keep this list minimal.
# Domain-specific tools belong to derived images.
# -----------------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \      
      tar \
      gzip \
      zip \
      unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


# -----------------------------------------------------------------------------
# Runtime user
# -----------------------------------------------------------------------------
# The image MUST NOT run as root.
# -----------------------------------------------------------------------------
RUN useradd --create-home --uid 1000 iac

USER iac
WORKDIR /work


# -----------------------------------------------------------------------------
# Runner installation
# -----------------------------------------------------------------------------
# The runner is the single entrypoint for all execution.
#
# - /usr/local/bin/runner        → entrypoint
# - /usr/local/lib/runner.d/     → plugin directory (modules)
# -----------------------------------------------------------------------------
USER root

# -----------------------------------------------------------------------------
# Runner identity
# -----------------------------------------------------------------------------

COPY etc/runner/image.env /etc/runner/image.env
RUN chmod 0644 /etc/runner/image.env

# -----------------------------------------------------------------------------
# Runner binary
# -----------------------------------------------------------------------------

COPY runner /usr/local/bin/runner
RUN chmod +x /usr/local/bin/runner

RUN mkdir -p /usr/local/lib/runner.d \
 && chown -R iac:iac /usr/local/lib


# -----------------------------------------------------------------------------
# Default execution context
# -----------------------------------------------------------------------------
USER iac
ENTRYPOINT ["runner"]
CMD ["help"]


# -----------------------------------------------------------------------------
# Healthcheck
# -----------------------------------------------------------------------------
# Verifies that the runner is functional.
# Does not perform any external checks.
# -----------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD runner info >/dev/null || exit 1
