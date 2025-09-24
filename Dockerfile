FROM --platform=linux/amd64 debian:bookworm-slim

# T006: Debian-based image for development/test with Rust, QEMU, and tools
# - Installs Git, GitHub CLI, QEMU, GDB (multiarch), build-essential, cmake
# - Installs Rust toolchains (stable + nightly) and components
# - Adds aarch64 targets and attempts to register QEMU binfmt
# - Placeholder steps for Vibe Kanban, Opencode, and Spec Kit installers

ENV DEBIAN_FRONTEND=noninteractive

# Basic deps (git, build tools, qemu, gdb with cross support)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg2 git build-essential cmake pkg-config \
    lsb-release software-properties-common apt-transport-https \
    binfmt-support qemu-user-static qemu-system-arm qemu-system-aarch64 \
    gdb-multiarch gcc-aarch64-linux-gnu python3 python3-pip unzip wget \
    vim openssh-server gzip xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Install rustup and toolchains (stable + nightly) and common components
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# Create cache-friendly directories under /usr/local so they can be reused as
# Docker BuildKit cache mounts. Example usage when BuildKit is enabled:
#   RUN --mount=type=cache,target=/usr/local/cargo/registry \
#       --mount=type=cache,target=/usr/local/cargo/git \
#       /usr/local/cargo/bin/cargo fetch --manifest-path=/work/Cargo.toml
RUN set -eux; \
    mkdir -p /usr/local/cargo /usr/local/rustup /usr/local/cargo/registry /usr/local/cargo/git; \
    chown -R root:root /usr/local/cargo /usr/local/rustup; \
    chmod -R a+rX /usr/local/cargo /usr/local/rustup

# Install rustup via the official installer and install stable + nightly toolchains.
# Add common components where available and register aarch64 targets. Use
# best-effort (ignore failures) for components/targets that may be absent for a
# particular toolchain to keep the Docker build resilient.
RUN set -eux; \
    curl -sSfL https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    /bin/sh /tmp/rustup-init.sh -y --no-modify-path; \
    rm -f /tmp/rustup-init.sh; \
    export PATH=/usr/local/cargo/bin:$PATH; \
    rustup --version; \
    rustup default stable; \
    rustup toolchain install nightly || true; \
    rustup component add --toolchain stable rust-src rustfmt clippy || true; \
    rustup component add --toolchain nightly rust-src rustfmt clippy || true; \
    rustup component add --toolchain nightly rust-analysis llvm-tools || true; \
    rustup target add aarch64-unknown-linux-gnu aarch64-unknown-none --toolchain stable || true; \
    rustup target add aarch64-unknown-linux-gnu aarch64-unknown-none --toolchain nightly || true; \
    chown -R 1000:1000 /usr/local/cargo /usr/local/rustup; \
    rustup show || true

# Ensure QEMU binfmt handlers are visible (qemu-user-static registers them),
# additional runtime registration may be required by the container runtime.
RUN update-binfmts --display || true

# Install Node.js (Node 20 LTS) and global npm packages (vibe-kanban, opencode-ai)
# Use install helper scripts so package logic remains visible and editable in repo
COPY docker/install_vibe.sh /tmp/install_vibe.sh
COPY docker/install_opencode.sh /tmp/install_opencode.sh
COPY docker/install_codex.sh /tmp/install_codex.sh
RUN chmod +x /tmp/install_vibe.sh /tmp/install_opencode.sh /tmp/install_codex.sh && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    /tmp/install_vibe.sh && \
    /tmp/install_opencode.sh && \
    /tmp/install_codex.sh && \
    # make global npm packages writable by the non-root 'runner' user (uid 1000)
    chown -R 1000:1000 /usr/lib/node_modules || true && \
    chown -R 1000:1000 /usr/local/lib/node_modules || true && \
    # ensure global binaries are executable by runner
    find /usr/local/bin /usr/bin -maxdepth 1 -type f -exec chmod a+rx {} + || true && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 runner || true

# Ensure HOME is set for the non-root user
ENV HOME=/home/runner
VOLUME ["/home/runner"]

# Copy entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/runner
USER runner

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
