#!/bin/sh
# ============================================================
# system-sleep-xhci.sh
# ============================================================
#
# 概要:
#   Dell Inspiron等のノートPCで発生するサスペンドエラーを回避するスクリプト
#
# 問題の詳細:
#   一部のDell Inspiron機種で、USB xHCIコントローラーが原因で
#   サスペンド（スリープ）に失敗し、システムがフリーズする問題が発生
#
#   エラーメッセージ例:
#     kernel: pci_pm_suspend(): hcd_pci_suspend+0x0/0x30 returns -16
#     kernel: dpm_run_callback(): pci_pm_suspend+0x0/0x150 returns -16
#     kernel: PM: Device 0000:00:14.0 failed to suspend async: error -16
#     kernel: PM: Some devices failed to suspend, or early wake event detected
#
# 解決方法:
#   サスペンド前にxHCIコントローラーのウェイクアップ機能を無効化
#   レジューム後に再度有効化することで問題を回避
#
# インストール方法:
#   $ sudo cp system-sleep-xhci.sh /usr/lib/systemd/system-sleep/xhci.sh
#   $ sudo chmod +x /usr/lib/systemd/system-sleep/xhci.sh
#
# 配置場所:
#   /usr/lib/systemd/system-sleep/xhci.sh
#   systemdがサスペンド/レジューム時に自動的に実行
#
# 対象デバイス:
#   PCI 00:14.0（USB xHCIコントローラー）
#
# 依存関係:
#   - systemd
#
# デバッグ:
#   スクリプトの動作ログは /tmp/systemd_suspend_test に記録
#
# ============================================================

###########################################################
# サスペンド前の処理
###########################################################

if [ "${1}" == "pre" ]; then
	# サスペンド前: xHCIのウェイクアップ機能を無効化
	echo "Disable broken xhci module before suspending at $(date)..." >/tmp/systemd_suspend_test

	# /proc/acpi/wakeup からXHCの状態を確認
	# "enable"状態であれば、ウェイクアップ機能を無効化（"disable"に変更）
	grep XHC.*enable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup

###########################################################
# レジューム後の処理
###########################################################

elif [ "${1}" == "post" ]; then
	# レジューム後: xHCIのウェイクアップ機能を再有効化
	echo "Enable broken xhci module at wakeup from $(date)" >>/tmp/systemd_suspend_test

	# /proc/acpi/wakeup からXHCの状態を確認
	# "disable"状態であれば、ウェイクアップ機能を有効化（"enable"に変更）
	grep XHC.*disable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup
fi
