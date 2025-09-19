# Tasks for: Vibe Kanban を Kubernetes で動かすための Docker Image

Feature dir: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/specs/001-vibe-kanban-kubernetes

Summary: 下記タスクは research.md と data-model.md をもとに依存順序で並べた実行可能なタスク群です。各タスクは具体的なファイルパスを示し、LLM エージェントや人がそのまま実行できる指示を含みます。

Guidelines:
- TDD に従い、テスト（smoke/contract）を先に作成します。
- 同一ファイルを変更するタスクは順次実行（非並列）。別ファイルは可能なら [P] (parallel) 実行可能。
- ファイル作成は絶対パスで指定しています。

Tasks:

T001 - Setup: create directory layout and placeholders
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker
- Action: Create directories and placeholder files:
  - `.github/workflows/` (if missing)
  - `ci/`
  - `k8s/`
  - `docker/`
  - `scripts/`
  - `tests/contract/`
  - `docs/implementation/`
  - Ensure `specs/001-vibe-kanban-kubernetes/` already exists (it does).
- Dependency: none
- Why: 残りタスクの出力先を明確にする

T002 - Create failing contract test for health endpoint [P]
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/tests/contract/test_health_endpoint.sh
- Action: Create a shell script that runs the container image (local tag) and asserts GET /health returns HTTP 200 and JSON {"status":"ok"}. Exit 0 only on success. (Test should fail until implementation exists.)
- Dependency: T001
- Parallel: [P]

T003 - Create OpenAPI contract (health) [P]
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/specs/001-vibe-kanban-kubernetes/contracts/openapi-health.yaml
- Action: Create OpenAPI 3.0 spec with GET /health as described in research.md (basic schema). Used by contract test and docs.
- Dependency: T001
- Parallel: [P]

T004 - Write quickstart.md (user-facing) [P]
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/specs/001-vibe-kanban-kubernetes/quickstart.md
- Action: Populate quickstart with exact commands to build image locally, run smoke test, and apply k8s manifests (use image name ghcr.io/<OWNER>/<REPO>:local as placeholder). This acts as acceptance steps for later validation.
- Dependency: T001
- Parallel: [P]

T005 - Create AGENTS.md (agent hints) [P]
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/specs/001-vibe-kanban-kubernetes/AGENTS.md
- Action: Short guidance for automation agents (what files to edit, main commands, where to find tests). Keep <150 lines.
- Dependency: T001
- Parallel: [P]

T006 - Create Dockerfile (core) (sequential edits expected)
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/Dockerfile
- Action: Create a Debian-based Dockerfile that:
  - Installs Git, GitHub CLI, qemu-system-aarch64, gdb (aarch64 support), required build tools (build-essential, cmake, etc.)
  - Installs Rust toolchains (stable, nightly) via rustup and components: rust-src, rustfmt, clippy, llvm-tools, rust-analysis
  - Adds target aarch64-unknown-none (or appropriate aarch64 target) and configures qemu if needed
  - Adds Vibe Kanban, Spec Kit, Opencode installation steps (placeholders if sources are external)
  - Adds non-root user and exposes relevant ports
  - Adds a copy of `docker/entrypoint.sh` and sets ENTRYPOINT
- Dependency: T001
- Note: This file will be edited incrementally; do not parallelize edits that change the same file.

T007 - Create entrypoint script
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/docker/entrypoint.sh
- Action: Create script that starts Vibe Kanban (command placeholder) and ensures graceful shutdown. Make executable (chmod +x). Document environment variables used (PORT, DATA_DIR, etc.).
- Dependency: T006 (entrypoint referenced by Dockerfile)

T008 - Implement Rust toolchain & caching steps in Dockerfile (continue T006)
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/Dockerfile
- Action: Add layered steps and cache-friendly patterns for rustup and cargo (use /usr/local/cargo cache dirs). Ensure rustup installs stable and nightly and components. Configure Docker layer caching instructions in comments.
- Dependency: T006 (same file - sequential)

T009 - Implement qemu & gdb setup in Dockerfile (continue T006)
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/Dockerfile
- Action: Add installation of qemu-system-aarch64 and a gdb build that supports aarch64 (via apt packages or build steps). Document any known limitations.
- Dependency: T006 (same file - sequential)

