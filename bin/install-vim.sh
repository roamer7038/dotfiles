#!/bin/sh
# Install vim latest version from source
# Ubuntu 22.04

sudo apt update

# Remove vim if installed
sudo apt remove vim vim-runtime gvim

# Install dependencies
sudo apt install git make build-essential unzip

# Download vim source
wget https://github.com/vim/vim/archive/master.zip
unzip master.zip
cd vim-master/src
./configure
make
sudo make install

# clean up
cd ../..
rm -rf vim-master
rm master.zip

# Check vim version
vim --version
