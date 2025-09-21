# CI / スモークテスト（ローカル実行ガイド）

このファイルは `ci/smoke_test.sh` を使ってローカルでイメージのスモークテストを実行する方法、カスタマイズ方法、トラブルシューティングのヒントをまとめたものです。

**基本的な使い方**
- スクリプトの場所: `ci/smoke_test.sh`
- 使い方（デフォルト）: `./ci/smoke_test.sh`
  - デフォルトは `ghcr.io/chalharu/vibe-stack-docker:local` イメージをプルし、`test_vibe_smoke` という名前のコンテナを `localhost:8080` に公開して `/api/health` に対してヘルスチェックを行います。
- 使い方（引数）: `./ci/smoke_test.sh <IMAGE> <CONTAINER_NAME> <HOST_PORT> <CONTAINER_PORT>`
  - 例: `./ci/smoke_test.sh my-image:local smoke_local 8081 8080`
- 環境変数（オプション）:
  - `HEALTH_PATH`: デフォルト `/api/health`
  - `MAX_RETRIES`: デフォルト `30`（ヘルスチェック試行回数）
  - `SLEEP_SECONDS`: デフォルト `1`（試行間隔）

**ローカルでのフロー（スクリプトの流れ）**
- スクリプトは最初に指定イメージを `docker pull` で取得しようとします。
- プルに失敗した場合、リポジトリのルートにある `Dockerfile` を使ってイメージをビルドします（`docker build -t <IMAGE> -f <REPO_ROOT>/Dockerfile <REPO_ROOT>`）。
- 既存の同名コンテナを削除してから新しいコンテナを `docker run -d --name <CONTAINER> -p <HOST_PORT>:<CONTAINER_PORT> <IMAGE>` で起動します。
- 指定の `HEALTH_PATH` に対して `curl` を繰り返し行い、成功すれば `smoke test passed` を返します。
- コンテナが途中で停止した場合、スクリプトはログを出力して失敗します。

**よく使うコマンド例**
- イメージを明示的にビルドしてからスモークテスト:
  - `docker build -t my-image:local -f Dockerfile .`
  - `./ci/smoke_test.sh my-image:local my_container 8080 8080`
- 別ポートで実行:
  - `./ci/smoke_test.sh ghcr.io/chalharu/vibe-stack-docker:local smoke_local 8081 8080`

**トラブルシューティング**
- スクリプトが `docker` コマンドを見つけられない: Docker をインストールしてください（`docker --version` で確認）。
- ヘルスチェックが失敗する:
  - まずコンテナログを確認: `docker logs <CONTAINER>`（スクリプトは EXIT 時に自動でログを表示します）
  - `docker ps -a` でコンテナの状態を確認
  - アプリが起動しているか、`/usr/local/bin/entrypoint.sh` が正常に実行されたか確認するために、手動でコンテナに入る: `docker run --rm -it --entrypoint /bin/bash <IMAGE>` または `docker exec -it <CONTAINER> /bin/bash`
- ポートが既に使われている: 別の `HOST_PORT` を指定して実行するか、既存プロセスを停止してください。

**CI キャッシュとローカルでの関係**
- スクリプト自身はキャッシュ処理を行いませんが、イメージをビルドする際に Dockerfile に定義されたレイヤーキャッシュ、ならびに BuildKit のキャッシュマウント（Cargo 等）を利用できます。
- ローカルで BuildKit キャッシュを使うには:
  - `DOCKER_BUILDKIT=1 docker build --progress=plain --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/usr/local/cargo/git -t my-image:local .`
- CI では前回ビルドしたイメージや `actions/cache` を使って依存取得時間を短縮します（ワークフロー側で `cache-from` などを設定している場合）。

**追加のデバッグヒント（素早い確認）**
- コンテナを対話的に起動して手動で起動スクリプトを試す:
  - `docker run --rm -it --entrypoint /bin/bash <IMAGE>`
  - コンテナ内で: `./usr/local/bin/entrypoint.sh` を実行して出力を確認
- Rust 関連のトラブル: `rustup show`, `rustc --version`, `cargo --version`, `rustup target list --installed`
- QEMU / binfmt の問題: ホスト側で `docker/setup-qemu-action@v2` 相当の登録が必要な場合があります。ホストで `update-binfmts --display` を実行して確認してください。

必要であれば、CI ワークフロー上でのキャッシュ設定例や、`docker/build-push-action` を利用したキャッシュ共有のサンプルを追加で用意します。ご希望があれば教えてください。