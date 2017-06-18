#!/bin/sh

# run this script directory path
PWD=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

ln -sf $PWD/.bash_profile ~/.bash_profile
ln -sf $PWD/.bashrc ~/.bashrc
ln -sf $PWD/.screenrc ~/.screenrc
ln -sf $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.gitconfig ~/.gitconfig
ln -sf $PWD/.latexmkrc ~/.latexmkrc

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
        ;;
    linux*)
        ln -sf $PWD/.Xdefaults ~/.Xdefaults
        ln -sf $PWD/.Xmodmap ~/.Xmodmap
        ln -sf $PWD/.xprofile ~/.xprofile
		if [ -x "`which i3 `" ]; then
   			mkdir -p ~/.config/i3
			ln -sf $PWD/.config/i3/config ~/.config/i3/config
            mkdir -p ~/.config/i3status
            ln -sf $PWD/.config/i3status/config ~/.config/i3status/config
		fi 
        if [ -x `which terminator` ]; then
            mkdir -p ~/.config/terminator
            ln -sf $PWD/.config/terminator/config ~/.config/terminator/config
        fi
        ;;
esac
