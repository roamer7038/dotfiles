#!/bin/sh 

mkdir -p ~/.ssh && chmod 700 ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
