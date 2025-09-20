# docs/implementation

Implementation notes and design docs.

## AArch64 emulation & GDB support

- The Docker image installs `qemu-system-aarch64`, `qemu-user-static`, and `gdb-multiarch` so you can run and debug aarch64 binaries on amd64 build hosts.
- Limitations and notes:
  - Enabling emulation via `binfmt_misc` requires host support and elevated privileges; CI typically sets this up using `docker/setup-qemu-action@v2` or similar. Running the container locally may require `--privileged` or running the `binfmt` registration on the host.
  - `gdb-multiarch` provides multi-architecture debugging but may lack some aarch64-specific features present in a native `gdb` built with explicit aarch64 support. If you need full aarch64 GDB features (e.g., for low-level embedded debugging), consider building `gdb` from source with `--target=aarch64-linux-gnu` or installing a distro package that explicitly provides an aarch64-capable `gdb`.
  - QEMU system emulation (`qemu-system-aarch64`) can be slow; use it for CI smoke tests and lightweight validation rather than heavy integration tests.

- Recommended CI configuration:
  - Use `docker/setup-qemu-action@v2` to register binfmt handlers and enable cross-arch builds and emulation on GitHub Actions.
  - Prefer multi-stage builds and caching for Rust toolchains to reduce image build times.


