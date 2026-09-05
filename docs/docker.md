# Docker

Docker Engine（公式のインストールスクリプト）と Lazydocker
（Docker コンテナの TUI 管理ツール）を導入する。
Docker Desktop ではなく CLI ベースの環境が入る。

```bash
make docker
```

## 導入後の手順

実行ユーザが docker グループに追加されるため、**ログアウトとログインが要る**。
反映後に動作を確認する。

```bash
docker --version
docker run hello-world
lazydocker
```

## 注意事項

- Lazydocker は `/usr/local/bin` に置かれる