T010 - Create CI smoke test script
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/ci/smoke_test.sh
- Action: Script that pulls/built image, runs container in background, waits for service, curls /health, fails if non-200. Return non-zero on failure.
- Dependency: T006, T007 (image & entrypoint required)

T011 - Create GitHub Actions workflow: build, smoke, publish
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/.github/workflows/build-and-publish.yml
- Action: Workflow that triggers on push (and on renovate PRs), performs:
  1. Checkout
  2. Set up QEMU & Docker Buildx (for cross/emu builds)
  3. Build Docker image using Dockerfile, tag with semver/latest/commit-sha
  4. Run `ci/smoke_test.sh` against the newly built image
  5. On success, login to ghcr with `GITHUB_TOKEN` and push image
  6. On renovate PRs: run same steps and report status
- Dependency: T006, T010

T012 - Configure Actions caching (rust/cargo, docker layer cache)
- Path: referenced inside `.github/workflows/build-and-publish.yml` (no separate file)
- Action: Add steps to cache cargo registry and target, and docker buildx cache. Document cache keys in workflow comments.
- Dependency: T011

T013 - Create Kubernetes manifests (Deployment, Service, ConfigMap)
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/k8s/vibe-kanban-deployment.yaml
- Action: Create Deployment that uses image `ghcr.io/<OWNER>/<REPO>:<tag>`, Service to expose port, and optional ConfigMap for configuration. Use readinessProbe on /health.
- Dependency: T006 (image interface), T007 (expected env vars)
- Parallel: [P]

T014 - Create renovate configuration with conditional automerge
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/renovate.json
- Action: Configure renovate to monitor all possible dependencies (OS packages, Rust toolchain, Vibe Kanban), create PRs. Set automerge rules: patch/minor PRs -> automerge when CI (build-and-publish) passes; major PRs -> no automerge and add `major` label for manual review. Configure PR labels and branch naming.
- Dependency: T011 (workflow name for check)

T015 - Create automerge workflow to merge renovate PRs when checks pass
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/.github/workflows/automerge.yml
- Action: Workflow triggered by `pull_request` or `pull_request_target` labeled `automerge` that checks statuses and, if all required checks passed and PR does not have `major` label, calls GitHub API or uses `actions-ecosystem/action-auto-merge` to merge.
- Dependency: T011, T014

T016 - Documentation: docs/implementation/docker.md and ci/README.md
- Path: /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/docs/implementation/docker.md
        /Users/haru/Developments/Repositories/github.com/chalharu/vibe-stack-docker/ci/README.md
- Action: Write short docs describing Dockerfile layers (where to add packages), how to run smoke test locally, and how caching works. Include debugging tips (how to start a shell in the container, check rust versions).
- Dependency: T006, T010, T011

T017 - Run local build + smoke test (manual verification)
- Action (commands to run locally):
  - Build: `docker build -t ghcr.io/<OWNER>/<REPO>:local -f Dockerfile .`
  - Run smoke test: `ci/smoke_test.sh ghcr.io/<OWNER>/<REPO>:local`
- Dependency: T006, T007, T010

T018 - Release tagging and publish (manual or CI)
- Action: After CI success, tag a release (semver) and ensure workflow pushes tags and `latest`. Document release steps in `docs/implementation/docker.md`.
- Dependency: T011, T017

Parallel execution groups (examples):
- Group A [P]: T002, T003, T004, T005 (docs & contract tests can be created in parallel)
- Group B [P]: T013 (k8s manifests) can be created while Dockerfile is being implemented

Notes & Hints for implementers / LLM agents:
- When editing `Dockerfile`, prefer incremental commits: create a minimal Dockerfile first (base + apt installs + entrypoint copy), commit, then add heavy tool installations (rustup, qemu) in separate commits to make CI caching effective.
- Use absolute paths above when creating files. Where `<OWNER>` and `<REPO>` are needed, replace with repository owner `chalharu` and repo `vibe-stack-docker` or keep as placeholders if automation will fill them.
- For automerge safety: require `build-and-publish` and `smoke` checks to pass and ensure renovate publishes PRs with semver metadata so automerge can detect major vs non-major.

Estimated minimal task count: 18 tasks. Adjust order if you add contract APIs or extra integration tests.
