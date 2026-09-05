# anyenv

rbenv・pyenv・nodenv などの \*env をまとめて管理するツール。
`make anyenv` で anyenv-update プラグインと合わせて導入する。

```bash
make anyenv
```

## 導入後の手順

シェル設定への PATH 追加は `shell/common.sh` が済ませているため、
`~/.anyenv` があれば次回のシェル起動から有効になる。

```bash
exec $SHELL -l          # シェルを起動し直す
anyenv install --init   # anyenv を初期化する
```

使う \*env を入れ、もう一度シェルを起動し直す。

```bash
anyenv install rbenv
anyenv install pyenv
anyenv install nodenv
exec $SHELL -l
```

各 \*env で言語のバージョンを入れる。

```bash
rbenv install 3.2.0
pyenv install 3.11.0
nodenv install 18.0.0
```

## 注意事項

- rbenv でのビルドには依存パッケージが要る

  ```bash
  sudo apt install -y build-essential libssl-dev zlib1g-dev libyaml-dev
  ```

- \*env を入れた後は必ずシェルを起動し直す
- 全ての \*env とプラグインの更新は `anyenv update` で行う。
  `make update` からも呼ばれる
