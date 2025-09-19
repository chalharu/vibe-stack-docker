FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Basic deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg2 git build-essential cmake pkg-config \
    lsb-release software-properties-common \
    qemu-system-arm qemu-system-aarch64 qemu-user-static \
    gdb-multiarch python3 python3-pip unzip wget && \
    rm -rf /var/lib/apt/lists/*

# Install rustup and toolchains
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo PATH=/usr/local/cargo/bin:$PATH
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path && \
    /usr/local/cargo/bin/rustup default stable && \
    /usr/local/cargo/bin/rustup toolchain install nightly || true && \
    /usr/local/cargo/bin/rustup component add rust-src rustfmt clippy llvm-tools rust-analysis || true && \
    /usr/local/cargo/bin/rustup target add aarch64-unknown-none || true

# Install Node.js (Node 20 LTS) and global npm packages (vibe-kanban, opencode-ai)
# Use install helper scripts so package logic is visible and editable in repo
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
    chown -R 1000:1000 /home/runner/.local/share/vibe-kanban || true

# Allow persistence of vibe-kanban data (mapped to $HOME/.local/share/vibe-kanban)
VOLUME ["/home/runner/.local/share/vibe-kanban"]

# Copy entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /work
USER runner

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
