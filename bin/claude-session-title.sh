#!/bin/sh
#
# Claude Code のセッション名を、本体が生成した ai-title から自動で付ける。
# UserPromptSubmit フックから呼ばれ、標準出力の JSON で名前を渡す。
#
#   claude-session-title.sh   < フックの入力(JSON)
#
# ai-title は1往復目のあとに作られるため、名前が付くのは2通目の送信時から。
# ブランチ名が <種別>/<番号>-<説明> の形なら、番号を "#123" として前に置く。
#
# 設定方法は docs/tmux-claude-status.md を参照。
# jq が無い環境・ai-title がまだ無い時点では何もせず正常終了する。

set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

# --- Input fields ---
# プロンプトのたびに走るので jq の起動は1回にまとめる。
# 区切りは値に現れない US(\037)
US=$(printf '\037')
IFS="$US" read -r transcript cwd <<EOF
$(printf '%s' "$input" | jq -j '[
  (.transcript_path // ""),
  (.cwd // "")
] | join("")')
EOF

[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# --- AI title ---
# transcript は MB 級まで育つため、全体を jq に通さず末尾から1行だけ取る
line=$(tac "$transcript" 2>/dev/null | grep -m1 '"type":"ai-title"') || exit 0
[ -n "$line" ] || exit 0

title=$(printf '%s' "$line" | jq -r '.aiTitle // empty')
[ -n "$title" ] || exit 0

# --- Issue number ---
# fix/123-concurrent-fetch のようなブランチから 123 を取る。
# 番号を持たないブランチ（main、feat/profiles など）では前置しない
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) || branch=""
  number=$(printf '%s' "$branch" | sed -n 's#.*/\([0-9][0-9]*\)-.*#\1#p')
  [ -n "$number" ] && title="#$number $title"
fi

# --- Output ---
# 同じ名前を繰り返し渡しても本体が無視するため、付け直しの判定は持たない
jq -n --arg t "$title" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
