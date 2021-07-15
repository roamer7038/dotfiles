#!/bin/env make

current_dir := $(shell pwd)
install_dir := /usr/local/bin

all: minimum develop

.ssh:
	${current_dir}/bin/authorized_keys.sh

minimum:
	${current_dir}/bin/create-symlinks.sh -d

develop:
	${current_dir}/bin/create-symlinks.sh -v

i3:
	${current_dir}/bin/create-symlinks.sh -a -c -d -x
	cp ${current_dir}/bin/xinit.sh ${HOME}/.xinit.sh

install:
	ln -sf ${current_dir}/bin/pane ${install_dir}/pane
	ln -sf ${current_dir}/bin/multissh ${install_dir}/multissh
