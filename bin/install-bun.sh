#!/bin/bash
#
# bun（JavaScript ランタイム兼ツールキット）を導入する。
# anyenv の管理外なので個別に入れる。~/.bun があれば何もしない。

set -e

echo "Starting bun installation..."

# --- 既存インストールのチェック ---

if [ -d "$HOME/.bun" ]; then
  echo "bun is already installed (~/.bun exists)."
  if command -v bun >/dev/null 2>&1; then
    echo "Version: $(bun --version)"
  fi
  echo "To update, run: bun upgrade"
  exit 0
fi

# --- bun のインストール ---

echo "Installing bun via official install script..."

# 公式インストールスクリプトを使用
curl -fsSL https://bun.sh/install | bash

echo "bun installation completed."

# --- 完了メッセージ ---

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
