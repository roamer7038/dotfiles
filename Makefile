#!/bin/env make

current_dir := $(shell pwd)

all: minimum

.ssh:
	${current_dir}/bin/authorized_keys.sh

minimum:
	${current_dir}/bin/create-symlinks.sh -d

develop:
	${current_dir}/bin/create-symlinks.sh -v

i3:
	${current_dir}/bin/create-symlinks.sh -a -c -d -x
	cp ${current_dir}/bin/kbdmgmt ${HOME}/.kbdmgmt
	cp ${current_dir}/bin/powermgmt ${HOME}/.powermgmt
