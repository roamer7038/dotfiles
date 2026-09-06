#!/bin/sh
#
# ~/.wallpaper 内の画像から1枚を選んで壁紙にする（要 feh）。
# ディレクトリが無ければ作る。画像が無くてもエラーにはならない。
# .xprofile や i3 の config から実行する。

mkdir -p ~/.wallpaper

# --bg-fill はアスペクト比を保ったまま画面いっぱいに拡大する
feh --randomize --bg-fill ~/.wallpaper/*
