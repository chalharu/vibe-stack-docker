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
    gdb-multiarch gcc-aarch64-linux-gnu python3 python3-pip unzip wget && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Install rustup and toolchains (stable + nightly) and common components
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo PATH=/usr/local/cargo/bin:$PATH
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path && \
    /usr/local/cargo/bin/rustup default stable && \
    /usr/local/cargo/bin/rustup toolchain install nightly || true && \
    # Add components for stable and nightly toolchains (best-effort)
    /usr/local/cargo/bin/rustup component add --toolchain stable rust-src rustfmt clippy llvm-tools rust-analysis || true && \
    /usr/local/cargo/bin/rustup component add --toolchain nightly rust-src rustfmt clippy llvm-tools rust-analysis || true && \
    # Add common aarch64 targets
    /usr/local/cargo/bin/rustup target add aarch64-unknown-linux-gnu aarch64-unknown-none || true

# Ensure QEMU binfmt handlers are visible (qemu-user-static registers them),
# additional runtime registration may be required by the container runtime.
RUN update-binfmts --display || true

# Install Node.js (Node 20 LTS) and global npm packages (vibe-kanban, opencode-ai)
# Use install helper scripts so package logic remains visible and editable in repo
COPY docker/install_vibe.sh /tmp/install_vibe.sh
COPY docker/install_opencode.sh /tmp/install_opencode.sh
RUN chmod +x /tmp/install_vibe.sh /tmp/install_opencode.sh && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    /tmp/install_vibe.sh && /tmp/install_opencode.sh && \
    # make global npm packages writable by the non-root 'runner' user (uid 1000)
    chown -R 1000:1000 /usr/lib/node_modules || true && \
    chown -R 1000:1000 /usr/local/lib/node_modules || true && \
    # ensure global binaries are executable by runner
    find /usr/local/bin /usr/bin -maxdepth 1 -type f -exec chmod a+rx {} + || true && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 runner || true

# Ensure HOME is set for the non-root user and create persistent data dir
ENV HOME=/home/runner
RUN mkdir -p /home/runner/.local/share/vibe-kanban && \
    chown -R 1000:1000 /home/runner || true

# Allow persistence of vibe-kanban data (mapped to $HOME/.local/share/vibe-kanban)
VOLUME ["/home/runner/.local/share/vibe-kanban"]

# Copy entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /work
USER runner

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
