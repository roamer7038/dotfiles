#!/bin/bash

set -xue

PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); cd ../; pwd)

#==============
# Basic dotfiles
#==============
DOTFILES=(.bashrc .zshrc .tmux.conf .vimrc .gitconfig .latexmkrc)
for file in ${DOTFILES[@]}; do
  ln -sf $PWD/$file $HOME/$file
done

#==============
# Vim
#==============
VIMCONF=($(ls $PWD/.vim))
mkdir -p $HOME/.vim
for file in ${VIMCONF[@]}; do
  ln -sf $PWD/.vim/$file $HOME/.vim/$file
done

#==============
# X Window System
#==============
if type "xset" > /dev/null 2>&1; then
  XCONFIG=(.Xmodmap .xprofile .picom.conf)
  for file in ${XCONFIG[@]}; do
    ln -sf $PWD/$file $HOME/$file
  done
fi

#==============
# Application Configs
#==============
getopts "a" opts
if [ $opts = "a" ]; then
  APPCONFDIR=(terminator dunst)
  for dir in ${APPCONFDIR[@]}; do
    mkdir -p $HOME/.config/$dir
    APPCONFIG=($(ls $PWD/etc/$dir))
    for file in ${APPCONFIG[@]}; do
      ln -sf $PWD/etc/$dir/$file $HOME/.config/$dir/$file
    done
  done
fi
