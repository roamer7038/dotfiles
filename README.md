# dotfiles

Linuxデスクトップ/サーバ環境設定ファイル群

## 概要

環境に応じて以下のソフトウェアの設定ファイルを管理・適用します。

- シェル: Zsh
- ターミナルマルチプレクサ: Tmux
- エディタ: Vim
- デスクトップ環境: i3wm、X11関連設定、その他GUIアプリケーション設定

また、インストール用のスクリプト等も含まれています。

## セットアップ

makeコマンドを使用して環境をセットアップします。

### プリセット

#### minimal

基本的なdotfilesのみをセットアップ
(.bashrc .zshrc .tmux.conf .gitconfig .latexmkrc)

```bash
make minimal
```

#### standard（デフォルト）

minimal + vim設定 + zshプラグイン

```bash
make standard
```

vimプラグインは vim-plug を利用して管理されます。
初回起動時に vim-plug と各プラグインを自動インストールするため、git と curl が必要です。
言語ごとの補完・診断は vim-lsp + vim-lsp-settings で行います。
対象言語のファイルを開き :LspInstallServer でサーバーを導入してください
（サーバーにより node/npm や go 等のランタイムが別途必要）。

#### desktop

standard + X11設定 + GUIアプリケーション設定

```bash
make desktop
```

#### full

すべての設定を含む完全セットアップ（i3wm含む）

```bash
make full
```

i3wmの動作確認はArch Linux環境で行っています。
本設定ファイルは2025年時点で既に保守されていないため、正常に動作しない可能性があります。

### ドライラン

変更内容を事前確認する場合:

```bash
make dry-run-minimal    # minimalの変更内容を確認
make dry-run-standard   # standardの変更内容を確認
make dry-run-desktop    # desktopの変更内容を確認
make dry-run-full       # fullの変更内容を確認
```

## 追加機能

### SSH公開鍵認証

GitHubアカウントの公開鍵を取得してauthorized_keysに追加:

```bash
make .ssh
```

特定のユーザの鍵を取得したい場合は直接スクリプトを実行してください。

```bash
./bin/authorized_keys.sh username
```

### anyenv

複数のプログラミング言語環境を管理するためのツール。anyenv-updateプラグイン付きでインストールされます。

```bash
make anyenv
```

インストール後の手順:

1. シェル設定ファイルにパスを追加:
   ```bash
   export PATH="$HOME/.anyenv/bin:$PATH"
   eval "$(anyenv init -)"
   ```

2. シェルを再起動:
   ```bash
   exec $SHELL -l
   ```

3. anyenvを初期化:
   ```bash
   anyenv install --init
   ```

4. 必要な*envをインストール:
   ```bash
   anyenv install rbenv
   anyenv install pyenv
   anyenv install nodenv
   exec $SHELL -l
   ```

5. 各環境で言語バージョンをインストール:
   ```bash
   rbenv install 3.2.0
   pyenv install 3.11.0
   nodenv install 18.0.0
   ```

#### 注意事項

- **rbenv使用時**: ビルドに必要なパッケージをインストール
  ```bash
  apt install -y build-essential libssl-dev zlib1g-dev libyaml-dev
  ```

- **定期的な更新**: anyenv-updateプラグインで全*envとプラグインを更新
  ```bash
  anyenv update
  ```

- **シェル再起動**: *envのインストール後は必ずシェルを再起動

### Docker

Docker EngineとLazydocker（DockerコンテナのTUI管理ツール）をインストールします。

```bash
make docker
```

インストール後の手順:

1. ログアウト/ログインして、dockerグループの変更を反映させる

2. Docker動作確認:
   ```bash
   docker --version
   docker run hello-world
   lazydocker
   ```

#### 注意事項

- インストール後は**必ずログアウト/ログインが必要**です（dockerグループの反映のため）
- Docker Desktopではなく、CLIベースのDocker Engine環境がインストールされます
- Lazydockerは`/usr/local/bin`に配置されます

