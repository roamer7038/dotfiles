# anyenv

rbenv・pyenv・nodenv などの \*env をまとめて管理するツール。
`make anyenv` で anyenv-update プラグインと合わせて導入する。

```bash
make anyenv
```

## 導入後の手順

シェル設定への PATH 追加は `config/profile.d/00-common.sh` が済ませているため、`~/.anyenv` があれば次回のシェル起動から有効になる。

```bash
exec $SHELL -l          # シェルを起動し直す
anyenv install --init   # anyenv を初期化する
```

## anyenv-setup

\*env の導入からバージョンの選定・インストール・`global` 設定までをまとめて行う。
`bin/anyenv-setup` にあり、`~/.local/bin` へリンクされる。

```bash
anyenv-setup nodenv               # 最新版を入れて global に設定する
anyenv-setup nodenv rbenv goenv   # 複数をまとめて入れる
anyenv-setup rbenv 3.4.10         # バージョンを指定する
anyenv-setup                      # 導入済みの *env と global のバージョンを表示する
```

| オプション | 内容 |
| --- | --- |
| `--latest` | LTS の系列に絞らず、最新の安定版を選ぶ |
| `-n`, `--dry-run` | 実行内容だけを表示する |
| `-h`, `--help` | 使い方を表示する |

### バージョンの選び方

バージョンを省略した場合は `<env> install -l` の一覧から `x.y.z` 形式の安定版だけを拾い、その最大を選ぶ。
この絞り込みによって jruby・pypy・anaconda などの別実装と、開発版・プレリリースは対象から外れる。

nodenv だけは既定で偶数メジャーに絞る。
Node.js は偶数メジャーが LTS になるという公式方針があるため、偶数メジャーの最大が LTS の最新版にあたる。
ただし新しいメジャーの公開から LTS 昇格までの約1ヶ月は、まだ LTS でない系列を選んでしまう。
その期間に厳密な選択が要るならバージョンを直接指定する。

### 引数の解釈

位置引数は原則すべて \*env の名前として扱う。
引数がちょうど2個で2個目が数字で始まる場合だけ、バージョンの指定とみなす。
\*env の名前が数字で始まることはないため、複数指定と取り違えることはない。

### shim の反映

\*env を新しく入れた直後は、その shim が現在のシェルの PATH に無い。
`anyenv-setup` は自身のプロセス内で shim を通すため処理は最後まで進むが、シェルで使う前に起動し直す。

```bash
exec $SHELL -l
```

## 手作業で行う場合

`anyenv-setup` を使わない場合は次の手順になる。

```bash
anyenv install nodenv   # *env を入れる
exec $SHELL -l          # shim を通すためシェルを起動し直す
nodenv install -l       # 入れられるバージョンを確認する
nodenv install 26.7.0   # バージョンを入れる
nodenv global 26.7.0    # 既定のバージョンに設定する
```

## 注意事項

- rbenv でのビルドには依存パッケージが要る

  ```bash
  sudo apt install -y build-essential libssl-dev zlib1g-dev libyaml-dev
  ```

- \*env とプラグインの更新は `anyenv update` で行う。`make update` からも呼ばれる
