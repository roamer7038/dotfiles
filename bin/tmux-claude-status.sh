#!/bin/bash
#
# Claude Code の状態（実行中／承認待ち／完了）を、tmux のウィンドウステータスの
# 背景色とスピナーで可視化する。Claude Code と tmux のフックから呼ばれる。
#
#   tmux-claude-status.sh running|waiting|done|none   Claude Code のフック用
#   tmux-claude-status.sh --ack <window-id>           tmux のフック用（既読化）
#   tmux-claude-status.sh --spinner                   window-status-format の #() 用
#
# done は Stop フックから渡されるが、バックグラウンド作業が残っている場合は
# 実行中として扱う。判定には stdin に届く Stop の入力を使う。
#
# 設定方法と挙動の詳細は docs/tmux-claude-status.md を参照。
# tmux 外・tmux 不在の環境では何もせず正常終了する。

set -u

# ============================================================
# スピナー
# ============================================================

# window-status-format の #() から毎秒呼ばれる
# tmux の検査やディレクトリ作成より前に返し、余計な処理をさせない
# 現在時刻からフレームを選ぶので、状態も常駐プロセスも持たない
if [ "${1:-}" = "--spinner" ]; then
  # 点字セル(2x4)の外周8方向を、3点の弧で1コマ1ステップずつ回す
  # 定番の "dots" スピナーは点灯数が3個と4個で不規則に変わるため、
  # 毎秒1コマしか進まない条件では回転方向が読み取れない
  set -- '⠙' '⠸' '⢰' '⣠' '⣄' '⡆' '⠇' '⠋'
  printf -v _now '%(%s)T' -1 2>/dev/null || _now=$(date +%s)
  eval printf '%s' "\${$((_now % $# + 1))}"
  exit 0
fi

# ============================================================
# 設定と事前チェック
# ============================================================

# --- 設定 ---

# 状態ごとのウィンドウステータスのスタイル
# 実行中は着色しない（空文字＝グローバル設定のまま）
# スピナーがステータスバー上で唯一動く要素なので、色を足さなくても見つかる
# 塗りつぶすとアクティブなウィンドウより目立ってしまうため、
# 色は操作を促したい承認待ち・完了のためだけに使う
STYLE_RUNNING=""
STYLE_WAITING="bg=colour136,fg=colour232"
STYLE_DONE="bg=colour22,fg=colour255"

# 実行中のウィンドウにスピナーを表示するか（off で無効）
# 有効な間だけ status-interval を1に上げるため、再描画の頻度が上がる
SPINNER=on

# 承認待ち・完了を示す静止アイコン（空文字で無効）
# 色を覚えていなくても形で区別できるようにするためのもの
# スピナーと違い #() を呼ばないので status-interval は上がらない
# tmux の書式として解釈されるため # を含む文字は使わない
ICON_WAITING="!"
ICON_DONE="✓"

# #() から自分自身を呼ぶために絶対パスを持っておく
SELF=$(readlink -f "$0" 2>/dev/null) || SELF=$0

# 状態ファイルの置き場所（tmpfs、再起動で消える）
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  STATE_DIR="$XDG_RUNTIME_DIR/tmux-claude-status"
else
  STATE_DIR="/tmp/tmux-claude-status-$(id -u)"
fi

# --- 事前チェック ---

