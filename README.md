# dotfiles

Linux デスクトップ／サーバ環境の設定ファイル群。

| 分類 | 対象 |
| --- | --- |
| シェル | Zsh、Bash |
| ターミナルマルチプレクサ | tmux |
| エディタ | Vim（vim-plug + vim-lsp） |
| デスクトップ環境 | X11 関連、GUI アプリケーション |
| AI エージェント | Claude Code |

## セットアップ

### ワンライナー（Ubuntu 24.04 以降）

素の環境を一度でセットアップする。実行内容を表示し、確認を取ってから進む。

```bash
curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash
```

sudo のパスワードを一度だけ尋ねる。確認を飛ばすには `--yes` を渡す。
パイプ経由では `bash -s --` を挟む。

```bash
curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash -s -- --yes
```

### プリセット

`make <プリセット>` で設定を配置する。既存ファイルは飛ばし、上書きしない（Ubuntu 既定のままの `.bashrc` を除く）。

| プリセット | 内容 |
| --- | --- |
| `minimal` | 基本の dotfiles（`.bashrc` `.zshrc` `.tmux.conf` `.gitconfig` `.latexmkrc` `config/profile.d/`）と、`~/.local/bin` へのコマンドリンク |
| `standard` | minimal + Vim + Claude Code 設定 + zsh プラグイン（推奨） |
| `desktop` | standard + X11 + GUI アプリケーション |
| `agent` | Claude Code 設定のみ（構築済みの環境へ追加する用） |

```bash
make dry-run-standard   # 適用内容を確認する
make standard           # 適用する
```

プリセットを使わずタグを直接指定することもできる。配置対象とタグの対応は `links` にある。

```bash
./bin/create-symlinks.sh --dry-run basic vim agent
./bin/create-symlinks.sh --force basic
```

`.bashrc` は Ubuntu の既定（`/etc/skel/.bashrc`）を土台にしている。
既定は新規ユーザへ必ず配られるため、`/etc/skel/.bashrc` と同じままの `.bashrc` は利用者の設定とみなさず置き換える。
手を入れた `.bashrc` は他の配置対象と同じく飛ばすので、置き換えるには `./bin/create-symlinks.sh --force basic` を使う。

i3wm の設定（`config/i3/` `config/i3status/`）と `bin/xinit.sh` はリポジトリに残しているが、保守しておらず配置対象から外してある。使う場合は手動でリンクする。

配置がうまくいかないときは `make doctor` で状態を確認する。

## 構成

```
Makefile          セットアップの入口（プリセットの定義もここ）
links             配置対象の定義（パス・配置先・タグ）
.editorconfig     エディタ共通の書式設定
bin/              セットアップ用スクリプトと各種ユーティリティ
config/           ~/.config 配下へ配置する設定
config/profile.d/ Bash と Zsh で共有する設定（PATH、環境変数、配色、エイリアス、関数、OS 別設定）
docs/             個別機能のドキュメント
.claude/          Claude Code の設定
```

### bin/

| スクリプト | 内容 |
| --- | --- |
| `bootstrap.sh` | 素の Ubuntu 環境をワンライナーで一括セットアップする |
| `create-symlinks.sh` | dotfiles のシンボリックリンクを作成する（Makefile から呼ばれる） |
| `doctor.sh` | 配置状態を点検する（`make doctor`） |
| `update.sh` | 導入済みのプラグイン・ツールを更新する（`make update`） |
| `lint.sh` | リポジトリを静的検査する（`make lint`） |
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
| `anyenv-setup` | anyenv 配下の \*env を導入し最新版を global に設定する（[設定方法](docs/anyenv.md)、`~/.local/bin` にリンクされる） |
| `xinit.sh` | X 起動時の初期化（i3wm 用。配置対象外） |
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

## ドキュメント

- [カスタマイズ](docs/customize.md) — Git、シェル設定（profile.d）、Vim
- [開発](docs/development.md) — 点検・整形とスクリプトを追加するときの規則

個別機能:

- [anyenv](docs/anyenv.md) — 複数の言語バージョン管理ツールをまとめて扱う
- [Docker](docs/docker.md) — Docker Engine と Lazydocker
- [Claude Code の状態表示](docs/tmux-claude-status.md) — tmux のウィンドウに実行中／承認待ち／完了を表示する
- [wsl-chrome](docs/wsl-chrome.md) — WSL2 から Windows の Chrome を開く・CDP で操作する
