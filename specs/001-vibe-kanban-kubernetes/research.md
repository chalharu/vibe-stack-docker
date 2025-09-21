# Research: Vibe Kanban を Kubernetes で動かすための Docker Image

## Decision
1. ベースイメージ: Debian を採用（ユーザー指定）
2. CI: GitHub Actions を使用し、`GITHUB_TOKEN` で GitHub Packages に push する
3. イメージタグ: semver、`latest`、commit SHA の 3 種類を付与
4. テスト: CI では smoke test を実行
5. renovate: 監視可能なものは全て監視する

## Rationale
- Debian はパッケージ互換性が高く qemu/gdb/Rust のセットアップ手順が豊富なため、マルチパッケージを同梱するイメージに適している。
- GitHub Actions は GitHub Packages とシームレスに連携でき、`GITHUB_TOKEN` による認証で自動化しやすい。
- semver+latest+commitSHA のタグ付けは運用上の追跡性とロールバックを両立する。
- smoke test に限定することで CI を高速に保ち、問題があれば手動で深掘りするフローを想定する。
- renovate の包括的監視で依存更新を検出し、PR → CI（ビルド&smoke）→手動承認で公開するワークフローが最も自動化と安全性のバランスが取れる。
 - renovate の包括的監視で依存更新を検出し、PR → CI（ビルド&smoke）→CI 通過かつ非破壊的（non-breaking）であれば自動マージし公開する（条件付き自動承認）。major/破壊的変更は手動レビューを必須とする。

## Alternatives considered
- Alpine をベースにした軽量イメージ: Rust や gdb、qemu の互換性で追加作業が増えるため採用しない。
- Buildx + multi-arch manifest を使ってネイティブ aarch64 と amd64 を同時に出す: 将来的に導入可能。初期は qemu を利用したビルドで aarch64 バイナリを含める方針。

## Open questions (resolved)
- ベースイメージ: Debian に決定（ユーザー指定）
- Push 先とトークン: 同リポジトリの GitHub Packages、`GITHUB_TOKEN` を使用（ユーザー指定）
- others: イメージタグ/テスト/renovate 方針も指定済み
