#!/bin/bash

set -xe

PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); cd ../; pwd)
I3WM=()

function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h          Display help.
  -a          Create symlinks for i3wm configs (use with -c).
  -c          Create symlinks for gui app configs.
  -d          Create symlinks for basic dotfiles.
  -v          Create symlinks for vim configs.
  -x          Create symlinks for x11 configs.
EOM
  exit 2
}

while getopts "acdvxh" OPT
do
  case $OPT in
    a) 
      #==============
      # i3 window manager
      #==============
      I3WM=(i3 i3status)
      ;;
    c)
      #==============
      # GUI Application Configs
      #==============
      APPCONFDIR=(terminator dunst ${I3WM[@]})
      for dir in ${APPCONFDIR[@]}; do
        mkdir -p $HOME/.config/$dir
        CONF=($(ls $PWD/config/$dir))
        for file in ${CONF[@]}; do
          ln -sf $PWD/config/$dir/$file $HOME/.config/$dir/$file
        done
      done
      ;;
    d)
      #==============
      # Minimum dotfiles
      #==============
      DOTFILES=(.bashrc .zshrc .tmux.conf .gitconfig .latexmkrc)
      for file in ${DOTFILES[@]}; do
        if [ "$file" = ".bashrc" ] && [ -e $HOME/.bashrc ]; then
          continue
        fi
        ln -sf $PWD/$file $HOME/$file
      done
      ;;
    v)
      #==============
      # Vim
      #==============
      VIMCONF=($(ls $PWD/.vim))
      ln -sf $PWD/.vimrc $HOME/.vimrc
      mkdir -p $HOME/.vim
      for file in ${VIMCONF[@]}; do
        ln -sf $PWD/.vim/$file $HOME/.vim/$file
      done
      ;;
    x)
      #==============
      # X Window System
      #==============
      XCONF=(.Xmodmap .xprofile .picom.conf)
      for file in ${XCONF[@]}; do
        ln -sf $PWD/$file $HOME/$file
      done
      ;;
    h)
      usage
      ;;
    /?)
      usage
      ;;
  esac
done
