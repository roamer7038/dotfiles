#!/bin/env make

PWD := $(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

all:
	init
	i3plasma
	.ssh

init:
	${PWD}/bin/create-symlinks.sh -a

minimal:
	${PWD}/bin/create-symlinks.sh

i3:
	mkdir -p ${HOME}/.config/{i3,i3status}
	ln -sf ${PWD}/etc/i3/config ${HOME}/.config/i3/config
	ln -sf ${PWD}/etc/i3status/config ${HOME}/.config/i3status/config

i3plasma:
	cp ${PWD}/etc/i3plasma/i3plasma.desktop /usr/share/xsessions/i3plasma.desktop
	cp ${PWD}/etc/i3plasma/i3plasma.sh /usr/local/bin/i3plasma.sh
	mkdir -p ${HOME}/.config/i3
	ln -sf ${PWD}/etc/i3plasma/config ${HOME}/.config/i3/config

.ssh:
	${PWD}/bin/authorized_keys.sh
