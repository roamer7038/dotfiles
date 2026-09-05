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
#   - 実行中のウィンドウにはスピナーを表示する
#     動かすのに毎秒の再描画が要るため、実行中がある間だけ
#     status-interval を1に上げ、無くなったら元の値へ戻す
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
#   # window-status-format の #() から（スクリプトが自動で設定する）
#   $ tmux-claude-status.sh --spinner    # 現在時刻に応じたスピナーの1文字
#
# 注意事項:
#   - tmux外・tmux不在の環境では何もせず正常終了する
#   - 状態ファイルは $XDG_RUNTIME_DIR 配下に置くため、再起動で消える
#   - スピナーが不要なら冒頭の SPINNER を off にする
#     （status-interval も変更されなくなる）
#
# ============================================================

set -u

# ---- スピナー --------------------------------------------

# window-status-format の #() から毎秒呼ばれる
# tmuxの検査やディレクトリ作成より前に返し、余計な処理をさせない
# 現在時刻からフレームを選ぶので、状態も常駐プロセスも持たない
if [ "${1:-}" = "--spinner" ]; then
	set -- '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧'
	printf -v _now '%(%s)T' -1 2>/dev/null || _now=$(date +%s)
	eval printf '%s' "\${$((_now % $# + 1))}"
	exit 0
fi

# ---- 設定 ------------------------------------------------

# 状態ごとのウィンドウステータスのスタイル
STYLE_RUNNING="bg=colour24,fg=colour255"
STYLE_WAITING="bg=colour136,fg=colour232"
STYLE_DONE="bg=colour22,fg=colour255"

# 実行中のウィンドウにスピナーを表示するか（off で無効）
# 有効な間だけ status-interval を1に上げるため、再描画の頻度が上がる
SPINNER=on

# #() から自分自身を呼ぶために絶対パスを持っておく
SELF=$(readlink -f "$0" 2>/dev/null) || SELF=$0

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

	apply_window "$win" "$best"
}

# ウィンドウに状態に応じた色と書式を設定する（none なら解除）
# monitor-activity が有効だと、出力のあったウィンドウに
# window-status-activity-style（既定は reverse）が重ねて適用され、
# 背景色が反転してしまう。Claude Codeのウィンドウは常に出力があるため、
# activity側にも同じスタイルを設定して反転を打ち消す
apply_window() {
	local win=$1 state=$2 style="" opt base

	case "$state" in
	waiting) style=$STYLE_WAITING ;;
	"done") style=$STYLE_DONE ;;
	running) style=$STYLE_RUNNING ;;
	esac

	for opt in window-status-style window-status-activity-style; do
		if [ -n "$style" ]; then
			tmux set-window-option -t "$win" "$opt" "$style" 2>/dev/null
		else
			# グローバル設定（.tmux.conf の setw -g ...）に戻す
			tmux set-window-option -u -t "$win" "$opt" 2>/dev/null
		fi
	done

	# 実行中だけウィンドウ名の後ろにスピナーを出す
	# 書式はグローバル設定を実行時に読んで組み立てるので、
	# .tmux.conf の window-status-format を変えても追従する
	if [ "$state" = "running" ] && [ "$SPINNER" = "on" ]; then
		base=$(tmux show-options -gv window-status-format 2>/dev/null) || base=""
		tmux set-window-option -t "$win" window-status-format \
			"$base#($SELF --spinner)" 2>/dev/null
	else
		tmux set-window-option -u -t "$win" window-status-format 2>/dev/null
	fi
}

# 実行中のウィンドウが1つでも存在するか
any_running() {
	local file state pid

	for file in "$STATE_DIR/$SERVER-"*; do
		[ -f "$file" ] || continue
		IFS=$'\t' read -r state pid _ <"$file" || continue
		[ "$state" = "running" ] || continue

		# PIDが記録されていない場合は生存確認できないので、動いているとみなす
		case "${pid:-}" in
		'' | *[!0-9]*) return 0 ;;
		esac
		kill -0 "$pid" 2>/dev/null && return 0
	done

	return 1
}

# スピナーを動かすには毎秒の再描画が要るが、status-interval はグローバル設定
# なので常時1にするとステータスバー全体の再描画まで増える
# 実行中のウィンドウがある間だけ1に上げ、無くなったら元の値へ戻す
sync_status_interval() {
	local cur saved

	[ "$SPINNER" = "on" ] || return 0
	cur=$(tmux show-options -gv status-interval 2>/dev/null) || return 0

	if any_running; then
		# 既に1なら、元の値を上書きしないよう何もしない
		[ "$cur" = "1" ] && return 0
		tmux set-option -g @claude-saved-status-interval "$cur" 2>/dev/null
		tmux set-option -g status-interval 1 2>/dev/null
	else
		[ "$cur" = "1" ] || return 0
		# 保存値が無い場合は利用者自身が1に設定しているので触らない
		saved=$(tmux show-options -gqv @claude-saved-status-interval 2>/dev/null)
		[ -n "$saved" ] || return 0
		tmux set-option -g status-interval "$saved" 2>/dev/null
		tmux set-option -gu @claude-saved-status-interval 2>/dev/null
	fi
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
	echo "usage: ${0##*/} {running|waiting|done|none|--ack <window-id>|--spinner}" >&2
	exit 1
	;;
esac

sync_status_interval

# フックを絶対にブロックしない
exit 0
