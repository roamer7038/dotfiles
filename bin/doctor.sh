#!/bin/bash
#
# dotfiles の配置状態を点検する。何も変更しない。
# 配置対象は links（パス・配置先・タグの3列）に定義されている。
# リンクの有無と向き先、リポジトリ外に残った古いコピー、依存コマンド、
# Claude Code のフック設定を確認する。
#
#   doctor.sh [-v]
#
# 問題が無ければ 0、警告のみなら 0、リンク切れ等があれば 1 を返す。

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
LINKS_FILE="$DOTFILES_ROOT/links"

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

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

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
      ng "$label: broken link ($dest -> $(readlink "$dest"))"
    elif [ "$actual" = "$src" ]; then
      log_verbose "$label: linked"
      LINKED=$((LINKED + 1))
    else
      warn "$label: points outside dotfiles ($dest -> $actual)"
    fi
  elif [ -e "$dest" ]; then
    warn "$label: regular file, not a symlink ($dest)"
  else
    log_verbose "$label: not linked"
    UNLINKED=$((UNLINKED + 1))
  fi
}

check_links() {
  log_info "Checking links..."

  if [ ! -r "$LINKS_FILE" ]; then
    ng "Cannot read link definitions: $LINKS_FILE"
    return
  fi

  local src dest tag file name

  while read -r src dest tag; do
    case "$src" in '' | '#'*) continue ;; esac
    dest="$HOME/${dest#\~/}"

    case "$src" in
    */)
      for file in "$DOTFILES_ROOT/$src"*; do
        [ -e "$file" ] || continue
        name=$(basename "$file")
        check_link "${dest%/}/$name" "$file" "$src$name"
      done
      ;;
    *)
      check_link "$dest" "$DOTFILES_ROOT/$src" "$src"
      ;;
    esac
  done <"$LINKS_FILE"

  log_ok "$LINKED linked, $UNLINKED not linked"
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
      ng "Broken link: $link -> $target"
      found=1
      ;;
    *)
      log_verbose "Broken link outside dotfiles: $link -> $target"
      ;;
    esac
  done < <(
    find "$HOME" -maxdepth 1 -xtype l 2>/dev/null
    find "$HOME/.config" "$HOME/.local/bin" "$HOME/.claude" \
      -maxdepth 2 -xtype l 2>/dev/null
  )

  [ "$found" -eq 0 ] && log_ok "No broken dotfiles links"
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
        warn "Copy outside the repository (identical): $path"
      else
        warn "Stale copy outside the repository: $path (differs from $DOTFILES_ROOT/bin/$name)"
      fi
      found=1
    done
  done

  [ "$found" -eq 0 ] && log_ok "No duplicate copies outside the repository"
}

# --- 依存コマンド ---

check_commands() {
  local c missing_req=0 missing_opt=""

  for c in git curl tmux zsh vim; do
    command -v "$c" >/dev/null 2>&1 || {
      ng "Required command not found: $c"
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

  [ "$missing_req" -eq 0 ] && log_ok "All required commands found"
  [ -n "$missing_opt" ] && warn "Optional commands not found:$missing_opt"
}

# --- Claude Code のフック ---

check_claude_hooks() {
  local settings="$HOME/.claude/settings.json" event missing=""

  if [ ! -f "$settings" ]; then
    warn "Claude Code settings not found: $settings"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_verbose "jq not found: cannot check hook settings"
    return
  fi

  if ! jq -e . "$settings" >/dev/null 2>&1; then
    ng "Claude Code settings are not valid JSON: $settings"
    return
  fi

  for event in UserPromptSubmit PreToolUse PostToolUse Notification Stop SessionEnd; do
    jq -e --arg e "$event" \
      '[.hooks[$e][]?.hooks[]?.command] | any(test("tmux-claude-status"))' \
      "$settings" >/dev/null 2>&1 || missing="$missing $event"
  done

  if [ -n "$missing" ]; then
    warn "tmux window status hooks not configured:$missing (run 'make claude-hooks')"
  else
    log_ok "Claude Code hooks configured"
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
  log_error "$NG_COUNT problem(s), $WARN_COUNT warning(s)"
  exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
  log_warn "$WARN_COUNT warning(s)"
else
  log_ok "No problems found"
fi