# tmux の外、または tmux が無い環境では何もしない
[ -n "${TMUX:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# $TMUX は "ソケットパス,サーバ PID,セッション ID" 形式
# ペイン ID は tmux サーバ内でのみ一意なため、サーバ PID を状態ファイル名に含めて
# 複数の tmux サーバ（tmux -L）を併用しても衝突しないようにする
SERVER=${TMUX#*,}
SERVER=${SERVER%%,*}
[ -n "$SERVER" ] || SERVER=0

# ============================================================
# 共通処理
# ============================================================

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

# ペイン ID から状態ファイルのパスを組み立てる（%3 -> $STATE_DIR/1766-3）
state_file() {
  echo "$STATE_DIR/$SERVER-${1#%}"
}

# 自身の祖先を辿って Claude Code の PID を探す
# フックは Claude Code の子プロセスとして起動されるため、数段辿れば見つかる
# プロセス名の完全一致で判定する（cmdline の部分一致だと、~/.claude/ 配下の
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

    # /proc/<pid>/stat の第4フィールドが親 PID
    # コマンド名に空白を含む場合があるため、最後の ')' 以降を見る
    stat=$(cat "/proc/$pid/stat" 2>/dev/null) || return 1
    pid=$(echo "${stat##*) }" | awk '{print $2}')
    depth=$((depth + 1))
  done

  return 1
}

# 状態ファイルを読み、記録された PID が生きていれば状態名を返す
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

  # PID が取れなかった記録（"-"）は生存確認をスキップする
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

# 現在のペインに記録されている状態を返す
current_state() {
  if [ -z "${TMUX_PANE:-}" ]; then
    echo none
    return
  fi

  read_state "$TMUX_PANE"
}

# Stop の入力を読み、まだ動いているバックグラウンド作業があるか調べる
# 本体のターンが終わってもバックグラウンドのシェルやサブエージェントが
# 残っていることがあり、それを完了として表示すると誤報になる
# 作業が終わると Claude Code がエージェントを呼び直し、空の background_tasks を
# 持つ Stop が改めて届くので、そこで完了になる
has_running_background_task() {
  local json count

  # 手で実行したときに入力待ちで止まらないようにする
  [ -t 0 ] && return 1

  json=$(cat 2>/dev/null) || return 1
  [ -n "$json" ] || return 1

  if command -v jq >/dev/null 2>&1; then
    count=$(printf '%s' "$json" |
      jq -r '[.background_tasks[]? | select(.status == "running" or .status == "pending")] | length' \
        2>/dev/null) || return 1
    case "${count:-}" in
    '' | *[!0-9]*) return 1 ;;
    esac
    [ "$count" -gt 0 ]
    return
  fi

  # jq が無い環境向けの目安。整形されていても読めるよう空白を潰してから見る
  json=${json//[[:space:]]/}
  case "$json" in
  *'"background_tasks":[]'*) return 1 ;;
  *'"background_tasks":['*'"status":"running"'*) return 0 ;;
  *'"background_tasks":['*'"status":"pending"'*) return 0 ;;
  *) return 1 ;;
  esac
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
apply_window() {
  local win=$1 state=$2 style="" mark="" opt base fmt

  # 状態ごとの配色と、ウィンドウ名の後ろに出す印を決める
  # 実行中は回転するスピナー、承認待ち・完了は静止アイコン
  case "$state" in
  waiting)
    style=$STYLE_WAITING
    mark=$ICON_WAITING
    ;;
  "done")
    style=$STYLE_DONE
    mark=$ICON_DONE
    ;;
  running)
    style=$STYLE_RUNNING
    if [ "$SPINNER" = "on" ]; then
      mark="#($SELF --spinner)"
    fi
    ;;
  esac

  for opt in window-status-style window-status-activity-style; do
    if [ -n "$style" ]; then
      tmux set-window-option -t "$win" "$opt" "$style" 2>/dev/null
    else
      # グローバル設定（.tmux.conf の setw -g ...）に戻す
      tmux set-window-option -u -t "$win" "$opt" 2>/dev/null
    fi
  done

  # 対象ウィンドウでのみ活動監視を切る
  # monitor-activity はウィンドウオプションなので他のウィンドウには影響しない
  # 「出力があった」を示す # フラグと、それに伴う反転描画
  # （window-status-activity-style、既定は reverse）が無くなる
  # Claude Code のウィンドウでは常に出力があり # は情報量を持たないうえ、
  # 反転がこのスクリプトの背景色を打ち消してしまうため
  # 上の window-status-activity-style の設定は、利用者が個別に監視を
  # 戻した場合に色が反転しないようにするための保険として残している
  # 判断は配色ではなく状態で行う。実行中は着色しないため、配色の有無で
  # 判断すると監視が戻ってしまい # と反転が出てしまう
  case "$state" in
  none | "") tmux set-window-option -u -t "$win" monitor-activity 2>/dev/null ;;
  *) tmux set-window-option -t "$win" monitor-activity off 2>/dev/null ;;
  esac

  # 非アクティブ用（window-status-format）とアクティブ用
  # （window-status-current-format）の両方に付ける
  # ウィンドウを行き来しても表示が途切れず、コピーモード中など
  # Claude Code の画面が見えていないときも状態が分かる
  # 書式はグローバル設定を実行時に読んで組み立てるので、
  # .tmux.conf 側を変えても追従する
  for opt in window-status-format window-status-current-format; do
    if [ -n "$mark" ]; then
      base=$(tmux show-options -gv "$opt" 2>/dev/null) || base=""

      # 書式が #[default] で終わる場合はその手前に入れる
      # 後ろに置くと装飾がリセットされ、印だけウィンドウ名と
      # 違う色（現在ウィンドウなら window-status-current-style の色）になる
      case "$base" in
      *'#[default]') fmt="${base%'#[default]'}$mark#[default]" ;;
      *) fmt="$base$mark" ;;
      esac

      tmux set-window-option -t "$win" "$opt" "$fmt" 2>/dev/null
    else
      tmux set-window-option -u -t "$win" "$opt" 2>/dev/null
    fi
  done
}

