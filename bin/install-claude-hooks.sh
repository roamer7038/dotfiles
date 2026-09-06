#!/bin/bash
#
# tmux のウィンドウ状態表示に必要なフックを ~/.claude/settings.json へ追加する。
# 既存の設定は保持し、同じフックが既にあれば何もしない（何度実行してもよい）。
#
#   install-claude-hooks.sh [-n]
#
# settings.json は環境ごとに内容が異なるため dotfiles の管理対象外。
# 詳細は docs/tmux-claude-status.md を参照。

set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

SETTINGS="$HOME/.claude/settings.json"
DRY_RUN=false

case "${1:-}" in
-n | --dry-run) DRY_RUN=true ;;
-h | --help)
  echo "usage: ${0##*/} [-n|--dry-run]"
  exit 0
  ;;
'') ;;
*)
  log_error "Unknown option: $1"
  exit 1
  ;;
esac

command -v jq >/dev/null 2>&1 || {
  log_error "jq is required: apt install jq"
  exit 1
}

# ホーム配下にあるなら $HOME 起点で書き、別マシンでも同じ設定が使えるようにする
case "$DOTFILES_ROOT" in
"$HOME"/*) SCRIPT_REF="\"\$HOME/${DOTFILES_ROOT#"$HOME"/}/bin/tmux-claude-status.sh\"" ;;
*) SCRIPT_REF="\"$DOTFILES_ROOT/bin/tmux-claude-status.sh\"" ;;
esac

# イベント名・渡す状態・matcher（空なら全件）の対応
# Notification は種類を絞る。matcher を付けないとアイドル通知（idle_prompt、
# 入力せず放置すると届く）まで拾ってしまい、完了の表示が承認待ちに化ける
# PreToolUse・PostToolUse は絞らない。ツールを1つでも呼んでいれば本体が
# 動いている証拠なので、種類で区別する理由がない
NOTIFY_MATCHER="permission_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input"
EVENTS=(
  "UserPromptSubmit:running:"
  "PreToolUse:running:"
  "PostToolUse:running:"
  "Notification:waiting:$NOTIFY_MATCHER"
  "Stop:done:"
  "SessionEnd:none:"
)

mkdir -p "$(dirname "$SETTINGS")"

if [ -f "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || {
    log_error "Not valid JSON: $SETTINGS"
    exit 1
  }
else
  log_info "Creating: $SETTINGS"
  [ "$DRY_RUN" = true ] || echo '{}' >"$SETTINGS"
fi

current=$([ -f "$SETTINGS" ] && cat "$SETTINGS" || echo '{}')
updated=$current
changed=0

for entry in "${EVENTS[@]}"; do
  event=${entry%%:*}
  rest=${entry#*:}
  state=${rest%%:*}
  matcher=${rest#*:}
  cmd="$SCRIPT_REF $state"

  if echo "$updated" | jq -e --arg e "$event" \
    '[.hooks[$e][]?.hooks[]?.command] | any(test("tmux-claude-status"))' \
    >/dev/null 2>&1; then
    # 既にある場合も matcher だけは求める値に揃える
    # （matcher を後から足したとき、既存環境が取り残されないように）
    fixed=$(echo "$updated" | jq --arg e "$event" --arg m "$matcher" '
      .hooks[$e] |= map(
        if ([.hooks[]?.command] | any(test("tmux-claude-status")))
        then (if $m == "" then del(.matcher) else { matcher: $m } + del(.matcher) end)
        else . end
      )
    ')

    if [ "$(echo "$fixed" | jq -S .)" = "$(echo "$updated" | jq -S .)" ]; then
      log_skip "$event: already configured"
    else
      updated=$fixed
      log_ok "$event: matcher updated"
      changed=$((changed + 1))
    fi
    continue
  fi

  updated=$(echo "$updated" | jq --arg e "$event" --arg c "$cmd" --arg m "$matcher" '
    .hooks //= {}
    | .hooks[$e] //= []
    | .hooks[$e] += [
        ({ hooks: [{ type: "command", command: $c, timeout: 5 }] })
        | if $m == "" then . else { matcher: $m } + . end
      ]
  ')
  log_ok "$event: added"
  changed=$((changed + 1))
done

if [ "$changed" -eq 0 ]; then
  log_info "No changes"
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] resulting hooks:"
  echo "$updated" | jq '.hooks'
  exit 0
fi

cp "$SETTINGS" "$SETTINGS.bak"
echo "$updated" | jq . >"$SETTINGS.tmp"
mv "$SETTINGS.tmp" "$SETTINGS"

log_ok "$changed hook(s) updated (previous settings: $SETTINGS.bak)"
