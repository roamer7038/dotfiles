#!/bin/env make

current_dir := $(shell pwd)

all:
	install
	i3
	.ssh

install:
	${current_dir}/bin/create-symlinks.sh -a

minimal:
	${current_dir}/bin/create-symlinks.sh

i3:
	mkdir -p ${HOME}/.config/{i3,i3status}
	ln -sf ${current_dir}/etc/i3/config ${HOME}/.config/i3/config
	ln -sf ${current_dir}/etc/i3status/config ${HOME}/.config/i3status/config
	cp ${current_dir}/bin/kbdmgmt ${HOME}/.kbdmgmt
	cp ${current_dir}/bin/powermgmt ${HOME}/.powermgmt

.ssh:
	${current_dir}/bin/authorized_keys.sh

