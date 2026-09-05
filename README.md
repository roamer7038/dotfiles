# dotfiles

Linux デスクトップ／サーバ環境の設定ファイル群。

| 分類 | 対象 |
| --- | --- |
| シェル | Zsh、Bash |
| ターミナルマルチプレクサ | tmux |
| エディタ | Vim（vim-plug + vim-lsp） |
| デスクトップ環境 | i3wm、X11 関連、GUI アプリケーション |
| AI エージェント | Claude Code |

## セットアップ

`make <プリセット>` で設定を配置する。既存ファイルは上書きしない。

| プリセット | 内容 |
| --- | --- |
| `minimal` | 基本の dotfiles（`.bashrc` `.zshrc` `.tmux.conf` `.gitconfig` `.latexmkrc` `config/profile.d/`）と、`~/.local/bin` へのコマンドリンク |
| `standard` | minimal + Vim + Claude Code 設定 + zsh プラグイン（推奨） |
| `desktop` | standard + X11 + GUI アプリケーション |
| `full` | desktop + i3wm |
| `agent` | Claude Code 設定のみ（構築済みの環境へ追加する用） |

```bash
make dry-run-standard   # 適用内容を確認する
make standard           # 適用する
```

上書きしたい場合やファイル単位で選びたい場合は `./bin/create-symlinks.sh --help` を参照。

`.bashrc` は Ubuntu の既定（`/etc/skel/.bashrc`）を土台にしている。
既存ファイルは上書きしないので、置き換えるなら `./bin/create-symlinks.sh --basic --force` を使う。
`full` だけはリンクに加えて `bin/xinit.sh` を `~/.xinit.sh` へコピーする。
リンクではないので、変更したら `make full` をやり直す必要がある。

i3wm の設定は Arch Linux で確認したものだが、2025年時点で保守しておらずそのままでは動作しない可能性がある。

## 構成

```
Makefile          セットアップの入口
.editorconfig     エディタ共通の書式設定
bin/              セットアップ用スクリプトと各種ユーティリティ
bin/lib/          bin/ 配下で共有するログ出力と配置対象の定義
config/           ~/.config 配下へ配置する設定
config/profile.d/ Bash と Zsh で共有する設定（PATH、環境変数、配色、エイリアス、関数、OS 別設定）
docs/             個別機能のドキュメント
.claude/          Claude Code の設定
```

### bin/

| スクリプト | 内容 |
| --- | --- |
| `create-symlinks.sh` | dotfiles のシンボリックリンクを作成する（Makefile から呼ばれる） |
| `doctor.sh` | 配置状態を点検する（`make doctor`） |
| `update.sh` | 導入済みのプラグイン・ツールを更新する（`make update`） |
| `check.sh` | 構文・書式・ドライランを検査する（`make check`） |
| `install-claude-hooks.sh` | Claude Code のフックを設定する（`make claude-hooks`） |
| `authorized_keys.sh` | GitHub の公開鍵を `~/.ssh/authorized_keys` に追記する |
| `install-bun.sh` | bun を導入する |
| `install-docker.sh` | Docker Engine と Lazydocker を導入する |
| `install-vim.sh` | Vim をソースからビルドして入れ替える |
| `install-zsh-plugins.sh` | zsh のプラグインを導入する |
| `tmux-claude-status.sh` | Claude Code の状態を tmux のウィンドウに表示する（[設定方法](docs/tmux-claude-status.md)） |
| `tmux-reorder-sessions.sh` | tmux のセッション番号を連番に振り直す |
| `pane` | tmux のペインを指定した数だけタイル状に分割する（`~/.local/bin` にリンクされる） |
| `multissh` | 複数ホストへ同時に SSH し tmux で一括操作する（`~/.local/bin` にリンクされる） |
| `wsl-chrome` | WSL2 から Windows の Chrome を開く・CDP で操作する（[設定方法](docs/wsl-chrome.md)、`~/.local/bin` にリンクされる） |
| `xinit.sh` | X 起動時の初期化 |
| `wallpaper.sh` | 壁紙をランダムに設定する |
| `system-sleep-xhci.sh` | Dell Inspiron のサスペンド失敗を回避する |
| `minecraft-input.sh` | Minecraft へ日本語を入力する |
| `fw.sh` | iptables の設定例 |

