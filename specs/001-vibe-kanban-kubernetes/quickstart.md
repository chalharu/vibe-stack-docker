# クイックスタート — Vibe Kanban（Kubernetes）

このクイックスタートは、ローカルでコンテナイメージをビルドし、スモークテストを実行し、Kubernetes マニフェストを適用するための正確なコマンドを示します。プレースホルダのイメージ名 `ghcr.io/<OWNER>/<REPO>:local` を使用しています。`<OWNER>` と `<REPO>` をあなたの GitHub オーナー／リポジトリ名に置き換えてください。

前提条件

- Docker がインストールされ稼働していること
- `kubectl` が利用可能で、適切なクラスタコンテキストに設定されていること
- （任意）GNU `make`

1) ローカルで Docker イメージをビルド

`<OWNER>` と `<REPO>` をあなたの値に置き換えてください。

- イメージをビルド（リポジトリの `Dockerfile` を使用）:

```
docker build -t ghcr.io/<OWNER>/<REPO>:local .
```

2) スモークテストを実行

リポジトリには `ci/smoke_test.sh` というスモークテストスクリプトが含まれており、ローカルでコンテナを起動してポート `8080` の `/health` エンドポイントを確認します。

- スモークテスト実行（スクリプトは最初の引数にイメージを受け取ります）:

```
# 必要に応じて実行権限を付与
chmod +x ci/smoke_test.sh
# ビルドしたイメージでスモークテストを実行
ci/smoke_test.sh ghcr.io/<OWNER>/<REPO>:local
```

スクリプトが `smoke test passed` と表示されれば、コンテナが起動し `/health` に正常に応答しています。

3) Kubernetes マニフェストを適用

マニフェストは `k8s/vibe-kanban-deployment.yaml` です。デフォルトでは `ghcr.io/chalharu/vibe-stack-docker:latest` を参照しています。適用前にローカルタグ `ghcr.io/<OWNER>/<REPO>:local` に差し替えるか、適用後に `kubectl set image` で差し替えてください。

- 方法 A — マニフェストを編集してから適用:

```
# 例: sed でイメージ参照を置換（macOS 互換）
sed -i.bak 's|ghcr.io/chalharu/vibe-stack-docker:latest|ghcr.io/<OWNER>/<REPO>:local|' k8s/vibe-kanban-deployment.yaml
kubectl apply -f k8s/vibe-kanban-deployment.yaml
```

- 方法 B — 先に適用してからデプロイのイメージを差し替え:

```
kubectl apply -f k8s/vibe-kanban-deployment.yaml
kubectl set image deployment/vibe-kanban vibe-kanban=ghcr.io/<OWNER>/<REPO>:local
```

確認方法

- Pod の状態を確認:

```
kubectl get pods -l app=vibe-kanban
```

- ポートフォワードしてローカルから `/health` を確認:

```
kubectl port-forward deployment/vibe-kanban 8080:8080
curl http://localhost:8080/health
```

受け入れ基準（手動）

- `docker build` が成功してイメージが作成されること
- `ci/smoke_test.sh ghcr.io/<OWNER>/<REPO>:local` が `smoke test passed` と表示すること
- `kubectl get pods` で `vibe-kanban` の Pod が `Running` であること
- `port-forward` 経由で `/health` に正常応答が返ること

注意事項

- GHCR にプッシュする場合は認証が必要です。例: `docker push ghcr.io/<OWNER>/<REPO>:local`
- `sed -i.bak` は macOS 互換の例です。Linux では `sed -i` をご使用ください。
