#!/bin/bash
# ============================================================
# install-zsh-plugins.sh
# ============================================================
#
# 概要:
#   zshプラグインをインストールする
#
# 使用例:
#   $ ./install-zsh-plugins.sh
#
# ============================================================

set -e

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
		echo "$plugin_name is already installed at $plugin_path"
		return 0
	fi

	echo "Installing $plugin_name..."
	if git clone "$plugin_repo" "$plugin_path" 2>/dev/null; then
		echo "$plugin_name installed successfully!"
	else
		echo "Failed to install $plugin_name" >&2
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

	echo ""
	echo "Installation complete!"
	echo ""
	echo "To enable plugins, add to your .zshrc:"
	echo "  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
}

main "$@"
