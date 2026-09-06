#!/bin/sh
#
# X 起動時の初期化。スクリーンセーバー、DPMS、キーリピート、
# ~/.Xmodmap のキーマップを適用する。
# .xprofile や i3 の config から実行する。

# スクリーンセーバー: 5分で起動し、5分ごとに切り替える
xset s 300 300

# DPMS: 5分ごとにスタンバイ・サスペンド・電源オフへ移る
xset dpms 300 300 300

# キーリピート: 開始まで 300ms、以降は毎秒 30 回
xset r rate 300 30

xmodmap ~/.Xmodmap
