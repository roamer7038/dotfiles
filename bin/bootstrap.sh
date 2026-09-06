#!/bin/bash
#
# dotfiles をワンライナーで導入する。Ubuntu 24.04 以降が対象。
#
#   curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash
#
# リポジトリが無い状態で curl から実行されるため、他のスクリプトに依存しない。
# clone 以降は Makefile と既存スクリプトへ委譲する。
# Docker はシステムへの影響が大きいため導入せず、最後に案内するだけにする。

set -euo pipefail

# ============================================================
# 設定
# ============================================================

REPO_URL="https://github.com/roamer7038/dotfiles.git"
REPO_SSH_URL="git@github.com:roamer7038/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

MIN_UBUNTU_VERSION="24.04"

# 必須     git curl ca-certificates zsh tmux vim-nox
# 任意     bc（.tmux.conf のバージョン判定）jq（claude-hooks）xsel（クリップボード連携）
# ファイラ ranger
# 開発用   build-essential（make）shfmt（make fmt）
APT_PACKAGES=(
  git
  curl
  ca-certificates
  zsh
  tmux
  vim-nox
  bc
  jq
  xsel
  ranger
  build-essential
  shfmt
)

CLAUDE_INSTALL_URL="https://claude.ai/install.sh"

ASSUME_YES=false

# ============================================================
# ログ出力
# ============================================================

# 全スクリプト共通の定型ブロック。clone 前に単体で走るため自己完結させる
if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }
log_step() {
  echo
  echo "$B==>$N $*"
}

# ============================================================
# 引数解析
# ============================================================

show_usage() {
  cat <<EOM
Usage: bootstrap.sh [OPTIONS]

Set up this dotfiles repository from scratch on Ubuntu ${MIN_UBUNTU_VERSION}+.

OPTIONS:
  -y, --yes      Skip the confirmation prompt
  -h, --help     Show this message

EXAMPLES:
  curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash
  curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash -s -- --yes
EOM
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -y | --yes) ASSUME_YES=true ;;
    -h | --help)
      show_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_usage >&2
      exit 1
      ;;
    esac
    shift
  done
}

# ============================================================
# 前提チェック
# ============================================================

check_prerequisites() {
  if [ "$(id -u)" -eq 0 ]; then
    log_error "Do not run as root: the configuration is placed in a regular user's home"
    exit 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo not found: required to install packages"
    exit 1
  fi

  check_os
}

check_os() {
  local id="" version_id="" pretty=""

  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    version_id="${VERSION_ID:-}"
    pretty="${PRETTY_NAME:-$id $version_id}"
  fi

  if [ "$id" = ubuntu ] && version_ge "$version_id" "$MIN_UBUNTU_VERSION"; then
    log_ok "Supported OS: $pretty"
    return
  fi

  log_error "Requires Ubuntu $MIN_UBUNTU_VERSION or later: ${pretty:-unknown}"
  exit 1
}

# $1 >= $2 なら真
version_ge() {
  [ -n "$1" ] || return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$2" ]
}

# ============================================================
# 各ステップ
# ============================================================

show_plan() {
  cat <<EOM

This script will:

  1. Install apt packages   ${APT_PACKAGES[*]}
  2. Clone the repository into $DOTFILES_DIR
  3. Move the default ~/.bashrc aside and link the configuration (make standard)
  4. Install Vim plugins
  5. Install Claude Code and its tmux status hooks
  6. Install anyenv and bun
  7. Check the result (make doctor)

sudo asks for your password once.

EOM
}

confirm() {
  [ "$ASSUME_YES" = true ] && return 0

  # read のプロンプトは stderr へ出るため、read の stderr は塞げない。
  # tty が開けるかを先に判定する。
  if ! { : </dev/tty; } 2>/dev/null; then
    log_error "No terminal to confirm on: rerun with --yes"
    exit 1
  fi

  local answer=""
  read -r -p "Continue? [y/N]: " answer </dev/tty || answer=""

  case "$answer" in
  y | Y | yes | YES) return 0 ;;
  esac

  log_info "Aborted"
  exit 0
}

authenticate_sudo() {
  log_step "Authenticating sudo"
  if sudo -n true 2>/dev/null; then
    log_ok "sudo already authenticated"
    return
  fi
  sudo -v
  log_ok "sudo authenticated"
}

install_packages() {
  log_step "Installing apt packages"
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
  log_ok "Packages installed"
}

