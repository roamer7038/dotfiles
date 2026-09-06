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

log_info "Installing bun..."

if [ -d "$HOME/.bun" ]; then
  log_skip "bun: already installed (~/.bun)"
  if command -v bun >/dev/null 2>&1; then
    log_info "Version: $(bun --version)"
  fi
  log_info "Update it with: bun upgrade"
  exit 0
fi

log_info "Running the official install script..."

# 公式インストーラは PATH 上に bun が無いときだけ、シェルの設定ファイルへ
# PATH と補完の読み込みを追記する。~/.bashrc と ~/.zshrc はリポジトリへの
# リンクなので、追記されるとリポジトリが汚れる。展開先を先に PATH へ通し、
# 追記の分岐へ入らせない。
export PATH="$HOME/.bun/bin:$PATH"
curl -fsSL https://bun.sh/install | bash

log_ok "bun installation complete"
echo
echo "PATH is set by ~/.config/profile.d/00-common.sh. Reload the shell to use it:"
echo "  exec \$SHELL -l"
echo "  bun --version"
