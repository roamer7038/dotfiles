#!/bin/bash
# ============================================================
# install-bun.sh
# ============================================================
#
# 概要:
#   bun（JavaScriptランタイム兼ツールキット）を自動インストールするスクリプト
#
# 用途:
#   新しい環境にbunをセットアップ
#   anyenvには含まれないため、.ssh/anyenv/docker等と同様に個別導入する
#
# 依存関係:
#   - curl または wget
#   - bash
#   - unzip
#   - インターネット接続
#
# 使用例:
#   $ ./install-bun.sh
#
# 注意事項:
#   - 既にインストール済み（~/.bun が存在）の場合はスキップします
#   - PATH設定は .zshrc に既に含まれています
#
# ============================================================

set -e

echo "Starting bun installation..."

###########################################################
# 既存インストールのチェック
###########################################################

if [ -d "$HOME/.bun" ]; then
	echo "bun is already installed (~/.bun exists)."
	if command -v bun >/dev/null 2>&1; then
		echo "Version: $(bun --version)"
	fi
	echo "To update, run: bun upgrade"
	exit 0
fi

###########################################################
# bun のインストール
###########################################################

echo "Installing bun via official install script..."

# 公式インストールスクリプトを使用
curl -fsSL https://bun.sh/install | bash

echo "bun installation completed."

###########################################################
# 完了メッセージ
###########################################################

echo ""
echo "============================================"
echo "bun installation completed successfully!"
echo "============================================"
echo ""
echo "PATH settings are already included in .zshrc."
echo "Reload your shell to start using bun:"
echo "  exec \$SHELL -l"
echo ""
echo "Test your installation with:"
echo "  bun --version"
echo ""
