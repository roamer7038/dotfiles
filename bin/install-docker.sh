#!/bin/bash
#
# Docker Engine（公式スクリプト）と Lazydocker を導入する。
# 実行ユーザを docker グループに追加するため、反映にはログアウトが要る。
# 手順の詳細は docs/docker.md を参照。

set -e

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

log_info "Docker の導入を開始します..."

# --- Docker Engine のインストール ---

log_info "Docker Engine を導入します..."

# Docker公式のインストールスクリプトをダウンロード
curl -fsSL https://get.docker.com -o get-docker.sh

# インストールスクリプトを実行
sudo sh get-docker.sh

# インストールスクリプトを削除
rm -f get-docker.sh

log_ok "Docker Engine を導入した"

# --- Lazydocker のインストール ---

log_info "Lazydocker を導入します..."

# Lazydocker（DockerコンテナのTUI管理ツール）をインストール
# 公式インストールスクリプトを使用
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# Lazydockerを/usr/local/binに移動（全ユーザーがアクセス可能に）
sudo mkdir -p /usr/local/bin
sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin

log_ok "Lazydocker を導入した"

# --- ユーザーをdockerグループに追加 ---

log_info "実行ユーザを docker グループへ追加します..."

# 現在のユーザーをdockerグループに追加
# これにより、sudoなしでdockerコマンドを実行できるようになる
sudo gpasswd -a "$USER" docker

log_ok "docker グループへ追加した"

# --- 完了メッセージ ---

log_ok "Docker の導入が完了した"
echo
echo "グループの変更を反映するには一度ログアウトする。"
echo "その後、sudo なしで docker を使える:"
echo "  docker --version"
echo "  docker run hello-world"
echo "  lazydocker"
