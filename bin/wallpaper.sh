#!/bin/sh
# 
# requirement: feh
#
# ~/.wallpaper ディレクトリ配下にある画像をランダムで選択して壁紙にする
#

mkdir -p ~/.wallpaper
feh --randomize --bg-fill ~/.wallpaper/*
