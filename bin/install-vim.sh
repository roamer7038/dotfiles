#!/bin/sh
# ============================================================
# install-vim.sh
# ============================================================
#
# 概要:
#   Vimの最新版をソースコードからビルド・インストールするスクリプト
#
# 用途:
#   古いVimバージョンがインストールされている環境を最新版に更新
#   パッケージマネージャーで提供されていない最新機能を使用したい場合
#
# 対象OS:
#   Ubuntu 22.04 LTS（他のDebianベースのディストリビューションでも動作する可能性あり）
#
# 依存関係:
#   - wget
#   - unzip
#   - git
#   - make
#   - build-essential
#   - ncurses-dev
#
# ビルドオプション:
#   デフォルトの設定でビルド（./configure引数なし）
#   必要に応じて、Python/Ruby/Lua等のサポートを追加可能
#
# 使用例:
#   $ ./install-vim.sh
#
# 注意事項:
#   - sudo権限が必要です
#   - ビルドには数分かかります
#   - 既存のVimは削除されます
#
# ============================================================

echo "Starting Vim installation from source..."

###########################################################
# パッケージリストの更新
###########################################################

echo "Updating package list..."
sudo apt update

###########################################################
# 既存のVimを削除
###########################################################

echo "Removing old Vim installation..."

# 既存のVimパッケージを削除（インストールされている場合）
sudo apt remove vim vim-runtime gvim

###########################################################
# ビルドに必要な依存関係をインストール
###########################################################

echo "Installing build dependencies..."

# ビルドツールと開発用ライブラリをインストール
# - git: ソースコード管理
# - make: ビルドツール
# - build-essential: gcc等のコンパイラ
# - ncurses-dev: ターミナルUI用ライブラリ
# - unzip: アーカイブ解凍
sudo apt install git make build-essential ncurses-dev unzip

###########################################################
# Vimソースコードのダウンロード
###########################################################

echo "Downloading Vim source code..."

# GitHubからVimの最新版（masterブランチ）をダウンロード
wget https://github.com/vim/vim/archive/master.zip

# ダウンロードしたアーカイブを解凍
unzip master.zip

# ソースディレクトリに移動
cd vim-master/src

###########################################################
# ビルド設定
###########################################################

echo "Configuring build..."

# ビルド設定を実行
# オプションなしでデフォルト設定を使用
# 必要に応じて以下のようなオプションを追加可能:
# --enable-pythoninterp=yes  # Python 2サポート
# --enable-python3interp=yes # Python 3サポート
# --enable-rubyinterp=yes    # Rubyサポート
# --enable-luainterp=yes     # Luaサポート
./configure

###########################################################
# ビルドとインストール
###########################################################

echo "Building Vim... (this may take a few minutes)"

# ビルドを実行
make

echo "Installing Vim..."

# システムにインストール（/usr/local/binに配置）
sudo make install

###########################################################
# クリーンアップ
###########################################################

echo "Cleaning up..."

# ソースディレクトリから移動
cd ../..

# ダウンロードしたファイルとビルドディレクトリを削除
rm -rf vim-master
rm master.zip

###########################################################
# インストール確認
###########################################################

echo ""
echo "============================================"
echo "Vim installation completed successfully!"
echo "============================================"
echo ""
echo "Installed version:"
vim --version | head -n 1
echo ""
echo "Vim is installed at: $(which vim)"
echo ""
