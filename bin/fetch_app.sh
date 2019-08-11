#!/bin/sh

mkdir -p $HOME/bin

curl https://raw.githubusercontent.com/rksz/dotfiles/master/bin/pane -o $HOME/bin/pane
chmod +x pane 
