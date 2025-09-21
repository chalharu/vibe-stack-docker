# Docker イメージとレイヤー（短いガイド）

この文書はリポジトリの `Dockerfile` （ルート）をベースに、どのレイヤーに何を追加すべきか、ビルドキャッシュの仕組み、ローカルでのデバッグ手順を簡潔にまとめたものです。

**レイヤーの概観**
- ベースイメージ（`FROM`）: `debian:bookworm-slim` を使用しています。ここを変更するとイメージ全体が再構築されるため、頻繁に変える必要がある変更は避けてください。
- 基本依存関係インストール（`apt-get install`）: Git、ビルドツール、QEMU、gdb などのシステムパッケージをここでまとめて入れています。システムパッケージを追加する場合はこのセクション（`RUN apt-get update && apt-get install -y --no-install-recommends \ ...`）に追記してください。
- GitHub CLI 専用レイヤー: `gh` のインストールだけをまとめたレイヤーがあります。GitHub CLI を変更・更新する場合はこのレイヤーを編集します。
- Rust ツールチェーンのインストール: `rustup` のインストールと `rustup toolchain install` / `rustup component add` / `rustup target add` を実行するレイヤーです。Rust のツールチェーンや追加コンポーネント（`rust-src`, `rustfmt`, `clippy`, `llvm-tools` など）を増やす場合はここを編集してください。
- Node.js と npm グローバルパッケージ: `nodejs` のインストールと `/tmp/install_vibe.sh`, `/tmp/install_opencode.sh` を実行するレイヤーがあります。npm のグローバルパッケージを追加・変更する場合はこれらのスクリプト（`docker/install_vibe.sh` / `docker/install_opencode.sh`）を編集するのが読みやすく安全です。
- ユーザー作成/エントリポイント/ボリューム: 非 root ユーザー `runner` の作成、`VOLUME` と `ENTRYPOINT` の設定はそれぞれ分離されています。これらはイメージの実行時振る舞いに関係するため、頻繁には変更しないでください。

**どこに何を追加するか（実践）**
- システム（apt）パッケージ: ルートの `Dockerfile` の最初の `RUN apt-get update && apt-get install -y --no-install-recommends \` セクションに追記します。例: `... python3-venv \` のように末尾に追加してください。
- GitHub CLI 等の外部リポジトリパッケージ: `gh` のような専用インストール手順が既にあるので、同様に別レイヤーを作るか、そのブロックに追記します。
- Node.js グローバル npm パッケージ: `docker/install_vibe.sh` / `docker/install_opencode.sh` に `npm install -g <pkg>` を追加します。スクリプトにまとめることで可読性が上がり、CI とローカルの挙動が一致します。
- Rust コンポーネント / ターゲット: `rustup component add --toolchain <toolchain> <component> || true` や `rustup target add <target> --toolchain <toolchain> || true` の行に追記します。`|| true` が付いているため、存在しないコンポーネントでもビルドが止まりません（ベストエフォート）。

**キャッシュについて**
- Docker レイヤーキャッシュ: 各 RUN/COPY 命令はレイヤーとしてキャッシュされます。依存関係をインストールするコマンド（apt, npm, rustup）は、ソースコードや頻繁に変わるファイルより前に置くのが効果的です。これにより、コード変更時にこれらのレイヤーを再構築する必要がなくなります。
- BuildKit キャッシュマウント（Cargo のキャッシュ）: `Dockerfile` は `/usr/local/cargo/registry` と `/usr/local/cargo/git` をキャッシュ向けに予め作成しています。BuildKit が有効な場合、ビルド時に以下のようにキャッシュをマウントして `cargo fetch` 等を実行すると、依存のダウンロードが再利用されます。例:

  `DOCKER_BUILDKIT=1 docker build --progress=plain \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    -t my-image:local .`

- CI レジストリキャッシュ: CI 環境では、`--cache-from` / プライベートレジストリを使って前回イメージを参照することでレイヤーキャッシュを有効にできます。GitHub Actions では `actions/cache` や `docker/build-push-action` の `cache-from` オプションを併用してください。

**ローカルでのデバッグと確認（短く実用的に）**
- コンテナにシェルを起動:
  - 一時コンテナからシェルを起動する（デバッグ用）: `docker run --rm -it --entrypoint /bin/bash ghcr.io/chalharu/vibe-stack-docker:local`（`/bin/bash` が無い場合は `/bin/sh`）
  - 実行中コンテナへ入る: `docker exec -it <container-name> /bin/bash`（または `/bin/sh`）
- ログ確認: `docker logs <container-name>`
- Rust の確認:
  - `rustup --version`、`rustc --version`、`cargo --version` でバージョン確認
  - インストール済みツールチェーン: `rustup toolchain list`
  - インストール済みターゲット: `rustup target list --installed` または `rustup target list --installed --toolchain <toolchain>`
  - コンポーネント確認: `rustup component list --installed --toolchain <toolchain>`
- QEMU / binfmt の確認: `update-binfmts --display`（イメージ内で実行すると表示されますが、ホスト側での binfmt 登録が必要な場合があります）

**デバッグのヒントとよくある操作**
- 依存追加後にレイヤーだけ再ビルドしたい: 依存を追加したブロックのみを編集して `DOCKER_BUILDKIT=1 docker build` でビルドします。頻繁に変わる設定は Dockerfile の後半（コード COPY 部分）に置くとビルド効率が上がります。
- エントリポイントが起動できない場合: `--entrypoint /bin/bash` で入って、`/usr/local/bin/entrypoint.sh` を手動で実行して出力を確認します。
- non-root ユーザーでのファイル権限問題: Dockerfile 内で `chown` している場所（`/usr/local/cargo` など）を確認してください。必要なら `docker run -u 0 ...` で root で起動して権限を修正できます。

このドキュメントは簡潔さを優先しています。より詳細な手順や CI 設定に関する補足が必要であれば指示してください。