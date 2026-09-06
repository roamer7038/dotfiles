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

# --- Docker Engine ---

log_info "Installing Docker Engine..."

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

log_ok "Docker Engine installed"

# --- Lazydocker ---

log_info "Installing Lazydocker..."

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# 全ユーザから使えるよう /usr/local/bin へ移す
sudo mkdir -p /usr/local/bin
sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin

log_ok "Lazydocker installed"

# --- docker グループへの追加 ---

log_info "Adding the current user to the docker group..."

sudo gpasswd -a "$USER" docker

log_ok "Added to the docker group"

log_ok "Docker installation complete"
echo
echo "Log out once to apply the group change. After that docker works without sudo:"
echo "  docker --version"
echo "  docker run hello-world"
echo "  lazydocker"
