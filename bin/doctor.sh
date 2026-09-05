#!/bin/bash
#
# dotfiles の配置状態を点検する。何も変更しない。
# リンクの有無と向き先、リポジトリ外に残った古いコピー、依存コマンド、
# Claude Code のフック設定を確認する。
#
#   doctor.sh [-v]
#
# 問題が無ければ 0、警告のみなら 0、リンク切れ等があれば 1 を返す。

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# ============================================================
# 準備と共通処理
# ============================================================

VERBOSE=false
case "${1:-}" in
-v | --verbose) VERBOSE=true ;;
-h | --help)
  echo "usage: ${0##*/} [-v]"
  exit 0
  ;;
esac

source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/targets.sh"

WARN_COUNT=0
NG_COUNT=0
LINKED=0
UNLINKED=0

warn() {
  log_warn "$*"
  WARN_COUNT=$((WARN_COUNT + 1))
}

ng() {
  log_error "$*"
  NG_COUNT=$((NG_COUNT + 1))
}

# ============================================================
# 点検項目
# ============================================================

# --- リンクの点検 ---

# 配置先が dotfiles 内の想定するファイルを指しているかを見る
check_link() {
  local dest=$1 src=$2 label=$3 actual

  if [ -L "$dest" ]; then
    actual=$(readlink -f "$dest" 2>/dev/null) || actual=""

    if [ -z "$actual" ] || [ ! -e "$actual" ]; then
      ng "$label: リンク切れ ($dest -> $(readlink "$dest"))"
    elif [ "$actual" = "$src" ]; then
      log_verbose "$label: リンク済み"
      LINKED=$((LINKED + 1))
    else
      warn "$label: dotfiles 以外を指している ($dest -> $actual)"
    fi
  elif [ -e "$dest" ]; then
    warn "$label: リンクではなく実体ファイルが置かれている ($dest)"
  else
    log_verbose "$label: 未配置"
    UNLINKED=$((UNLINKED + 1))
  fi
}

