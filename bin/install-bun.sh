#!/bin/bash
#
# bun（JavaScript ランタイム兼ツールキット）を導入する。
# anyenv の管理外なので個別に入れる。~/.bun があれば何もしない。

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

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

# --- .zshrc の保護 ---

# 公式インストーラは ~/.zshrc へ completions の読み込みを追記する。
# dotfiles の .zshrc は同じ読み込みを既に持っており、~/.zshrc はリポジトリへの
# リンクなので、そのままだとリポジトリが汚れる。導入前に差分が無ければ後で戻す。
RESTORE_ZSHRC=false
if [ "$(readlink -f "$HOME/.zshrc" 2>/dev/null)" = "$DOTFILES_ROOT/.zshrc" ] &&
  git -C "$DOTFILES_ROOT" diff --quiet -- .zshrc 2>/dev/null; then
  RESTORE_ZSHRC=true
fi

# --- bun のインストール ---

echo "Installing bun via official install script..."

# 公式インストールスクリプトを使用
curl -fsSL https://bun.sh/install | bash

echo "bun installation completed."

# --- .zshrc を元に戻す ---

if [ "$RESTORE_ZSHRC" = true ] && ! git -C "$DOTFILES_ROOT" diff --quiet -- .zshrc; then
  git -C "$DOTFILES_ROOT" checkout -- .zshrc
  echo "Reverted the line the bun installer appended to .zshrc."
fi

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
