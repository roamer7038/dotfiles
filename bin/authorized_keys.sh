#!/bin/sh
#
# GitHub に登録された公開鍵を取得して ~/.ssh/authorized_keys に追記する
# （上書きはしない）。
#
#   authorized_keys.sh [github-user]   既定のユーザは roamer7038

if [ -t 1 ]; then
  N=$(printf '\033[0m') G=$(printf '\033[0;32m') Y=$(printf '\033[0;33m') B=$(printf '\033[0;34m') R=$(printf '\033[0;31m')
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

# デフォルトのGitHubユーザー名
DEFAULT_USER="roamer7038"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [GITHUB_USERNAME]

概要:
  GitHubから公開鍵を取得してSSH認証用のauthorized_keysに追加

引数:
  GITHUB_USERNAME   GitHubユーザー名（省略時: $DEFAULT_USER）

オプション:
  -h, --help        このヘルプを表示

使用例:
  $(basename "$0")                # デフォルトユーザー（$DEFAULT_USER）
  $(basename "$0") username       # 指定したGitHubユーザー

EOF
  exit 0
}

# 引数の処理
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
fi

# GitHubユーザー名の決定
if [ -n "$1" ]; then
  GITHUB_USER="$1"
else
  GITHUB_USER="$DEFAULT_USER"
fi

log_info "GitHub ユーザー $GITHUB_USER から公開鍵を取得します..."

# --- .sshディレクトリの作成 ---

# .sshディレクトリの作成（存在しない場合）
# パーミッションは700（所有者のみアクセス可能）に設定
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# --- GitHubから公開鍵を取得 ---

# GitHub APIエンドポイント: https://github.com/{username}.keys
GITHUB_URL="https://github.com/${GITHUB_USER}.keys"

# curlで公開鍵を取得（エラーチェック付き）
# -f: HTTPエラー時に失敗ステータスを返す
# -s: サイレントモード（進捗表示なし）
# -S: エラーメッセージは表示
KEYS=$(curl -fsSL "$GITHUB_URL" 2>&1)
CURL_EXIT_CODE=$?

# curlの実行結果をチェック
if [ $CURL_EXIT_CODE -ne 0 ]; then
  log_error "GitHub ユーザー '$GITHUB_USER' の公開鍵を取得できなかった"
  log_error "ユーザー名とネットワーク接続を確認する"
  exit 1
fi

# 取得した公開鍵が空でないかチェック
if [ -z "$KEYS" ]; then
  log_warn "GitHub ユーザー '$GITHUB_USER' に公開鍵が登録されていない"
  exit 1
fi

# 公開鍵をauthorized_keysに追記
echo "$KEYS" >>~/.ssh/authorized_keys

# --- パーミッションの設定 ---

# authorized_keysのパーミッションを600に設定
# （所有者のみ読み書き可能、SSHの要件）
chmod 600 ~/.ssh/authorized_keys

# --- 完了メッセージ ---

KEY_COUNT=$(echo "$KEYS" | wc -l)
log_ok "$KEY_COUNT 個の公開鍵を ~/.ssh/authorized_keys に追加した"
log_info "追加されたキー:"
echo "$KEYS" | sed 's/^/  /'
