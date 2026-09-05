#!/bin/bash
# ============================================================
# tmux-claude-status.sh
# ============================================================
#
# 概要:
#   Claude Code の状態を、tmuxのウィンドウステータスの背景色で可視化する
#
# 用途:
#   複数ウィンドウでClaude Codeを動かしていると、非アクティブなウィンドウで
#   タスクが完了したり承認待ちになったりしても気づけない
#   このスクリプトをClaude Codeのフックから呼ぶことで、該当ウィンドウの
#   ステータス背景色が変わり、他のウィンドウで作業していても状態がわかる
#
# 機能:
#   - running（実行中）/ waiting（承認・入力待ち）/ done（完了）を色分け
#   - tmuxの window-status-style はウィンドウが非アクティブなときのみ有効な
#     ため、アクティブなウィンドウは着色されない（追加の判定が不要）
#   - ウィンドウを離れる/選択したタイミングで waiting・done を既読にする
#     （running は維持されるため、実行中のウィンドウは色が残る）
#   - 状態ファイルにClaude CodeのPIDを記録し、プロセスが消えていれば解除する
#     （強制終了・SSH切断などで SessionEnd が発火しない場合の保険）
#   - グローバルオプションは変更せず、対象ウィンドウのオプションのみ操作する
#     ため、Claude Codeが動いていないウィンドウには影響しない
#
# 依存関係:
#   - bash
#   - tmux
#   - procfs（/proc）
#
# 使用例:
#   # Claude Code のフックから（~/.claude/settings.json）
#   $ tmux-claude-status.sh running   # UserPromptSubmit
#   $ tmux-claude-status.sh waiting   # Notification
#   $ tmux-claude-status.sh done      # Stop
#   $ tmux-claude-status.sh none      # SessionEnd
#
#   # tmux のフックから（~/.tmux.conf）
#   $ tmux-claude-status.sh --ack '@3'   # ウィンドウ@3の waiting/done を既読化
#
# 注意事項:
#   - tmux外・tmux不在の環境では何もせず正常終了する
#   - 状態ファイルは $XDG_RUNTIME_DIR 配下に置くため、再起動で消える
#
# ============================================================

set -u

# ---- 設定 ------------------------------------------------

# 状態ごとのウィンドウステータスのスタイル
STYLE_RUNNING="bg=colour24,fg=colour255"
STYLE_WAITING="bg=colour136,fg=colour232"
STYLE_DONE="bg=colour22,fg=colour255"

# 状態ファイルの置き場所（tmpfs、再起動で消える）
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	STATE_DIR="$XDG_RUNTIME_DIR/tmux-claude-status"
else
	STATE_DIR="/tmp/tmux-claude-status-$(id -u)"
fi

# ---- 事前チェック ----------------------------------------

# tmuxの外、またはtmuxが無い環境では何もしない
[ -n "${TMUX:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# $TMUX は "ソケットパス,サーバPID,セッションID" 形式
# ペインIDはtmuxサーバ内でのみ一意なため、サーバPIDを状態ファイル名に含めて
# 複数のtmuxサーバ（tmux -L）を併用しても衝突しないようにする
SERVER=${TMUX#*,}
SERVER=${SERVER%%,*}
[ -n "$SERVER" ] || SERVER=0

# ---- 共通処理 --------------------------------------------

# 状態の優先度を返す（大きいほど強い）
# 承認待ちが最優先、次に完了、最後に実行中
priority() {
	case "$1" in
	waiting) echo 3 ;;
	"done") echo 2 ;;
	running) echo 1 ;;
	*) echo 0 ;;
	esac
}

# ペインIDから状態ファイルのパスを組み立てる（%3 -> $STATE_DIR/1766-3）
state_file() {
	echo "$STATE_DIR/$SERVER-${1#%}"
}

# 自身の祖先を辿ってClaude CodeのPIDを探す
# フックはClaude Codeの子プロセスとして起動されるため、数段辿れば見つかる
# プロセス名の完全一致で判定する（cmdlineの部分一致だと、~/.claude/ 配下の
# パスを引数に持つ無関係な一時プロセスを誤検出してしまうため）
find_claude_pid() {
	local pid=$PPID depth=0 stat comm argv0

	while [ "${pid:-0}" -gt 1 ] && [ "$depth" -lt 12 ]; do
		comm=$(cat "/proc/$pid/comm" 2>/dev/null)
		argv0=$(tr '\0' '\n' <"/proc/$pid/cmdline" 2>/dev/null | head -n 1)

		if [ "$comm" = "claude" ] || [ "${argv0##*/}" = "claude" ]; then
			echo "$pid"
			return 0
		fi

		# /proc/<pid>/stat の第4フィールドが親PID
		# コマンド名に空白を含む場合があるため、最後の ')' 以降を見る
		stat=$(cat "/proc/$pid/stat" 2>/dev/null) || return 1
		pid=$(echo "${stat##*) }" | awk '{print $2}')
		depth=$((depth + 1))
	done

	return 1
}

