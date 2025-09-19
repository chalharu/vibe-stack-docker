# Data Model: Vibe Kanban Docker Image & CI

## Entities

- DockerImage
  - tag: string (semver | latest | commit-sha)
  - arch: string (amd64 | aarch64)
  - created_at: datetime
  - components: list[string] (vibe-kanban, spec-kit, opencode, git, gh, rust, qemu, gdb)

- CIWorkflow
  - name: string
  - triggers: list[string] (push, pull_request)
  - steps: list[step]

- SmokeTest
  - name: string
  - commands: list[string]
  - expected_exit: int

## Relationships
- DockerImage is produced_by CIWorkflow
- CIWorkflow runs SmokeTest after build

## Validation Rules
- DockerImage.tag must include at least one of semver/latest/commit-sha
- SmokeTest.expected_exit == 0
