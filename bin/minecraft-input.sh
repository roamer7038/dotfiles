#!/bin/bash
#
# requirement: zenity, xclip, xdotool
# 
# Minecraft用の日本語入力支援ツール
# スクリプトを起動すると，入力画面がポップアップするので，
# 任意の文字列を入力してEnterを押すとゲーム上にペーストされる．
#

zenity --text="Please enter text:" --entry | tr -d \n | xclip -selection clipboard
sleep 0.1
xdotool key ctrl+v
