AGENTS.md

001-vibe-kanban-kubernetes スペック向け自動化エージェント用ガイド（日本語）
変更は小さく保ち、ローカルでテストし、このフォルダ内の仕様ファイルを参照してください。

依存: 実装・デプロイの前に `T001` を完了してください。

対象範囲
- 目的: 自動化エージェント（CI ボット、スクリプト）に対して、どのファイルを編集し、どのコマンドを実行し、テストがどこにあるかを示します。
- PR は小さく自己完結にしてください。スコープが変わる場合は `plan.md` と `tasks.md` を更新してください。

主に編集するファイル
- `specs/001-vibe-kanban-kubernetes/spec.md` — 要件と受け入れ基準
- `specs/001-vibe-kanban-kubernetes/plan.md` — 実装計画とマイルストーン
- `specs/001-vibe-kanban-kubernetes/tasks.md` — タスク一覧と状態
- `specs/001-vibe-kanban-kubernetes/data-model.md` — データスキーマ／モデル
- `k8s/vibe-kanban-deployment.yaml` — Kubernetes マニフェスト
- `Dockerfile` と `docker/entrypoint.sh` — コンテナのビルドと起動ロジック
- `.github/workflows/build-and-publish.yml` — ビルド／公開の CI 定義
- `ci/smoke_test.sh` — スモークテスト実行スクリプト
- `tests/contract/` — コントラクト／統合テスト（例: `test_health_endpoint.sh`）
- `docs/implementation/` — 実装ノート
- `.specify/scripts/bash/` — 補助スクリプトとチェック

主要コマンド（ローカルまたは CI で実行）
- スモークテスト: `bash ci/smoke_test.sh`
- コントラクトテスト: `bash tests/contract/test_health_endpoint.sh`
- Docker イメージビルド: `docker build -t vibe-kanban .`
- コンテナ起動（簡易確認）: `docker run --rm -p 8080:8080 vibe-kanban`
- k8s マニフェスト適用（kube コンテキスト要）: `kubectl apply -f k8s/vibe-kanban-deployment.yaml`
- 事前チェック: `bash .specify/scripts/bash/check-task-prerequisites.sh`
- リポジトリ検索: `rg "pattern"`（ripgrep）

テスト
- 場所: `tests/contract/` と `ci/`
- PR を出す前にローカルでスモークテストとコントラクトテストを実行してください。API や挙動を変更した場合はテストを更新してください。
- CI: GitHub Actions は `.github/workflows/` に定義されています。

エージェント向けベストプラクティス
- 変更は最小限かつ焦点を絞って行う。スコープ変更時は `plan.md` と `tasks.md` を更新。
- 挙動変更にはテストを追加・更新する。
- スクリプトは冪等で安全なデフォルトを持たせる（破壊的操作はデフォルトで行わない）。
- 本番に昇格する前に開発クラスタで k8s マニフェストを検証する。
- 日本語でのやりとり: PR 説明、コメント、質問など、エージェントと人間のやりとりは原則日本語で行ってください。特別な合意がある場合にのみ英語を使用できます。

トラブルシューティング
- CI の失敗: GitHub の Actions ログ（`.github/workflows/`）を確認する。
- テスト失敗: ローカルで再現して `tests/contract/` のフィクスチャや期待されるエンドポイントを確認する。

参照場所
- 仕様・調査: `specs/001-vibe-kanban-kubernetes/*.md`
- 実装メモ: `docs/implementation/`

判断があいまいな場合は停止して人間のレビューを求めること。重大な設計判断は単独で行わないでください。
