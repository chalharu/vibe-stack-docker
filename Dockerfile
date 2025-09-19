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

# Create non-root user
RUN useradd -m -u 1000 runner || true

# Copy entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /work
USER runner

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
