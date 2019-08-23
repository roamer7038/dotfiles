#!/bin/sh

# Where this script is running
PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# Basic dotfiles
DOTFILES=(.bashrc .zshrc .tmux.conf .vimrc .gitconfig .latexmkrc)
for file in ${DOTFILES[@]}; do
  ln -s $PWD/$file $HOME/$file
done

# Vim's config
# With option the "-nox", the ".vim.nox" is duplicated.
# By default, the ".vim" directory is created and the files are duplicated.
getopts "nox" opts
if [ $opts = "nox" ]; then
  ln -sf $PWD/.vimrc.nox ~/.vimrc
  exit 0
else
  mkdir -p $HOME/.vim

  VIMCONF=($(ls $PWD/.vim))
  for file in ${VIMCONF[@]}; do
    ln -sf $PWD/.vim/$file $HOME/.vim/$file
  done
fi

case ${OSTYPE} in
  darwin*)
    ;;
  linux*)
    # X Window System's config
    XCONFIG=(.Xmodmap .xprofile .compton.conf)
    for file in ${XCONFIG[@]}; do
      ln -s $PWD/$file $HOME/$file
    done

    # Application's config
    mkdir -p $HOME/.config
    APPCONFDIR=(i3 i3status terminator alacritty dunst)
    for dir in ${APPCONFDIR[@]}; do
      mkdir -p $HOME/.config/$dir
      APPCONF=($(ls $PWD/.config/$dir))
      for file in ${APPCONF[@]}; do
        ln -sf $PWD/.config/$dir/$file $HOME/.config/$dir/$file
      done
    done
esac