# 状態ファイルを読み、記録されたPIDが生きていれば状態名を返す
# プロセスが消えていればファイルを削除して none を返す
read_state() {
	local file state pid

	file=$(state_file "$1")
	[ -f "$file" ] || {
		echo none
		return
	}

	IFS=$'\t' read -r state pid _ <"$file" || {
		echo none
		return
	}

	# PIDが取れなかった記録（"-"）は生存確認をスキップする
	case "${pid:-}" in
	'' | *[!0-9]*) pid="" ;;
	esac

	if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
		rm -f "$file"
		echo none
		return
	fi

	echo "${state:-none}"
}

# ウィンドウ内の全ペインの状態から、最も強いものを選んで着色する
repaint_window() {
	local win=$1 best=none pane state

	while read -r pane; do
		[ -n "$pane" ] || continue
		state=$(read_state "$pane")
		if [ "$(priority "$state")" -gt "$(priority "$best")" ]; then
			best=$state
		fi
	done < <(tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null)

	case "$best" in
	waiting) apply_style "$win" "$STYLE_WAITING" ;;
	"done") apply_style "$win" "$STYLE_DONE" ;;
	running) apply_style "$win" "$STYLE_RUNNING" ;;
	*) apply_style "$win" "" ;;
	esac
}

# ウィンドウにスタイルを設定する（空文字なら解除）
# monitor-activity が有効だと、出力のあったウィンドウに
# window-status-activity-style（既定は reverse）が重ねて適用され、
# 背景色が反転してしまう。Claude Codeのウィンドウは常に出力があるため、
# activity側にも同じスタイルを設定して反転を打ち消す
apply_style() {
	local win=$1 style=$2 opt

	for opt in window-status-style window-status-activity-style; do
		if [ -n "$style" ]; then
			tmux set-window-option -t "$win" "$opt" "$style" 2>/dev/null
		else
			# グローバル設定（.tmux.conf の setw -g ...）に戻す
			tmux set-window-option -u -t "$win" "$opt" 2>/dev/null
		fi
	done
}

# Claude Codeが消えた状態ファイルを掃除し、対象ウィンドウを塗り直す
# 他のウィンドウで強制終了された場合も、次にこのスクリプトが動いた時点で消える
prune_dead() {
	local file pid win

	for file in "$STATE_DIR/$SERVER-"*; do
		[ -f "$file" ] || continue

		IFS=$'\t' read -r _ pid win <"$file" || continue
		case "${pid:-}" in
		'' | *[!0-9]*) continue ;;
		esac
		kill -0 "$pid" 2>/dev/null && continue

		rm -f "$file"
		[ -n "${win:-}" ] && repaint_window "$win"
	done
}

# ---- サブコマンド ----------------------------------------

# ウィンドウ内の waiting・done を既読にする（running は維持）
# ユーザがそのウィンドウを見た＝状態を把握したとみなす
ack_window() {
	local win=$1 pane state

	while read -r pane; do
		[ -n "$pane" ] || continue
		state=$(read_state "$pane")
		case "$state" in
		waiting | "done") rm -f "$(state_file "$pane")" ;;
		esac
	done < <(tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null)

	repaint_window "$win"
}

# 現在のペインの状態を更新し、所属ウィンドウを塗り直す
set_state() {
	local state=$1 win file pid

	# フックはClaude Codeのプロセスから起動されるので TMUX_PANE を引き継いでいる
	[ -n "${TMUX_PANE:-}" ] || return 0

	win=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null) || return 0
	[ -n "$win" ] || return 0

	file=$(state_file "$TMUX_PANE")

	if [ "$state" = "none" ]; then
		rm -f "$file"
	else
		# PIDが特定できない場合もプレースホルダを置く
		# タブは空白類なので、空フィールドがあると列が詰まってずれてしまう
		pid=$(find_claude_pid) || pid=""
		[ -n "$pid" ] || pid="-"
		printf '%s\t%s\t%s\n' "$state" "$pid" "$win" >"$file"
	fi

	repaint_window "$win"
}

# ---- エントリポイント ------------------------------------

case "${1:-}" in
--ack)
	[ -n "${2:-}" ] || exit 0
	prune_dead
	ack_window "$2"
	;;
running | waiting | done | none)
	prune_dead
	set_state "$1"
	;;
*)
	echo "usage: ${0##*/} {running|waiting|done|none|--ack <window-id>}" >&2
	exit 1
	;;
esac

# フックを絶対にブロックしない
exit 0
