#!/bin/env make

current_dir := $(shell pwd)

all:
	init
	i3plasma
	.ssh

init:
	${current_dir}/bin/create-symlinks.sh -a

minimal:
	${current_dir}/bin/create-symlinks.sh

i3:
	mkdir -p ${HOME}/.config/{i3,i3status}
	ln -sf ${current_dir}/etc/i3/config ${HOME}/.config/i3/config
	ln -sf ${current_dir}/etc/i3status/config ${HOME}/.config/i3status/config

i3plasma:
	cp ${current_dir}/etc/i3plasma/i3plasma.desktop /usr/share/xsessions/i3plasma.desktop
	cp ${current_dir}/etc/i3plasma/i3plasma.sh /usr/local/bin/i3plasma.sh
	mkdir -p ${HOME}/.config/i3
	ln -sf ${current_dir}/etc/i3plasma/config ${HOME}/.config/i3/config

.ssh:
	${current_dir}/bin/authorized_keys.sh

