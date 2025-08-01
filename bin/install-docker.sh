#!/bin/bash

set +xe

# install docker engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

# install lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
sudo mkdir -p /usr/local/bin
sudo mv $HOME/.local/bin/lazydocker /usr/local/bin

sudo gpasswd -a $USER docker
