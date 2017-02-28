#!/bin/sh

cd ~/dotfiles
ln -sf `pwd`/.bash_profile ~/.bash_profile
ln -sf `pwd`/.bashrc ~/.bashrc
ln -sf `pwd`/.screenrc ~/.screenrc
ln -sf `pwd`/.vimrc ~/.vimrc
ln -sf `pwd`/.zshrc ~/.zshrc
ln -sf `pwd`/.gitconfig ~/.gitconfig

cd
git clone https://github.com/tomasr/molokai.git
mkdir -p .vim/colors
cp molokai/colors/molokai.vim .vim/colors/molokai.vim
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
        cd ~/dotfiles
        brew tap homebrew/bundle
        brew bundle
        curl -L git.io/nodebrew | perl - setup
        ;;
esac 
