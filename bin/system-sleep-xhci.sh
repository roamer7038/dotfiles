#!/bin/sh
#
# 一部の Dell Inspiron で、USB xHCI コントローラ（PCI 00:14.0）が原因で
# サスペンドに失敗しフリーズする問題を回避する。サスペンド前に wakeup を
# 無効化し、レジューム後に戻す。
#
#   kernel: PM: Device 0000:00:14.0 failed to suspend async: error -16
#
# systemd から呼ばれる位置に置いて使う:
#   sudo install -m 755 system-sleep-xhci.sh /usr/lib/systemd/system-sleep/xhci.sh
#
# 動作ログは /tmp/systemd_suspend_test に残る。

# --- サスペンド前の処理 ---

if [ "${1}" == "pre" ]; then
  # サスペンド前: xHCIのウェイクアップ機能を無効化
  echo "Disable broken xhci module before suspending at $(date)..." >/tmp/systemd_suspend_test

  # /proc/acpi/wakeup からXHCの状態を確認
  # "enable"状態であれば、ウェイクアップ機能を無効化（"disable"に変更）
  grep XHC.*enable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup

# --- レジューム後の処理 ---

elif [ "${1}" == "post" ]; then
  # レジューム後: xHCIのウェイクアップ機能を再有効化
  echo "Enable broken xhci module at wakeup from $(date)" >>/tmp/systemd_suspend_test

  # /proc/acpi/wakeup からXHCの状態を確認
  # "disable"状態であれば、ウェイクアップ機能を有効化（"enable"に変更）
  grep XHC.*disable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup
fi
