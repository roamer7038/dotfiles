#!/bin/sh
#
# GitHub に登録された公開鍵を取得して ~/.ssh/authorized_keys に追記する
# （上書きはしない）。
#
#   authorized_keys.sh [github-user]   既定のユーザは roamer7038

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

echo "GitHubユーザー: $GITHUB_USER から公開鍵を取得します..."

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
  echo "エラー: GitHubユーザー '$GITHUB_USER' の公開鍵を取得できませんでした" >&2
  echo "ユーザー名が正しいか、またはインターネット接続を確認してください" >&2
  exit 1
fi

# 取得した公開鍵が空でないかチェック
if [ -z "$KEYS" ]; then
  echo "警告: GitHubユーザー '$GITHUB_USER' に公開鍵が登録されていません" >&2
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
echo "成功: $KEY_COUNT 個の公開鍵を ~/.ssh/authorized_keys に追加しました"
echo "追加されたキー:"
echo "$KEYS" | sed 's/^/  /'
