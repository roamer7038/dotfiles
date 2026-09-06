#!/bin/sh
#
# Vim を最新のソースからビルドして入れ替える。Ubuntu 22.04 で確認。
# 既存の Vim パッケージを削除するので注意。sudo 権限が要る。

echo "Updating the package list..."
sudo apt update

echo "Removing the installed Vim packages..."
sudo apt remove vim vim-runtime gvim

echo "Installing build dependencies..."
sudo apt install git make build-essential ncurses-dev unzip

echo "Downloading the Vim source..."
wget https://github.com/vim/vim/archive/master.zip
unzip master.zip
cd vim-master/src

# 既定の構成でビルドする。インタプリタ連携が要るときは
# --enable-python3interp=yes などを足す
echo "Configuring..."
./configure

echo "Building Vim... (this may take a few minutes)"
make

echo "Installing Vim into /usr/local..."
sudo make install

cd ../..
rm -rf vim-master
rm master.zip

echo ""
echo "============================================"
echo "Vim installation completed successfully!"
echo "============================================"
echo ""
echo "Installed version:"
vim --version | head -n 1
echo ""
echo "Vim is installed at: $(which vim)"
echo ""
