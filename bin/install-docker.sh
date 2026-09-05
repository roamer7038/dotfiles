#!/bin/bash
#
# Docker Engine（公式スクリプト）と Lazydocker を導入する。
# 実行ユーザを docker グループに追加するため、反映にはログアウトが要る。
# 手順の詳細は docs/docker.md を参照。

set +xe

echo "Starting Docker installation..."

# --- Docker Engine のインストール ---

echo "Installing Docker Engine..."

# Docker公式のインストールスクリプトをダウンロード
curl -fsSL https://get.docker.com -o get-docker.sh

# インストールスクリプトを実行
sudo sh get-docker.sh

# インストールスクリプトを削除
rm -f get-docker.sh

echo "Docker Engine installation completed."

# --- Lazydocker のインストール ---

echo "Installing Lazydocker..."

# Lazydocker（DockerコンテナのTUI管理ツール）をインストール
# 公式インストールスクリプトを使用
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# Lazydockerを/usr/local/binに移動（全ユーザーがアクセス可能に）
sudo mkdir -p /usr/local/bin
sudo mv $HOME/.local/bin/lazydocker /usr/local/bin

echo "Lazydocker installation completed."

# --- ユーザーをdockerグループに追加 ---

echo "Adding current user to docker group..."

# 現在のユーザーをdockerグループに追加
# これにより、sudoなしでdockerコマンドを実行できるようになる
sudo gpasswd -a $USER docker

echo "User added to docker group."

# --- 完了メッセージ ---

echo ""
echo "============================================"
echo "Docker installation completed successfully!"
echo "============================================"
echo ""
echo "Please log out and log back in for the group changes to take effect."
echo "After that, you can use Docker without sudo."
echo ""
echo "Test your installation with:"
echo "  docker --version"
echo "  docker run hello-world"
echo "  lazydocker"
echo ""
