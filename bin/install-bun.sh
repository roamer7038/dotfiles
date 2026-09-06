#!/bin/bash
#
# bun（JavaScript ランタイム兼ツールキット）を導入する。
# anyenv の管理外なので個別に入れる。~/.bun があれば何もしない。

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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

log_info "Installing bun..."

if [ -d "$HOME/.bun" ]; then
  log_skip "bun: already installed (~/.bun)"
  if command -v bun >/dev/null 2>&1; then
    log_info "Version: $(bun --version)"
  fi
  log_info "Update it with: bun upgrade"
  exit 0
fi

# --- .zshrc の保護 ---

# 公式インストーラは ~/.zshrc へ completions の読み込みを追記する。
# dotfiles の .zshrc は同じ読み込みを既に持っており、~/.zshrc はリポジトリへの
# リンクなので、そのままだとリポジトリが汚れる。導入前に差分が無ければ後で戻す。
RESTORE_ZSHRC=false
if [ "$(readlink -f "$HOME/.zshrc" 2>/dev/null)" = "$DOTFILES_ROOT/.zshrc" ] &&
  git -C "$DOTFILES_ROOT" diff --quiet -- .zshrc 2>/dev/null; then
  RESTORE_ZSHRC=true
fi

log_info "Running the official install script..."
curl -fsSL https://bun.sh/install | bash

log_ok "bun installed"

# --- .zshrc を元に戻す ---

if [ "$RESTORE_ZSHRC" = true ] && ! git -C "$DOTFILES_ROOT" diff --quiet -- .zshrc; then
  git -C "$DOTFILES_ROOT" checkout -- .zshrc
  log_ok "Reverted the lines appended to .zshrc"
fi

log_ok "bun installation complete"
echo
echo "The PATH entry is already in .zshrc. Reload the shell to use it:"
echo "  exec \$SHELL -l"
echo "  bun --version"