clone_repository() {
  log_step "Fetching the repository"

  if [ ! -e "$DOTFILES_DIR" ]; then
    git clone "$REPO_URL" "$DOTFILES_DIR"
    log_ok "Cloned: $DOTFILES_DIR"
    return
  fi

  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    log_error "$DOTFILES_DIR is not a git repository: move or remove it and try again"
    exit 1
  fi

  if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
    log_skip "$DOTFILES_DIR has uncommitted changes: not updating"
    return
  fi

  if git -C "$DOTFILES_DIR" pull --ff-only; then
    log_ok "Updated: $DOTFILES_DIR"
  else
    log_warn "Update failed: continuing with the existing checkout"
  fi
}

# Ubuntu は新規ユーザへ /etc/skel/.bashrc を必ずコピーするため、
# create-symlinks.sh が既存ファイルとして常に飛ばしてしまう。
# 退避しておき、dotfiles の .bashrc が配置されるようにする。
backup_default_bashrc() {
  log_step "Moving the default .bashrc aside"

  local rc="$HOME/.bashrc" backup="$HOME/.bashrc.orig"

  if [ ! -e "$rc" ] || [ -L "$rc" ]; then
    log_skip "Nothing to move aside"
    return
  fi

  if [ -e "$backup" ]; then
    log_skip "$backup already exists: keeping it"
    return
  fi

  mv "$rc" "$backup"
  log_ok "Moved $rc to $backup"
}

# standard は agent（~/.claude）を含むので make agent は呼ばない
link_dotfiles() {
  log_step "Linking the configuration (make standard)"
  make -C "$DOTFILES_DIR" standard
  log_ok "Configuration linked"
}

# .vimrc は初回起動時に vim-plug とプラグインを同期導入する。
# それをヘッドレスで済ませ、初回の対話起動を待たせない。
install_vim_plugins() {
  log_step "Installing Vim plugins"

  if ! command -v vim >/dev/null 2>&1; then
    log_warn "vim not found: skipping"
    return
  fi

  if vim --not-a-term -c 'qall!' </dev/null >/dev/null 2>&1; then
    log_ok "Vim plugins installed"
  else
    log_warn "Vim plugin installation failed: start vim and run :PlugInstall"
  fi
}

install_claude_code() {
  log_step "Installing Claude Code"

  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    log_skip "Claude Code already installed"
    return
  fi

  if curl -fsSL "$CLAUDE_INSTALL_URL" | bash; then
    log_ok "Claude Code installed"
  else
    log_warn "Claude Code installation failed: curl -fsSL $CLAUDE_INSTALL_URL | bash"
  fi
}

install_claude_hooks() {
  log_step "Configuring Claude Code hooks (make claude-hooks)"
  if make -C "$DOTFILES_DIR" claude-hooks; then
    log_ok "Hooks configured"
  else
    log_warn "Hook configuration failed"
  fi
}

install_extra_tools() {
  log_step "Installing anyenv and bun"
  make -C "$DOTFILES_DIR" anyenv
  make -C "$DOTFILES_DIR" bun
}

run_doctor() {
  log_step "Checking the result (make doctor)"
  # 警告があっても失敗扱いにしない
  make -C "$DOTFILES_DIR" doctor || true
}

print_next_steps() {
  cat <<EOM

============================================
Setup complete
============================================

Remaining steps are manual.

  Docker
    cd $DOTFILES_DIR && make docker
    See docs/docker.md

  Login shell
    chsh -s "\$(command -v zsh)"
    Log out once to apply

  Git identity
    Set user.name and user.email in $DOTFILES_DIR/.gitconfig

  SSH public keys
    cd $DOTFILES_DIR && make .ssh

  The default .bashrc moved aside (remove it if you do not need it)
    $HOME/.bashrc.orig

  Pushing to the repository (currently cloned over HTTPS)
    git -C $DOTFILES_DIR remote set-url origin $REPO_SSH_URL

EOM
}

# ============================================================
# メイン
# ============================================================

main() {
  parse_args "$@"

  log_info "dotfiles bootstrap"
  check_prerequisites
  show_plan
  confirm

  authenticate_sudo
  install_packages

  clone_repository
  backup_default_bashrc
  link_dotfiles
  install_vim_plugins

  install_claude_code
  install_claude_hooks

  install_extra_tools
  run_doctor

  print_next_steps
}

# 転送が途中で切れた場合に部分実行されないよう、末尾で呼ぶ
main "$@"
