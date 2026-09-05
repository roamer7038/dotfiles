#!/bin/bash
#
# Minecraft へ日本語を入力するための補助ツール。zenity の入力欄に打った
# 文字列をクリップボード経由で xdotool が Ctrl+V として送る。
# 要 zenity・xclip・xdotool。
#
# i3wm での割り当て例:
#   bindsym $mod+m exec ~/dotfiles/bin/minecraft-input.sh

# zenityで入力ダイアログを表示し、入力されたテキストを取得
# tr -d \n で改行を削除（ペースト時の問題を防ぐため）
# xclipでクリップボード（selection clipboard）にコピー
zenity --text="Please enter text:" --entry | tr -d \n | xclip -selection clipboard

# クリップボードへのコピーが完了するまで少し待機
sleep 0.1

# Ctrl+Vキーを送信してペースト
# Minecraftのアクティブウィンドウに対して実行される
xdotool key ctrl+v
