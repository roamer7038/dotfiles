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

source "$SCRIPT_DIR/lib/log.sh"

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
  log_error "jq が必要です: apt install jq"
  exit 1
}

# ホーム配下にあるなら $HOME 起点で書き、別マシンでも同じ設定が使えるようにする
case "$DOTFILES_ROOT" in
"$HOME"/*) SCRIPT_REF="\"\$HOME/${DOTFILES_ROOT#"$HOME"/}/bin/tmux-claude-status.sh\"" ;;
*) SCRIPT_REF="\"$DOTFILES_ROOT/bin/tmux-claude-status.sh\"" ;;
esac

# イベント名と、渡す状態の対応
EVENTS=(
  "UserPromptSubmit:running"
  "Notification:waiting"
  "Stop:done"
  "SessionEnd:none"
)

mkdir -p "$(dirname "$SETTINGS")"

if [ -f "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || {
    log_error "JSON として読めません: $SETTINGS"
    exit 1
  }
else
  log_info "新規作成します: $SETTINGS"
  [ "$DRY_RUN" = true ] || echo '{}' >"$SETTINGS"
fi

current=$([ -f "$SETTINGS" ] && cat "$SETTINGS" || echo '{}')
updated=$current
added=0

for entry in "${EVENTS[@]}"; do
  event=${entry%%:*}
  state=${entry##*:}
  cmd="$SCRIPT_REF $state"

  if echo "$updated" | jq -e --arg e "$event" \
    '[.hooks[$e][]?.hooks[]?.command] | any(test("tmux-claude-status"))' \
    >/dev/null 2>&1; then
    log_skip "$event: 設定済み"
    continue
  fi

  updated=$(echo "$updated" | jq --arg e "$event" --arg c "$cmd" '
    .hooks //= {}
    | .hooks[$e] //= []
    | .hooks[$e] += [{ hooks: [{ type: "command", command: $c, timeout: 5 }] }]
  ')
  log_ok "$event: 追加"
  added=$((added + 1))
done

if [ "$added" -eq 0 ]; then
  log_info "変更はありません"
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] 追加後の hooks:"
  echo "$updated" | jq '.hooks'
  exit 0
fi

cp "$SETTINGS" "$SETTINGS.bak"
echo "$updated" | jq . >"$SETTINGS.tmp"
mv "$SETTINGS.tmp" "$SETTINGS"

log_ok "$added 件のフックを追加しました（変更前: $SETTINGS.bak）"
