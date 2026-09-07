# カスタマイズ

配置した設定を環境に合わせて調整する方法。

## Git

### ユーザ情報

`.gitconfig` のユーザ名とメールアドレスを書き換える。

```
[user]
	name = your_username
	email = your@example.com
```

### 差分表示（delta）

`git diff`、`git show`、`git add -p` の差分は [delta](https://dandavison.github.io/delta/) で表示する。
シンタックスハイライト、行番号、左右2画面の表示が付く。

```bash
sudo apt install git-delta
```

`bootstrap.sh` は他の apt パッケージと一緒にこれを入れる。
delta が無い環境では git の既定の表示に落ちるため、入れずに使ってもよい。

| 設定 | 内容 | delta が無いとき |
| --- | --- | --- |
| `core.pager` | ページャ | `$PAGER`（未設定なら `less`） |
| `interactive.diffFilter` | `git add -p` の差分の整形 | `cat`（素の色付き差分） |
| `[delta]` | 表示の設定（配色、`side-by-side`、`line-numbers`、シンタックステーマ） | 参照されない |

git にはコマンドの有無で設定を切り替える機能が無いため（`includeIf` の条件は `gitdir` `onbranch` `hasconfig` のみ）、上2つの値は `command -v` で分岐するシェル式として書いてある。
値はシェル経由で実行されるので、この書き方で delta の有無を判定できる。

表示を変えるときは `[delta]` の各項目を編集する。
使えるテーマは `delta --list-syntax-themes` で一覧できる。
一時的に素の差分を見るには `git --no-pager diff` を使う。

### エイリアスと既定

| 設定 | 内容 |
| --- | --- |
| `alias.st` `alias.co` `alias.br` `alias.sw` `alias.ch` | `status` `commit` `branch` `switch` `checkout` |
| `core.filemode = false` | 実行属性の差分を無視する（Windows と共有するリポジトリ向け） |
| `init.defaultBranch = main` | 新規リポジトリの既定ブランチ |
| `credential.helper = cache --timeout 86400` | 認証情報を1日メモリに保持する |
| `merge.tool = vimdiff` | `git mergetool` で使うツール |

## シェルの設定（profile.d）

`.bashrc` と `.zshrc` は、起動時に `~/.config/profile.d/` 配下を名前順に読み込む。
PATH の構築、`EDITOR` や `LESS` などの環境変数、配色、エイリアス、関数、WSL2 向けの設定はこの仕組みで配る。
プロンプトや補完、`setopt` や `shopt` のようなシェル固有の記法が要るものは各 rc 側に置く。

```
~/.config/profile.d/00-common.sh   dotfiles が置く共通設定（編集しない）
~/.config/profile.d/*.sh           利用者が自由に置く設定
```

`00-common.sh` はリポジトリの `config/profile.d/00-common.sh` へのリンクで、名前順で最初に読まれる。
プロキシ設定や環境ごとの環境変数は、利用者が同じディレクトリへファイルを足して指定する。
`00-common.sh` より後に読まれるため、共通設定の値をここで上書きできる。

```bash
echo 'export http_proxy="http://proxy.example.com:8080"' > ~/.config/profile.d/proxy.sh
```

読み込みには次の制約がある。

- Bash が読むのは `*.sh` のみで、Zsh は `*.sh` と `*.zsh` を読む
- Bash 側が読むのは `.bashrc` を配置した場合に限る（`agent` のように `.bashrc` を含まないプリセットや、手を入れた `.bashrc` を残した環境では読み込まれない）
- 読み込みより前に値を確定させる設定（Zsh の補完の配色など）は上書きできない
- 読み込むのは対話シェルだけなので、`ssh host 'コマンド'` や cron のような非対話の実行には反映されない

## Vim

プラグインは vim-plug で管理する。初回起動時に vim-plug と各プラグインを自動で導入するため、git と curl が要る。
補完と診断は vim-lsp + vim-lsp-settings で行う。対象言語のファイルを開いて `:LspInstallServer` を実行するとサーバが入る（サーバによっては node や go のランタイムが別途要る）。
