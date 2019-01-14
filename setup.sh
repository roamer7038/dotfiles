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
getopts "s" opts
if [ $opts = "s" ]; then
  ln -sf $PWD/.vimrc.nox ~/.vimrc
  exit 0
fi

case ${OSTYPE} in
  darwin*)
    xcode-select --install
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo 'Please enter GitHub Username...'
    read GITHUB_USERNAME 
    TOKEN=$(curl -u $GITHUB_USERNAME -d '{"scopes":["repo"],"note":"'$(date +"%Y%m%d%I%M%S")'"}' https://api.github.com/authorizations | grep -w 'token' | awk -F '"' '{ print $4 }')
    echo 'export HOMEBREW_GITHUB_API_TOKEN="'$TOKEN'"' > ~/.github_api_token
    exec $SHELL -l
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
    mkdir -p ~/.config/terminator
    ln -sf $PWD/.config/terminator/config ~/.config/terminator/config
    mkdir -p ~/.config/alacritty
    ln -sf $PWD/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
    ## Other Software
    mkdir -p ~/.config/dunst
    ln -sf $PWD/.config/dunst/dunstrc ~/.config/dunst/dunstrc
    ln -sf $PWD/.latexmkrc ~/.latexmkrc
    ;;
esac
