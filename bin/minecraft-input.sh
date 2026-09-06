#!/bin/bash
#
# Minecraft へ日本語を入力するための補助ツール。zenity の入力欄に打った
# 文字列をクリップボード経由で xdotool が Ctrl+V として送る。
# 要 zenity・xclip・xdotool。
#
# i3wm での割り当て例:
#   bindsym $mod+m exec ~/dotfiles/bin/minecraft-input.sh

# 末尾の改行はチャット欄で送信として扱われるため落とす
zenity --text="Please enter text:" --entry | tr -d \n | xclip -selection clipboard

# クリップボードへの反映を待ってから貼り付ける
sleep 0.1

xdotool key ctrl+v
