#!/bin/sh
#
# X 起動時の初期化。スクリーンセーバー、DPMS、キーリピート、
# ~/.Xmodmap のキーマップを適用する。
# .xprofile や i3 の config から実行する。

# --- スクリーンセーバーの設定 ---

# xset s <timeout> <cycle>
# timeout: スクリーンセーバー起動までの秒数
# cycle: スクリーンセーバーのサイクル時間（秒）
#
# 設定値: 300秒（5分）でスクリーンセーバーを起動
xset s 300 300

# --- DPMS（Display Power Management Signaling）の設定 ---

# xset dpms <standby> <suspend> <off>
# standby: スタンバイモードまでの秒数
# suspend: サスペンドモードまでの秒数
# off: ディスプレイをオフにするまでの秒数
#
# 設定値: 300秒（5分）で各段階に移行
# - 5分後にスタンバイ
# - 5分後にサスペンド
# - 5分後にディスプレイオフ
xset dpms 300 300 300

# --- キーボードリピートの設定 ---

# xset r rate <delay> <rate>
# delay: キーを押し続けてからリピートが始まるまでの遅延時間（ミリ秒）
# rate: 1秒間のリピート回数
#
# 設定値:
# - delay: 300ミリ秒（0.3秒）
# - rate: 30回/秒
xset r rate 300 30

# --- キーマップの変更 ---

# xmodmapで~/.Xmodmapに定義されたキーマップを適用
# 例: CapsLockをCtrlに変更、等のカスタマイズ
xmodmap ~/.Xmodmap