check_links() {
  log_info "配置状態を確認しています..."

  local f d

  for f in "${DOTFILES_BASIC[@]}"; do
    # .bashrc は既定でシステムのものを残すため、実体ファイルでも異常ではない
    if [ "$f" = ".bashrc" ] && [ ! -L "$HOME/.bashrc" ] && [ -e "$HOME/.bashrc" ]; then
      log_verbose ".bashrc: システム既定を使用中（--force で置き換え可能）"
      continue
    fi
    check_link "$HOME/$f" "$DOTFILES_ROOT/$f" "$f"
  done

  for f in "${DOTFILES_COMMANDS[@]}"; do
    check_link "$HOME/.local/bin/$f" "$DOTFILES_ROOT/bin/$f" "bin/$f"
  done

  for f in "${DOTFILES_VIM[@]}" "${DOTFILES_X11[@]}"; do
    check_link "$HOME/$f" "$DOTFILES_ROOT/$f" "$f"
  done

  for d in "${DOTFILES_SHELL_DIRS[@]}" "${DOTFILES_GUI_DIRS[@]}" \
    "${DOTFILES_I3WM_DIRS[@]}"; do
    [ -d "$DOTFILES_ROOT/config/$d" ] || continue
    for f in "$DOTFILES_ROOT/config/$d"/*; do
      [ -e "$f" ] || continue
      check_link "$HOME/.config/$d/$(basename "$f")" "$f" "config/$d/$(basename "$f")"
    done
  done

  for f in "${DOTFILES_AGENT[@]}"; do
    check_link "$HOME/.claude/$f" "$DOTFILES_ROOT/.claude/$f" ".claude/$f"
  done

  log_ok "リンク済み $LINKED 件 / 未配置 $UNLINKED 件"
}

# --- リンク切れの走査 ---

# dotfiles を指したまま切れているリンクだけを対象にする。
# 他のツールが張ったリンクは管理外なので報告しない。
check_broken_links() {
  local found=0 link target

  while IFS= read -r link; do
    target=$(readlink "$link")

    case "$target" in
    "$DOTFILES_ROOT"/* | */dotfiles/*)
      ng "リンク切れ: $link -> $target"
      found=1
      ;;
    *)
      log_verbose "管理外の切れたリンク: $link -> $target"
      ;;
    esac
  done < <(
    find "$HOME" -maxdepth 1 -xtype l 2>/dev/null
    find "$HOME/.config" "$HOME/.local/bin" "$HOME/.claude" \
      -maxdepth 2 -xtype l 2>/dev/null
  )

  [ "$found" -eq 0 ] && log_ok "dotfiles 由来のリンク切れは無し"
}

# --- リポジトリ外に残った古いコピー ---

check_stale_copies() {
  local dir name found=0 path target

  for name in $(ls "$DOTFILES_ROOT/bin"); do
    [ -f "$DOTFILES_ROOT/bin/$name" ] || continue

    for dir in /usr/local/bin /usr/bin "$HOME/bin"; do
      path="$dir/$name"
      [ -e "$path" ] || continue

      target=$(readlink -f "$path" 2>/dev/null) || target=""
      [ "$target" = "$DOTFILES_ROOT/bin/$name" ] && continue

      if cmp -s "$path" "$DOTFILES_ROOT/bin/$name"; then
        warn "リポジトリ外にコピーがある（内容は同一）: $path"
      else
        warn "リポジトリ外に古いコピーがある: $path（$DOTFILES_ROOT/bin/$name と内容が異なる）"
      fi
      found=1
    done
  done

  [ "$found" -eq 0 ] && log_ok "リポジトリ外の重複コピーは無し"
}

# --- 依存コマンド ---

check_commands() {
  local c missing_req=0 missing_opt=""

  for c in git curl tmux zsh vim; do
    command -v "$c" >/dev/null 2>&1 || {
      ng "必須コマンドが無い: $c"
      missing_req=1
    }
  done

  # 無くても大半は動くが、特定の機能が黙って効かなくなるもの
  #   bc     .tmux.conf のバージョン判定（セッション番号の詰め直し）
  #   jq     make claude-hooks
  #   xsel   tmux とシェルのクリップボード連携
  #   feh    bin/wallpaper.sh
  #   shfmt  make fmt
  for c in bc jq xsel feh shfmt; do
    command -v "$c" >/dev/null 2>&1 || missing_opt="$missing_opt $c"
  done

  [ "$missing_req" -eq 0 ] && log_ok "必須コマンドは揃っている"
  [ -n "$missing_opt" ] && warn "任意のコマンドが無い:$missing_opt"
}

# --- Claude Code のフック ---

check_claude_hooks() {
  local settings="$HOME/.claude/settings.json" event missing=""

  if [ ! -f "$settings" ]; then
    warn "Claude Code の設定が無い: $settings"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_verbose "jq が無いためフック設定を確認できない"
    return
  fi

  if ! jq -e . "$settings" >/dev/null 2>&1; then
    ng "Claude Code の設定が JSON として壊れている: $settings"
    return
  fi

  for event in UserPromptSubmit PreToolUse PostToolUse Notification Stop SessionEnd; do
    jq -e --arg e "$event" \
      '[.hooks[$e][]?.hooks[]?.command] | any(test("tmux-claude-status"))' \
      "$settings" >/dev/null 2>&1 || missing="$missing $event"
  done

  if [ -n "$missing" ]; then
    warn "tmux のウィンドウ状態表示のフックが未設定:$missing（make claude-hooks で追加）"
  else
    log_ok "Claude Code のフックは設定済み"
  fi
}

# ============================================================
# エントリポイント
# ============================================================

log_info "dotfiles: $DOTFILES_ROOT"
echo

check_links
echo
check_broken_links
check_stale_copies
echo
check_commands
check_claude_hooks
echo

if [ "$NG_COUNT" -gt 0 ]; then
  log_error "問題 $NG_COUNT 件、警告 $WARN_COUNT 件"
  exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
  log_warn "警告 $WARN_COUNT 件"
else
  log_ok "問題なし"
fi
