#!/bin/sh
#
# ~/.wallpaper 内の画像から1枚を選んで壁紙にする（要 feh）。
# ディレクトリが無ければ作る。画像が無くてもエラーにはならない。
# .xprofile や i3 の config から実行する。

mkdir -p ~/.wallpaper

# --randomize: ランダムに画像を選択
# --bg-fill: 画面サイズに合わせて画像を拡大（アスペクト比維持）
feh --randomize --bg-fill ~/.wallpaper/*