## 追加ツール

| コマンド | 内容 | 手順 |
| --- | --- | --- |
| `make .ssh` | GitHub の公開鍵を `~/.ssh/authorized_keys` に追加 | — |
| `make anyenv` | anyenv + anyenv-update プラグイン | [docs/anyenv.md](docs/anyenv.md) |
| `make docker` | Docker Engine + Lazydocker | [docs/docker.md](docs/docker.md) |
| `make bun` | bun | — |
| `make claude-hooks` | Claude Code のフック設定 | [docs/tmux-claude-status.md](docs/tmux-claude-status.md) |

特定のユーザの公開鍵を取る場合は直接スクリプトを実行する。

```bash
./bin/authorized_keys.sh username
```

## 更新

導入済みのものをまとめて更新する。未導入のものは飛ばす。dotfiles 自体は更新しないので、リポジトリは `git pull` で別途更新する。

```bash
make update
```

| 対象 | 方法 |
| --- | --- |
| zsh プラグイン | `~/.zsh` 配下の git リポジトリを `git pull --ff-only` |
| Vim プラグイン | `PlugUpgrade` と `PlugUpdate` |
| anyenv | `anyenv update`（anyenv-update プラグインが必要） |
| bun | `bun upgrade` |

`-n` を付けると実行内容だけを表示する。

## 点検

どちらも読み取り専用で、何も変更しない。

```bash
make doctor   # 配置状態を点検する
make check    # 構文・書式・ドライランを検査する
```

`doctor` はリンクの有無と向き先、dotfiles 由来のリンク切れ、リポジトリ外に残った古いコピー、依存コマンド、Claude Code のフック設定を見る。

`check` はシェル・Vim・tmux の構文、`.editorconfig` への準拠（タブ、行末空白、CRLF、末尾改行）、Makefile の全ターゲット、全プリセットのドライラン、ドキュメントの相対リンク、README の `bin/` 一覧と実体の一致を確認する。
shfmt があれば整形差分も見る。
vim-plug が未導入の環境では、読み込むと導入が走ってしまうため Vim の確認は飛ばす。

## カスタマイズ

### Git

`.gitconfig` のユーザ名とメールアドレスを書き換える。

```
[user]
	name = your_username
	email = your@example.com
```

### シェルの設定（profile.d）

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
- Bash 側が読むのは `.bashrc` を配置した場合に限る（既存の `.bashrc` を残した環境では読み込まれない）
- 読み込みより前に値を確定させる設定（Zsh の補完の配色など）は上書きできない
- 読み込むのは対話シェルだけなので、`ssh host 'コマンド'` や cron のような非対話の実行には反映されない

### Vim

プラグインは vim-plug で管理する。初回起動時に vim-plug と各プラグインを自動で導入するため、git と curl が要る。
補完と診断は vim-lsp + vim-lsp-settings で行う。対象言語のファイルを開いて `:LspInstallServer` を実行するとサーバが入る（サーバによっては node や go のランタイムが別途要る）。

## ドキュメント

- [anyenv](docs/anyenv.md) — 複数の言語バージョン管理ツールをまとめて扱う
- [Docker](docs/docker.md) — Docker Engine と Lazydocker
- [Claude Code の状態表示](docs/tmux-claude-status.md) — tmux のウィンドウに実行中／承認待ち／完了を表示する
- [wsl-chrome](docs/wsl-chrome.md) — WSL2 から Windows の Chrome を開く・CDP で操作する

## 開発

```bash
make check  # 変更前に検査する
make fmt    # シェルスクリプトを shfmt で整形する
make help   # ターゲット一覧
```

`make fmt` には shfmt が要る。

```bash
sudo apt install shfmt
```
