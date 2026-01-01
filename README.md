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

vimプラグインは dein を利用して管理されます。
vim 8.0以降、nodejs、npmが必要です。

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

## その他各種スクリプト

`bin/`ディレクトリ内にはいくつかスクリプトが配置されています。

- `authorized_keys.sh`：GitHubから公開鍵を取得して`~/.ssh/authorized_keys`に追加
- `fw.sh`：iptables向けの設定スクリプト例
- `install-docker.sh`：Docker環境のインストールスクリプト、Docker Desktopを使わずCLIのみのセットアップです。

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
