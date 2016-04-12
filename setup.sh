#!/bin/sh

cd ~/dotfiles
ln -sf `pwd`/.bash_profile ~/.bash_profile
ln -sf `pwd`/.bashrc ~/.bashrc
ln -sf `pwd`/.screenrc ~/.screenrc
ln -sf `pwd`/.vimrc ~/.vimrc
ln -sf `pwd`/.zshrc ~/.zshrc

cd
git clone https://github.com/tomasr/molokai.git
mkdir -p .vim/colors
cp molokai/colors/molokai.vim .vim/colors/molokai.vim
rm -rf molokai/
