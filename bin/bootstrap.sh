#!/bin/bash
#
# dotfiles をワンライナーで導入する。Ubuntu 24.04 以降が対象。
#
#   curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash
#
# リポジトリが無い状態で curl から実行されるため bin/lib/ には依存しない。
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

FORCE=false

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
  -f, --force    Skip the OS check and run anyway
  -h, --help     Show this message

EXAMPLE:
  curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash
  curl -fsSL https://raw.githubusercontent.com/roamer7038/dotfiles/main/bin/bootstrap.sh | bash -s -- --force

Docker is not installed by this script. See docs/docker.md after the setup.
EOM
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -f | --force) FORCE=true ;;
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
    log_error "root では実行しない（設定は一般ユーザのホームへ配置する）"
    exit 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo が無い。パッケージの導入に必要"
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
    log_ok "対象の OS: $pretty"
    return
  fi

  if [ "$FORCE" = true ]; then
    log_warn "想定外の OS だが --force のため続行する: ${pretty:-unknown}"
    return
  fi

  log_error "Ubuntu $MIN_UBUNTU_VERSION 以降が対象: ${pretty:-unknown}"
  log_error "それでも実行するなら --force を付ける"
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

これから次の処理を行う。

  1. apt でパッケージを導入   ${APT_PACKAGES[*]}
  2. 既定シェルを zsh に変更
  3. $DOTFILES_DIR へ clone
  4. 既定の ~/.bashrc を退避し make standard で設定を配置
  5. Vim プラグインを導入
  6. Claude Code と tmux 連携フックを導入
  7. anyenv と bun を導入
  8. make doctor で点検

Docker は導入しない（最後に手順を案内する）。
sudo のパスワードを一度だけ尋ねる。

EOM
}

authenticate_sudo() {
  log_step "sudo の認証"
  if sudo -n true 2>/dev/null; then
    log_ok "sudo は認証済み"
    return
  fi
  sudo -v
  log_ok "sudo を認証した"
}

install_packages() {
  log_step "apt パッケージの導入"
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
  log_ok "パッケージを導入した"
}

# apt の直後に行う。間隔が空くと sudo の認証が切れる
change_login_shell() {
  log_step "既定シェルの変更"

  local zsh_path current
  zsh_path=$(command -v zsh || true)
  if [ -z "$zsh_path" ]; then
    log_warn "zsh が見つからないため既定シェルを変更しない"
    return
  fi

  current=$(getent passwd "$(id -un)" | cut -d: -f7)
  if [ "$current" = "$zsh_path" ]; then
    log_skip "既定シェルは既に $zsh_path"
    return
  fi

  if sudo chsh -s "$zsh_path" "$(id -un)"; then
    log_ok "既定シェルを $zsh_path に変更した（反映は再ログイン後）"
  else
    log_warn "既定シェルを変更できなかった: chsh -s $zsh_path"
  fi
}

clone_repository() {
  log_step "リポジトリの取得"

  if [ ! -e "$DOTFILES_DIR" ]; then
    git clone "$REPO_URL" "$DOTFILES_DIR"
    log_ok "clone した: $DOTFILES_DIR"
    return
  fi

  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    log_error "$DOTFILES_DIR が git リポジトリではない。移動または削除してからやり直す"
    exit 1
  fi

  if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
    log_skip "$DOTFILES_DIR に未コミットの変更があるため更新しない"
    return
  fi

  if git -C "$DOTFILES_DIR" pull --ff-only; then
    log_ok "更新した: $DOTFILES_DIR"
  else
    log_warn "更新できなかったため既存の内容のまま進める"
  fi
}

# Ubuntu は新規ユーザへ /etc/skel/.bashrc を必ずコピーするため、
# create-symlinks.sh が既存ファイルとして常に飛ばしてしまう。
# 退避しておき、dotfiles の .bashrc が配置されるようにする。
backup_default_bashrc() {
  log_step "既定の .bashrc の退避"

  local rc="$HOME/.bashrc" backup="$HOME/.bashrc.orig"

  if [ ! -e "$rc" ] || [ -L "$rc" ]; then
    log_skip "退避するファイルは無い"
    return
  fi

  if [ -e "$backup" ]; then
    log_skip "$backup が既にあるため退避しない"
    return
  fi

  mv "$rc" "$backup"
  log_ok "$rc を $backup へ退避した"
}

# standard は agent（~/.claude）を含むので make agent は呼ばない
link_dotfiles() {
  log_step "設定ファイルの配置（make standard）"
  make -C "$DOTFILES_DIR" standard
  log_ok "設定を配置した"
}

# .vimrc は初回起動時に vim-plug とプラグインを同期導入する。
# それをヘッドレスで済ませ、初回の対話起動を待たせない。
install_vim_plugins() {
  log_step "Vim プラグインの導入"

  if ! command -v vim >/dev/null 2>&1; then
    log_warn "vim が無いため飛ばす"
    return
  fi

  if vim --not-a-term -c 'qall!' </dev/null >/dev/null 2>&1; then
    log_ok "Vim プラグインを導入した"
  else
    log_warn "Vim プラグインの導入に失敗した。vim を起動して手動で :PlugInstall する"
  fi
}

install_claude_code() {
  log_step "Claude Code の導入"

  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    log_skip "Claude Code は導入済み"
    return
  fi

  if curl -fsSL "$CLAUDE_INSTALL_URL" | bash; then
    log_ok "Claude Code を導入した"
  else
    log_warn "Claude Code の導入に失敗した: curl -fsSL $CLAUDE_INSTALL_URL | bash"
  fi
}

install_claude_hooks() {
  log_step "Claude Code のフック設定（make claude-hooks）"
  if make -C "$DOTFILES_DIR" claude-hooks; then
    log_ok "フックを設定した"
  else
    log_warn "フックを設定できなかった"
  fi
}

install_extra_tools() {
  log_step "anyenv と bun の導入"
  make -C "$DOTFILES_DIR" anyenv
  make -C "$DOTFILES_DIR" bun
}

run_doctor() {
  log_step "配置状態の点検（make doctor）"
  # 警告があっても失敗扱いにしない
  make -C "$DOTFILES_DIR" doctor || true
}

print_next_steps() {
  cat <<EOM

============================================
セットアップが完了した
============================================

残りは手動で行う。

  Docker（システムへの影響が大きいため自動化しない）
    cd $DOTFILES_DIR && make docker
    詳細は docs/docker.md

  Git のユーザ情報
    $DOTFILES_DIR/.gitconfig の user.name と user.email を書き換える

  SSH 公開鍵の登録
    cd $DOTFILES_DIR && make .ssh

  退避した既定の .bashrc（不要なら消してよい）
    $HOME/.bashrc.orig

  リポジトリへ push する場合（現在は HTTPS）
    git -C $DOTFILES_DIR remote set-url origin $REPO_SSH_URL

既定シェルの変更を反映するには一度ログアウトする。
今すぐ試すだけなら次を実行する。

  exec zsh -l

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

  authenticate_sudo
  install_packages
  change_login_shell

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
