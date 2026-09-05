#!/bin/bash
#
# zsh のプラグインを ~/.zsh 配下に clone する。

set -e

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

# ベースディレクトリ
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh}"

# プラグイン定義（name:repository の形式）
PLUGINS=(
  "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
  # 将来追加する場合はここに記述
  # "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
  # "zsh-completions:https://github.com/zsh-users/zsh-completions"
)

# 汎用的な存在チェック関数
plugin_exists() {
  local plugin_name="$1"
  local plugin_path="$ZSH_PLUGIN_DIR/$plugin_name"
  [ -d "$plugin_path" ]
}

# 汎用的なインストール関数
install_plugin() {
  local plugin_name="$1"
  local plugin_repo="$2"
  local plugin_path="$ZSH_PLUGIN_DIR/$plugin_name"

  if plugin_exists "$plugin_name"; then
    log_skip "$plugin_name: 導入済み ($plugin_path)"
    return 0
  fi

  log_info "$plugin_name を導入します..."
  if git clone "$plugin_repo" "$plugin_path" 2>/dev/null; then
    log_ok "$plugin_name: 導入した"
  else
    log_error "$plugin_name: 導入に失敗"
    return 1
  fi
}

# メイン処理
main() {
  # プラグインディレクトリの作成
  mkdir -p "$ZSH_PLUGIN_DIR"

  # 各プラグインのインストール
  for plugin_def in "${PLUGINS[@]}"; do
    IFS=':' read -r name repo <<<"$plugin_def"
    install_plugin "$name" "$repo"
  done

  log_ok "完了（.zshrc は ~/.zsh 配下を自動で読み込む）"
}

main "$@"
