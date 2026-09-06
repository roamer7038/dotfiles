# カスタマイズ

配置した設定を環境に合わせて調整する方法。

## Git

`.gitconfig` のユーザ名とメールアドレスを書き換える。

```
[user]
	name = your_username
	email = your@example.com
```

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