### Claude Codeの状態表示

tmuxで複数ウィンドウを使っていると、非アクティブなウィンドウでClaude Codeが
タスクを終えたり承認待ちになったりしても気づけません。
`bin/tmux-claude-status.sh` は、その状態をウィンドウステータスの背景色で示します。

| 状態 | 背景色 | 表示 |
| --- | --- | --- |
| 実行中 | 青 | ウィンドウ名の後ろにスピナー |
| 承認・入力待ち | 黄 | — |
| 完了 | 緑 | — |

tmuxの`window-status-style`はウィンドウが非アクティブなときのみ有効なため、
今見ているウィンドウは着色されません。
また、ウィンドウを離れる/選ぶと「承認待ち」「完了」は既読として解除されます
（「実行中」は色が残ります）。

`.tmux.conf`側の設定は済んでいるので、`~/.claude/settings.json`にフックを追加します。

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "\"$HOME/dotfiles/bin/tmux-claude-status.sh\" running", "timeout": 5 } ] }
    ],
    "Notification": [
      { "hooks": [ { "type": "command", "command": "\"$HOME/dotfiles/bin/tmux-claude-status.sh\" waiting", "timeout": 5 } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "\"$HOME/dotfiles/bin/tmux-claude-status.sh\" done", "timeout": 5 } ] }
    ],
    "SessionEnd": [
      { "hooks": [ { "type": "command", "command": "\"$HOME/dotfiles/bin/tmux-claude-status.sh\" none", "timeout": 5 } ] }
    ]
  }
}
```

#### 注意事項

- `~/.claude/settings.json`は環境ごとに内容が異なるためdotfilesの管理対象外です。手動で追記してください
- 操作するのは対象ウィンドウのオプションのみで、tmuxのグローバル設定は変更しません。Claude Codeを起動していないウィンドウには影響しません
- `monitor-activity`が有効だと、出力のあったウィンドウは`window-status-activity-style`（既定は`reverse`）で反転描画され背景色が打ち消されます。これを避けるため、着色時は対象ウィンドウの`window-status-activity-style`も同じ値に設定します
- スピナーを動かすには毎秒の再描画が必要です。`status-interval`はグローバル設定のため、**実行中のウィンドウがある間だけ**1に上げ、無くなったら元の値に戻します。元の値は変更前に保存するので、`.tmux.conf`側の設定を書き換える必要はありません
- 色は`bin/tmux-claude-status.sh`冒頭の`STYLE_*`、スピナーの有無は同じく冒頭の`SPINNER`で変更できます（`off`にすると`status-interval`も変更されなくなります）

## その他各種スクリプト

`bin/`ディレクトリ内にはいくつかスクリプトが配置されています。

- `authorized_keys.sh`：GitHubから公開鍵を取得して`~/.ssh/authorized_keys`に追加
- `fw.sh`：iptables向けの設定スクリプト例
- `install-docker.sh`：Docker環境のインストールスクリプト、Docker Desktopを使わずCLIのみのセットアップです。
- `tmux-claude-status.sh`：Claude Codeの状態（実行中/承認待ち/完了）をtmuxのウィンドウ背景色とスピナーで可視化。Claude Codeのフックから呼び出します（[設定方法](#claude-codeの状態表示)）

## カスタマイズ

### Git設定

`.gitconfig`を編集してユーザー名とメールアドレスを変更:

```
[user]
	name = your_username
	email = your@example.com
```

### Zsh設定

Zsh起動時に `~/.config/profile.d/`配下のスクリプト群を`source`で読み込みます。
必要に応じてディレクトリを作成し、スクリプトを追加してください。

例：プロキシ設定、環境変数設定など

```bash
mkdir -p ~/.config/profile.d
echo 'export http_proxy="http://proxy.example.com:8080"' > ~/.config/profile.d/proxy.sh
```

## ヘルプ

利用可能なmakeターゲット一覧:

```bash
make help
```
