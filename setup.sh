#!/bin/sh

# run this script directory path
PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

ln -sf $PWD/.bash_profile ~/.bash_profile
ln -sf $PWD/.bashrc ~/.bashrc
ln -sf $PWD/.screenrc ~/.screenrc
ln -sf $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.gitconfig ~/.gitconfig

mkdir -p ~/.vim/colors
git clone https://github.com/tomasr/molokai.git
cp molokai/colors/molokai.vim ~/.vim/colors/molokai.vim
rm -rf molokai/

case ${OSTYPE} in
    darwin*)
        xcode-select --install
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        defaults write com.apple.desktopservices DSDontWriteNetworkStores true
        echo 'Please enter GitHub API Token.'
        read TOKEN
        touch ~/.github_api_token
        echo 'export HOMEBREW_GITHUB_API_TOKEN="'$TOKEN'"' > ~/.github_api_token
        source ~/.bashrc
        brew tap homebrew/bundle
        cd $PWD
        brew bundle
        curl -L git.io/nodebrew | perl - setup
        ;;
    linux*)
        ln -sf $PWD/.Xdefaults ~/.Xdefaults
        ln -sf $PWD/.Xmodmap ~/.Xmodmap
        ln -sf $PWD/.xprofile ~/.xprofile
		if [ -x "`which i3 `" ]; then
   			mkdir -p ~/.config/i3
			ln -sf $PWD/.config/i3/config ~/.config/i3/config
		fi 
        ;;
esac
