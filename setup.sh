#!/bin/sh

# run this script directory path
PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

ln -sf $PWD/.bash_profile ~/.bash_profile
ln -sf $PWD/.bashrc ~/.bashrc
ln -sf $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.gitconfig ~/.gitconfig

## nox on Linux Server 
getopts "nox" opts
if [ $opts = "r" ]; then
  ln -sf $PWD/.vimrc.nox ~/.vimrc
  exit 1
fi

case ${OSTYPE} in
  darwin*)
    xcode-select --install
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo 'Please enter GitHub API Token.'
    read TOKEN
    touch ~/.github_api_token
    echo 'export HOMEBREW_GITHUB_API_TOKEN="'$TOKEN'"' > ~/.github_api_token
    source ~/.bashrc
    brew tap homebrew/bundle
    cd $PWD
    brew bundle
    ;;
  linux*)
    ## X Window System
    ln -sf $PWD/.Xdefaults ~/.Xdefaults
    ln -sf $PWD/.Xmodmap ~/.Xmodmap
    ln -sf $PWD/.xprofile ~/.xprofile
    ln -sf $PWD/.compton.conf ~/.compton.conf
    ## i3 Window Manager
    mkdir -p ~/.config/i3
    ln -sf $PWD/.config/i3/config ~/.config/i3/config
    mkdir -p ~/.config/i3status
    ln -sf $PWD/.config/i3status/config ~/.config/i3status/config
    ## Terminal Emulator
    mkdir -p ~/.config/termite
    ln -sf $PWD/.config/termite/config ~/.config/termite/config
    ## Other Software
    mkdir -p ~/.config/dunst
    ln -sf $PWD/.config/dunst/dunstrc ~/.config/dunst/dunstrc
    ln -sf $PWD/.latexmkrc ~/.latexmkrc
    ;;
esac
