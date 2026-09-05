#!/bin/bash
#
# 導入済みのプラグイン・ツールをまとめて更新する。
# 対象は zsh プラグイン、Vim プラグイン、anyenv、bun。
# 導入されていないものは飛ばす。dotfiles 自体は更新しない。
#
#   update.sh [-n]

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ============================================================
# 準備と共通処理
# ============================================================

DRY_RUN=false
case "${1:-}" in
-n | --dry-run) DRY_RUN=true ;;
-h | --help)
  echo "usage: ${0##*/} [-n|--dry-run]"
  exit 0
  ;;
'') ;;
*)
  echo "Unknown option: $1" >&2
  exit 1
  ;;
esac

source "$SCRIPT_DIR/lib/log.sh"

FAILED=0

# ============================================================
# 更新項目
# ============================================================

# --- zsh プラグイン ---

# ~/.zsh 配下の git リポジトリを対象にする。手で入れたものも拾えるよう、
# install-zsh-plugins.sh の一覧ではなく実際の配置を見る。
update_zsh_plugins() {
  local dir name out found=0

  for dir in "$HOME"/.zsh/*/; do
    [ -d "$dir.git" ] || continue

    name=$(basename "$dir")
    found=1

    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] git -C $dir pull --ff-only"
      continue
    fi

    if out=$(git -C "$dir" pull --ff-only 2>&1); then
      case "$out" in
      *"Already up to date"* | *"最新です"*) log_skip "$name: 更新なし" ;;
      *) log_ok "$name: 更新済み" ;;
      esac
    else
      log_warn "$name: 更新に失敗"
      echo "$out" | sed 's/^/    /'
      FAILED=$((FAILED + 1))
    fi
  done

  [ "$found" -eq 0 ] && log_skip "zsh プラグイン: 未導入"
  return 0
}

# --- Vim プラグイン ---

update_vim_plugins() {
  if ! command -v vim >/dev/null 2>&1; then
    log_skip "Vim: 未導入"
    return 0
  fi

  if [ ! -d "$HOME/.vim/plugged" ]; then
    log_skip "Vim プラグイン: 未導入（vim を起動すると入る）"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] vim +PlugUpgrade +PlugUpdate +qall"
    return 0
  fi

  # PlugUpgrade は vim-plug 自体、PlugUpdate は各プラグインを更新する。
  # --sync を付けないと更新の完了前に qall へ進んでしまう。
  if vim -Nu "$HOME/.vimrc" -c 'PlugUpgrade' -c 'PlugUpdate --sync' -c 'qall!' \
    </dev/null >/dev/null 2>&1; then
    log_ok "Vim プラグイン: 更新済み"
  else
    log_warn "Vim プラグイン: 更新に失敗"
    FAILED=$((FAILED + 1))
  fi
}

# --- anyenv ---

update_anyenv() {
  local anyenv="$HOME/.anyenv/bin/anyenv"

  if [ ! -x "$anyenv" ]; then
    log_skip "anyenv: 未導入"
    return 0
  fi

  if [ ! -d "$HOME/.anyenv/plugins/anyenv-update" ]; then
    log_warn "anyenv-update プラグインが無いため更新できない（make anyenv で導入）"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] anyenv update"
    return 0
  fi

  if "$anyenv" update; then
    log_ok "anyenv: 更新済み"
  else
    log_warn "anyenv: 更新に失敗"
    FAILED=$((FAILED + 1))
  fi
}

# --- bun ---

update_bun() {
  local bun="$HOME/.bun/bin/bun"

  if [ ! -x "$bun" ]; then
    log_skip "bun: 未導入"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] bun upgrade"
    return 0
  fi

  if "$bun" upgrade; then
    log_ok "bun: 更新済み"
  else
    log_warn "bun: 更新に失敗"
    FAILED=$((FAILED + 1))
  fi
}

# ============================================================
# エントリポイント
# ============================================================

log_info "zsh プラグイン"
update_zsh_plugins
echo

log_info "Vim プラグイン"
update_vim_plugins
echo

log_info "anyenv"
update_anyenv
echo

log_info "bun"
update_bun
echo

if [ "$FAILED" -gt 0 ]; then
  log_error "$FAILED 件が失敗しました"
  exit 1
fi

log_ok "更新完了"
