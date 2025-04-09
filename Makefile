#!/bin/env make

current_dir := $(shell pwd)
install_dir := /usr/local/bin

all: basic

.ssh:
	${current_dir}/bin/authorized_keys.sh

# .bashrc .zshrc .tmux.conf .gitconfig .latexmkrc
minimum:
	${current_dir}/bin/create-symlinks.sh -d

# vim (+plugins): requirement: golang, nodejs, npm/yarn
develop:
	${current_dir}/bin/create-symlinks.sh -v -l

# minimum + develop + terminator dunst ranger 
basic:
	${current_dir}/bin/create-symlinks.sh -c -d -v -l

# basic + i3wm
full:
	${current_dir}/bin/create-symlinks.sh -a -c -d -v -l -x
	cp ${current_dir}/bin/xinit.sh ${HOME}/.xinit.sh

# install:
# 	ln -sf ${current_dir}/bin/pane ${install_dir}/pane
# 	ln -sf ${current_dir}/bin/multissh ${install_dir}/multissh

anyenv:
	git clone https://github.com/anyenv/anyenv ~/.anyenv
	# echo 'export PATH=$$HOME/.anyenv/bin:$$PATH' >> ~/.bash_profile
	# bash -c '~/.anyenv/bin/anyenv init'
	# anyenv install --init
	#
	# anyenv install nodenv
	# anyenv install goenv