# 実行中のウィンドウが1つでも存在するか
any_running() {
  local file state pid

  for file in "$STATE_DIR/$SERVER-"*; do
    [ -f "$file" ] || continue
    IFS=$'\t' read -r state pid _ <"$file" || continue
    [ "$state" = "running" ] || continue

    # PID が記録されていない場合は生存確認できないので、動いているとみなす
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

# Claude Code が消えた状態ファイルを掃除し、対象ウィンドウを塗り直す
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

# ============================================================
# サブコマンド
# ============================================================

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

  # フックは Claude Code のプロセスから起動されるので TMUX_PANE を引き継いでいる
  [ -n "${TMUX_PANE:-}" ] || return 0

  win=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null) || return 0
  [ -n "$win" ] || return 0

  file=$(state_file "$TMUX_PANE")

  if [ "$state" = "none" ]; then
    rm -f "$file"
  else
    # PID が特定できない場合もプレースホルダを置く
    # タブは空白類なので、空フィールドがあると列が詰まってずれてしまう
    pid=$(find_claude_pid) || pid=""
    [ -n "$pid" ] || pid="-"
    printf '%s\t%s\t%s\n' "$state" "$pid" "$win" >"$file"
  fi

  repaint_window "$win"
}

# ============================================================
# エントリポイント
# ============================================================

case "${1:-}" in
--ack)
  [ -n "${2:-}" ] || exit 0
  prune_dead
  ack_window "$2"
  ;;
running | waiting | done | none)
  state=$1

  # Stop は完了として呼ばれるが、バックグラウンド作業が残っていれば実行中とみなす
  if [ "$state" = "done" ] && has_running_background_task; then
    state=running
  fi

  # PreToolUse・PostToolUse はツールを呼ぶたびに実行中を伝えてくる
  # 既に実行中なら表示は何も変わらないので、tmux を呼ばずに帰る
  # これで tmux を起動するのは状態が実際に動くときだけになる
  if [ "$state" = "running" ] && [ "$(current_state)" = "running" ]; then
    exit 0
  fi

  prune_dead
  set_state "$state"
  ;;
*)
  echo "usage: ${0##*/} {running|waiting|done|none|--ack <window-id>|--spinner}" >&2
  exit 1
  ;;
esac

sync_status_interval

# フックを絶対にブロックしない
exit 0
